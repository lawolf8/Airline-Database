/*
Project 2.3
Group 8
Luke Wolf, Kyle Petrone, Michael Brennan, Reece Sleater
*/

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

--1)----------------------------------------------------------------------------
GO
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


--2)----------------------------------------------------------------------------
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


--3)----------------------------------------------------------------------------
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


--4)----------------------------------------------------------------------------
IF OBJECT_ID('Restrict_FirstName_Length', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER Restrict_FirstName_Length;
END;
GO

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

--5)----------------------------------------------------------------------------
CREATE TABLE TB_audit
(
    aud_id INT IDENTITY,
    aud_station VARCHAR(50),
    aud_operation VARCHAR(50),
    aud_date DATE,
    aud_time TIME,
    aud_username VARCHAR(50),
    aud_table VARCHAR(50),
    aud_identifier_id VARCHAR(50),
    aud_column VARCHAR(50),
    aud_before VARCHAR(MAX),
    aud_after VARCHAR(MAX)
);

IF OBJECT_ID('dbo.tr_planes_insert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_planes_insert;
GO

CREATE TRIGGER tr_planes_insert
ON planes
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @date DATE = CAST(GETDATE() AS DATE);
    DECLARE @time TIME = CAST(GETDATE() AS TIME);

    INSERT INTO TB_audit (
        aud_station, aud_operation, aud_date, aud_time, aud_username, aud_table, aud_identifier_id, aud_column, aud_before, aud_after
    )
    SELECT 
        HOST_NAME(), 'INSERT', @date, @time, SYSTEM_USER, 'planes', inserted.plane_id, COLUMN_NAME, NULL, COLUMN_VALUE
    FROM 
        inserted
    CROSS APPLY (
        VALUES 
        ('plane_id', CAST(plane_id AS VARCHAR(MAX))),
        ('fabrication_date', CONVERT(VARCHAR, fabrication_date, 120)),
        ('first_use_date', CONVERT(VARCHAR, first_use_date, 120)),
        ('brand', brand),
        ('model', model),
        ('capacity', CAST(capacity AS VARCHAR(MAX)))
    ) AS AuditLog (COLUMN_NAME, COLUMN_VALUE);
END;
GO

IF OBJECT_ID('dbo.tr_planes_update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_planes_update;
GO
CREATE TRIGGER tr_planes_update
ON planes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @date DATE = CAST(GETDATE() AS DATE);
    DECLARE @time TIME = CAST(GETDATE() AS TIME);

    INSERT INTO TB_audit (
        aud_station, aud_operation, aud_date, aud_time, aud_username, aud_table, aud_identifier_id, aud_column, aud_before, aud_after
    )
    SELECT 
        HOST_NAME(), 'UPDATE', @date, @time, SYSTEM_USER, 'planes', inserted.plane_id, COLUMN_NAME, DELETED_VALUE, INSERTED_VALUE
    FROM 
        inserted
    JOIN 
        deleted ON inserted.plane_id = deleted.plane_id
    CROSS APPLY (
        VALUES 
        ('plane_id', CAST(deleted.plane_id AS VARCHAR(MAX)), CAST(inserted.plane_id AS VARCHAR(MAX))),
        ('fabrication_date', CONVERT(VARCHAR, deleted.fabrication_date, 120), CONVERT(VARCHAR, inserted.fabrication_date, 120)),
        ('first_use_date', CONVERT(VARCHAR, deleted.first_use_date, 120), CONVERT(VARCHAR, inserted.first_use_date, 120)),
        ('brand', deleted.brand, inserted.brand),
        ('model', deleted.model, inserted.model),
        ('capacity', CAST(deleted.capacity AS VARCHAR(MAX)), CAST(inserted.capacity AS VARCHAR(MAX)))
    ) AS AuditLog (COLUMN_NAME, DELETED_VALUE, INSERTED_VALUE)
    WHERE DELETED_VALUE <> INSERTED_VALUE;
END;
GO

IF OBJECT_ID('dbo.tr_planes_delete', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_planes_delete;
GO
CREATE TRIGGER tr_planes_delete
ON planes
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @date DATE = CAST(GETDATE() AS DATE);
    DECLARE @time TIME = CAST(GETDATE() AS TIME);

    INSERT INTO TB_audit (
        aud_station, aud_operation, aud_date, aud_time, aud_username, aud_table, aud_identifier_id, aud_column, aud_before, aud_after
    )
    SELECT 
        HOST_NAME(), 'DELETE', @date, @time, SYSTEM_USER, 'planes', deleted.plane_id, COLUMN_NAME, COLUMN_VALUE, NULL
    FROM 
        deleted
    CROSS APPLY (
        VALUES 
        ('plane_id', CAST(plane_id AS VARCHAR(MAX))),
        ('fabrication_date', CONVERT(VARCHAR, fabrication_date, 120)),
        ('first_use_date', CONVERT(VARCHAR, first_use_date, 120)),
        ('brand', brand),
        ('model', model),
        ('capacity', CAST(capacity AS VARCHAR(MAX)))
    ) AS AuditLog (COLUMN_NAME, COLUMN_VALUE);
END;
GO

--6)----------------------------------------------------------------------------
CREATE VIEW Top_100_Customers AS
SELECT TOP 100
    c.customer_id,
    c.first_name,
    c.last_name,
    c.birth_date,
    DATEDIFF(YEAR, c.birth_date, GETDATE()) AS current_age,
    cs.name AS city_name
FROM
    customers c
INNER JOIN
    cities_states cs ON c.city_state_id = cs.city_state_id
ORDER BY
    current_age ASC,
    c.birth_date DESC;
GO


--7)----------------------------------------------------------------------------
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

--8)----------------------------------------------------------------------------
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
GO

