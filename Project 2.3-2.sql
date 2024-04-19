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
CREATE VIEW Part_9 AS
WITH CAge AS (
    SELECT
        customer_id,
        city_state_id,
        CASE
            WHEN DATEDIFF(year, birth_date, GETDATE()) <= 25 THEN '25>'
            WHEN DATEDIFF(year, birth_date, GETDATE()) BETWEEN 26 AND 40 THEN '26 to 40'
            WHEN DATEDIFF(year, birth_date, GETDATE()) BETWEEN 41 AND 55 THEN '41 to 55'
            WHEN DATEDIFF(year, birth_date, GETDATE()) BETWEEN 56 AND 70 THEN '56 to 70'
            ELSE '71<'
        END AS age_group
    FROM customers
),
CFlights AS (
    SELECT
        CA.customer_id,
        CA.city_state_id,
        CA.age_group,   -- Ensuring that age_group is selected here
        F.flight_id
    FROM flights F
    JOIN tickets T ON F.flight_id = T.flight_id
    JOIN CAge CA ON T.customer_id = CA.customer_id
    WHERE YEAR(F.date) IN (2016, 2017)
),
FlightData AS (
    SELECT
        CS.name AS city_name,
        CF.age_group,  -- Using age_group from CFlights
        COUNT(DISTINCT CF.customer_id) AS number_of_customers,
        COUNT(DISTINCT CF.flight_id) AS number_of_flights
    FROM CFlights CF
    JOIN cities_states CS ON CF.city_state_id = CS.city_state_id
    GROUP BY CS.name, CF.age_group  -- Grouping by age_group here
),
RankCities AS (
    SELECT
        city_name,
        age_group,
        number_of_customers,
        number_of_flights,
        RANK() OVER (PARTITION BY age_group ORDER BY number_of_customers DESC, number_of_flights DESC) AS city_rank
    FROM FlightData
)
SELECT
    city_name,
    number_of_customers,
    number_of_flights,
    age_group
FROM RankCities
WHERE city_rank <= 3;
GO

--10)----------------------------------------------------------------------------

alter table employees
drop constraint unique_employee_id
alter table employees
drop constraint check_gender
alter table employees
drop constraint CHK_HireDate
alter table employees
drop constraint unique_ssn
alter table employees
drop constraint CHK_Phone1Length
alter table employees
drop constraint check_zipcode_id
alter table employees
drop constraint default_employee_id_reports_to
alter table employees
drop constraint check_job_position_id

-- 1. Unique constraint for employee_id
ALTER TABLE employees
ADD CONSTRAINT unique_employee_id UNIQUE (employee_id);

-- 2. Check constraint for gender
ALTER TABLE employees
ADD CONSTRAINT check_gender CHECK (gender IN ('M', 'F'));

-- 3. Default constraint for birth_date
ALTER TABLE employees
ADD CONSTRAINT CHK_HireDate CHECK (hire_date < GETDATE());

-- 4. Unique constraint for ssn
ALTER TABLE employees
ADD CONSTRAINT unique_ssn UNIQUE (ssn);

-- 5. Default constraint for phone1
ALTER TABLE employees
ADD CONSTRAINT CHK_Phone1Length
CHECK (LEN(phone1) <= 50);

-- 6. Check constraint for zipcode_id
ALTER TABLE employees
ADD CONSTRAINT check_zipcode_id CHECK (zipcode_id > 0);

-- 7. Default constraint for employee_id_reports_to
ALTER TABLE employees
ADD CONSTRAINT default_employee_id_reports_to DEFAULT -1 FOR employee_id_reports_to;

-- 8. Check constraint for job_position_id
ALTER TABLE employees
ADD CONSTRAINT check_job_position_id CHECK (job_position_id >= 1 AND job_position_id <= 50);
-------------------------------------------------------------------------------------------------------------------------------------------------------
--1
ALTER TABLE customers 
    ADD CONSTRAINT unique_customer_id UNIQUE (customer_id),
--2
ALTER TABLE customers 
    ADD CONSTRAINT unique_email1 UNIQUE (email),
--3
ALTER TABLE customers 
    ADD CONSTRAINT check_gender1 CHECK (gender IN ('M', 'F')),
--4
ALTER TABLE customers 
    ADD CONSTRAINT default_phone11 DEFAULT 'N/A' FOR phone1,
--5
ALTER TABLE customers 
    ADD CONSTRAINT check_zipcode_id1 CHECK (zipcode_id > 0),
