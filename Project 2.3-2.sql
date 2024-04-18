--This deletes all triggers and views--
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'DROP TRIGGER ' + QUOTENAME(name) + ';' 
FROM sys.triggers;

EXEC sp_executesql @sql;

DECLARE @viewName NVARCHAR(MAX)

DECLARE viewCursor CURSOR FOR
SELECT name
FROM sys.views

OPEN viewCursor
FETCH NEXT FROM viewCursor INTO @viewName

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('DROP VIEW ' + @viewName)
    FETCH NEXT FROM viewCursor INTO @viewName
END

CLOSE viewCursor
DEALLOCATE viewCursor
-------------------------------------------------------------------

--1)---------------------------------------------------------------
CREATE OR ALTER TRIGGER Flights_Date_Restriction_On_Edit_Trigger
ON flights
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE YEAR([date]) < 2016 OR YEAR([date]) > 2019
    )
    BEGIN
        RAISERROR ('Flight dates must be between 2016 and 2019.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

--2)------------------------------------------------
IF OBJECT_ID('Restricted_Edit_On_Planes_Trigger', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER Restricted_Edit_On_Planes_Trigger;
END;
GO

CREATE TRIGGER Restricted_Edit_On_Planes_Trigger
ON planes
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    RAISERROR ('Input, modification, or deletion of rows not allowed.', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

--3)---------------------------------------------------------------------------
IF OBJECT_ID('Restrict_Final_Price_Update', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER Restrict_Final_Price_Update;
END;
GO

CREATE TRIGGER Restrict_Final_Price_Update
ON tickets
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the final_price update meets the requirement
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN tickets t ON i.ticket_id = t.ticket_id
        JOIN flights f ON t.flight_id = f.flight_id
        JOIN routes_cabin_types rct ON f.route_id = rct.route_id AND t.cabin_type_id = rct.cabin_type_id
        WHERE ABS(i.final_price - rct.price) > (0.2 * rct.price)
    )
    BEGIN
        -- If the requirement is not met, cancel the operation
        RAISERROR ('Final price cannot deviate more than 20% from the corresponding route and cabin type price.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        -- If the requirement is met, perform the update
        UPDATE t
        SET t.final_price = i.final_price
        FROM tickets t
        INNER JOIN inserted i ON t.ticket_id = i.ticket_id;
    END
END;
GO

--4)---------------------------------------------------------------------------
IF OBJECT_ID('Restrict_FirstName_Length', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER Restrict_FirstName_Length;
END;
GO
--6
CREATE TRIGGER Restrict_FirstName_Length
ON customers
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Check the length of first_name in inserted data
    DECLARE @MinLength INT, @MaxLength INT;
    SELECT @MinLength = MIN(LEN(first_name)), @MaxLength = MAX(LEN(first_name)) FROM inserted;

    -- Get the shortest and longest length of first_name from existing data
    DECLARE @MinExistingLength INT, @MaxExistingLength INT;
    SELECT @MinExistingLength = MIN(LEN(first_name)), @MaxExistingLength = MAX(LEN(first_name)) FROM customers;

    -- If the length of first_name in inserted data is outside the range of existing data, cancel the operation
    IF @MinLength < @MinExistingLength OR @MaxLength > @MaxExistingLength
    BEGIN
        RAISERROR ('Input or update of first_name values is restricted based on the length of existing data.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        -- If the length is within the range, perform the insert or update
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            -- Insert the rows into the customers table
            INSERT INTO customers (customer_id, first_name, last_name, birth_date, start_date, email, gender, phone1, phone2, address_line1, address_line2, zipcode_id, city_state_id)
            SELECT customer_id, first_name, last_name, birth_date, start_date, email, gender, phone1, phone2, address_line1, address_line2, zipcode_id, city_state_id
            FROM inserted;
        END
        ELSE
        BEGIN
            -- Update the rows in the customers table
            UPDATE c
            SET c.first_name = i.first_name
            FROM customers c
            INNER JOIN inserted i ON c.customer_id = i.customer_id;
        END
    END
END;
GO
--7
CREATE VIEW Top_3_Routes_By_Weekday AS
SELECT 
    route_id,
    origin_city_name,
    destination_city_name,
    weekday_id,
    weekday_name,
    num_flights
FROM (
    SELECT 
        r.route_id,
        origin_city.name AS origin_city_name,
        destination_city.name AS destination_city_name,
        w.weekday_id,
        w.name AS weekday_name,
        COUNT(t.ticket_id) AS num_flights,
        ROW_NUMBER() OVER (PARTITION BY w.weekday_id ORDER BY COUNT(t.ticket_id) DESC) AS route_rank
    FROM 
        routes r
    JOIN 
        cities_states origin_city ON r.city_state_id_origin = origin_city.city_state_id
    JOIN 
        cities_states destination_city ON r.city_state_id_destination = destination_city.city_state_id
    JOIN 
        weekdays w ON r.weekday_id = w.weekday_id
    LEFT JOIN 
        flights f ON r.route_id = f.route_id
    LEFT JOIN 
        tickets t ON f.flight_id = t.flight_id
    WHERE 
        YEAR(t.purchase_date) IN (2016, 2017)
    GROUP BY 
        r.route_id, origin_city.name, destination_city.name, w.weekday_id, w.name
) AS subquery
WHERE 
    route_rank <= 3;
	GO

--8)-----------------------------------------------------------------------------
CREATE VIEW Flights_By_City AS
SELECT 
    cs.name AS city_name,
    COUNT(DISTINCT CASE WHEN YEAR(t.purchase_date) IN (2016, 2017) THEN f.flight_id END) AS total_flights,
    COUNT(DISTINCT CASE WHEN YEAR(t.purchase_date) IN (2016, 2017) AND c.gender = 'Male' THEN f.flight_id END) AS male_flights,
    COUNT(DISTINCT CASE WHEN YEAR(t.purchase_date) IN (2016, 2017) AND c.gender = 'Female' THEN f.flight_id END) AS female_flights
FROM 
    cities_states cs
JOIN 
    customers c ON cs.city_state_id = c.city_state_id
JOIN 
    tickets t ON c.customer_id = t.customer_id
JOIN 
    flights f ON t.flight_id = f.flight_id
GROUP BY 
    cs.name
ORDER BY 
    total_flights DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY;