--9)----------------------------------------------------------------------------
CREATE VIEW vw_nine AS
SELECT
 c.name,
 SUM(CASE WHEN f.flight_year = 2016 THEN 1 ELSE 0 END) AS num_flights_2016,
 SUM(CASE WHEN f.flight_year = 2017 THEN 1 ELSE 0 END) AS num_flights_2017,
 COUNT(DISTINCT c.customer_id) AS num_customers,
 CASE
  WHEN c.customer_age <= 25 THEN '25 or younger'
  WHEN c.customer_age BETWEEN 26 AND 40 THEN '26 to 40'
  WHEN c.customer_age BETWEEN 41 AND 55 THEN '41 to 55'
  WHEN c.customer_age BETWEEN 56 AND 70 THEN '56 to 70'
  ELSE '71 or older'
 END AS age_group
FROM 
    customers c
JOIN 
    addresses a ON c.address_id = a.address_id
JOIN 
    cities_states cs ON a.city_state_id = cs.city_state_id
JOIN 
    flights f ON c.customer_id = f.customer_id
GROUP BY 
    c.customer_id, cs.name, c.customer_age
ORDER BY 
    age_group, num_customers_2016_2017 DESC, num_flights_2016 DESC, num_flights_2017 DESC;
Go
--10)----------------------------------------------------------------------------
ALTER TABLE employees
ADD CONSTRAINT unique_email UNIQUE (email),
ADD CONSTRAINT check_gender CHECK (gender IN ('M', 'F')),
ADD CONSTRAINT default_birth_date DEFAULT '1900-01-01' FOR birth_date,
ADD CONSTRAINT unique_ssn UNIQUE (ssn),
ADD CONSTRAINT default_phone1 DEFAULT 'N/A' FOR phone1,
ADD CONSTRAINT check_zipcode_id CHECK (zipcode_id > 0),
ADD CONSTRAINT default_employee_id_reports_to DEFAULT -1 FOR employee_id_reports_to;

ALTER TABLE customers
ADD CONSTRAINT unique_customer_id UNIQUE (customer_id),
ADD CONSTRAINT unique_email UNIQUE (email),
ADD CONSTRAINT check_gender CHECK (gender IN ('M', 'F')),
ADD CONSTRAINT default_phone1 DEFAULT 'N/A' FOR phone1,
ADD CONSTRAINT check_zipcode_id CHECK (zipcode_id > 0),
ADD CONSTRAINT default_city_state_id DEFAULT -1 FOR city_state_id;


ALTER TABLE tickets
ADD CONSTRAINT unique_ticket_id UNIQUE (ticket_id),
ADD CONSTRAINT date_constraint CHECK (boarding_date >= purchase_date),
ADD CONSTRAINT time_constraint CHECK (purchase_time <= boarding_time)
ADD CONSTRAINT default_purchase_time DEFAULT '00:00:00' FOR purchase_time,
ADD CONSTRAINT default_boarding_time DEFAULT '00:00:00' FOR boarding_time,
ADD CONSTRAINT check_final_price CHECK (final_price >= 0);


ALTER TABLE routes
DROP CONSTRAINT CHK_Time_Order;
ALTER TABLE routes
DROP CONSTRAINT UQ_route_id;
ALTER TABLE routes
DROP CONSTRAINT DF_Weekday;
-- 1. Check Constraint
ALTER TABLE routes
ADD CONSTRAINT CHK_Time_Order CHECK (start_time < end_time);
--2
alter table routes
Add constraint UQ_route_id UNIQUE (route_id)
-- 3. Default Constraint
ALTER TABLE routes
ADD CONSTRAINT DF_Weekday DEFAULT 1 FOR weekday_id;