--6
ALTER TABLE customers 
    ADD CONSTRAINT default_city_state_id DEFAULT -1 FOR city_state_id;

-----------------------------------------------------------------------------------------------------------------------------------------------
alter table tickets
drop constraint unique_ticket_id --1
alter table tickets
drop constraint check_purchase_date --2
alter table tickets
drop constraint default_purchase_time --3
alter table tickets
drop constraint check_final_price --4
alter table tickets
drop constraint check_discount_id --5

alter table tickets
drop constraint check_payment_type_id --6



-- 1. Unique constraint for ticket_id
ALTER TABLE tickets
ADD CONSTRAINT unique_ticket_id UNIQUE (ticket_id);

-- 2. Check constraint for purchase_date to ensure it's not in the future
ALTER TABLE tickets
ADD CONSTRAINT check_purchase_date CHECK (purchase_date <= GETDATE());

-- 3. Default constraint for purchase_time to set it to the current time
ALTER TABLE tickets
ADD CONSTRAINT default_purchase_time DEFAULT GETDATE() FOR purchase_time;

-- 4. Check constraint for final_price to ensure it's non-negative
ALTER TABLE tickets
ADD CONSTRAINT check_final_price CHECK (final_price >= 0);

-- 5. Unique constraint for flight_id, customer_id, and purchase_date combination
Alter table tickets
add constraint check_discount_id Check (discount_id between 0 and 5)

-- 6. Check constraint for payment_type_id to ensure it's within a specific range
ALTER TABLE tickets
ADD CONSTRAINT check_payment_type_id CHECK (payment_type_id BETWEEN 1 AND 10);
-------------------------------------------------------------------
Alter table locations
drop constraint UQ_LocationID
Alter table locations
drop constraint CHK_LocationType
Alter table locations
drop constraint DF_AddressLine2


-- 1. Unique constraint on location_id
ALTER TABLE locations
ADD CONSTRAINT UQ_LocationID UNIQUE (location_id);

-- 2. Check constraint on location_type_id
ALTER TABLE locations
ADD CONSTRAINT CHK_LocationType CHECK (location_type_id IN (1, 2, 3)); 
-- 3. Default constraint on address_line2
ALTER TABLE locations
ADD CONSTRAINT DF_AddressLine2 DEFAULT 'N/A' FOR address_line2;
select * from location_types
-------------------------------------------------------------------
Alter table planes
drop constraint CHK_FabricationDate
Alter table planes
drop constraint  DF_Brand
Alter table planes
drop constraint UQ_PlaneID

-- 1. CHECK Constraint
ALTER TABLE planes
ADD CONSTRAINT CHK_FabricationDate CHECK (fabrication_date <= first_use_date);

-- 2. DEFAULT Constraint
ALTER TABLE planes
ADD CONSTRAINT DF_Brand DEFAULT ('Unknown') FOR brand;

-- 3. UNIQUE Constraint
ALTER TABLE planes
ADD CONSTRAINT UQ_PlaneID UNIQUE (plane_id);
-------------------------------------------------------------------
                    Alter Table flights
                        drop constraint CHK_TimeRange
                    Alter Table flights
                        drop constraint DF_Date
                    Alter Table flights
                        drop constraint UQ_FlightID
-- 1. CHECK Constraint
ALTER TABLE flights
ADD CONSTRAINT CHK_TimeRange CHECK (
    start_time_actual >= '00:00' AND start_time_actual <= '23:59' AND
    end_time_actual >= '00:00' AND end_time_actual <= '23:59' );
-- 2. DEFAULT Constraint
ALTER TABLE flights
ADD CONSTRAINT DF_Date DEFAULT GETDATE() FOR date;
--3 UNIQUE Constraint
ALTER TABLE flights
ADD CONSTRAINT UQ_FlightID UNIQUE (flight_id);
-------------------------------------------------------------------
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
--------------------------------------------------------------------
                    ALTER TABLE discounts
                        DROP CONSTRAINT CHK_DiscountAmount ;
                    ALTER TABLE discounts
                        DROP CONSTRAINT DF_Start_Date ;
                    ALTER TABLE discounts
                        DROP CONSTRAINT UQ_Discount_id ;

ALTER TABLE discounts
    ADD CONSTRAINT CHK_DiscountAmount CHECK (discounts.percentage > 0);
ALTER TABLE discounts
    ADD CONSTRAINT DF_Start_Date DEFAULT (GETDATE()) FOR start_date;
ALTER TABLE discounts
    ADD CONSTRAINT UQ_Discount_id UNIQUE (discount_id);
