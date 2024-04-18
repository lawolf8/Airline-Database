--1)---------------------------------------------------------------
CREATE OR ALTER TRIGGER Flights_Date_Restriction_On_Edit_Trigger
ON flights
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE YEAR(date) < 2016 OR YEAR(date) > 2019
    )
    BEGIN
        RAISERROR ('Flight dates must be between 2016 and 2019.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

/*
--2)------------------------------------------------
CREATE OR ALTER TRIGGER Restricted_Edit_On_Planes_Trigger
ON planes
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    RAISERROR ('Input, modification, or deletion of rows not allowed.', 16, 1);
    ROLLBACK TRANSACTION;
END;

*/
--CORRECTED 2:
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'Restricted_Edit_On_Planes_Trigger')
BEGIN
    DROP TRIGGER Restricted_Edit_On_Planes_Trigger;
END;
GO  -- Ends the batch here
-- Starts a new batch
CREATE TRIGGER Restricted_Edit_On_Planes_Trigger
ON planes
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    RAISERROR ('Input, modification, or deletion of rows not allowed.', 16, 1);
    ROLLBACK; -- Ensures that the transaction is not committed
END;
GO  -- Ends the batch, though this is optional as it's the end of the script


--3)---------------------------------------------------------------------------
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

--4)---------------------------------------------------------------------------
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

--5)---------------------------------------------------------------------------
CREATE TRIGGER trg_planes_insert
AFTER INSERT ON planes
FOR EACH ROW
BEGIN
  INSERT INTO tb_audit (
    aud_station,
    aud_operation,
    aud_date,
    aud_time,
    aud_username,
    aud_table,
    aud_identifier_id,
    aud_column,
    aud_before,
    aud_after
  )
  VALUES (
    @@SERVER_NAME,  -- Capture workstation name
    'INSERT',
    GETDATE(),     -- Capture current date
    GETUTCDATE(),  -- Capture current time (UTC)
    CURRENT_USER,   -- Capture username
    'planes',
    NEW.plane_id,   -- ID of the newly inserted row
    NULL,           -- No column change for INSERT
    NULL,           -- No old value for INSERT
    CONVERT(varchar(max), NEW.*, 126)  -- Convert entire new row to string
  );
END;

CREATE TRIGGER trg_planes_update
AFTER UPDATE ON planes
FOR EACH ROW
BEGIN
  DECLARE @old_data nvarchar(max);

  -- Get the old data of the updated row
  SELECT @old_data = CONVERT(nvarchar(max), DELETED.*, 126)
  FROM deleted
  WHERE deleted.plane_id = UPDATED.plane_id;

  INSERT INTO tb_audit (
    aud_station,
    aud_operation,
    aud_date,
    aud_time,
    aud_username,
    aud_table,
    aud_identifier_id,
    aud_column,
    aud_before,
    aud_after
  )
  SELECT
    @@SERVER_NAME,
    'UPDATE',
    GETDATE(),
    GETUTCDATE(),
    CURRENT_USER,
    'planes',
    UPDATED.plane_id,
    d.name AS aud_column,  -- Capture the updated column name
    @old_data AS aud_before,
    CONVERT(varchar(max), UPDATED.*, 126) AS aud_after
  FROM (
    SELECT TOP 1 *
    FROM deleted d
    WHERE d.plane_id = UPDATED.plane_id
  ) d;
END;

CREATE TRIGGER trg_planes_delete
AFTER DELETE ON planes
FOR EACH ROW
BEGIN
  INSERT INTO tb_audit (
    aud_station,
    aud_operation,
    aud_date,
    aud_time,
    aud_username,
    aud_table,
    aud_identifier_id,
    aud_column,
    aud_before,
    aud_after
  )
  VALUES (
    @@SERVER_NAME,  -- Capture workstation name
    'DELETE',
    GETDATE(),     -- Capture current date
    GETUTCDATE(),  -- Capture current time (UTC)
    CURRENT_USER,   -- Capture username
    'planes',
    DELETED.plane_id, -- ID of the deleted row
    NULL,           -- No column change for DELETE
    CONVERT(varchar(max), DELETED.*, 126) AS aud_before,  -- Entire deleted row data
    NULL            -- No new value for DELETE
  );
END;


--6)---------------------------------------------------------------------------
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
--7)----------------------------------------------------------------------------- Verified
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

--9)-----------------------------------------------------------------------
CREATE VIEW vw_TopCityCustomerFlightsByAgeGroup AS
SELECT
  c.name,
  SUM(CASE WHEN f.flight_year = 2016 THEN 1 ELSE 0 END) AS num_flights_2016,
  SUM(CASE WHEN f.flight_year = 2017 THEN 1 ELSE 0 END) AS num_flights_2017,
  COUNT(DISTINCT c.customer_id) AS num_customers_2016_2017,
  CASE
    WHEN c.customer_age <= 25 THEN '25 or younger'
    WHEN c.customer_age BETWEEN 26 AND 40 THEN '26 to 40'
    WHEN c.customer_age BETWEEN 41 AND 55 THEN '41 to 55'
    WHEN c.customer_age BETWEEN 56 AND 70 THEN '56 to 70'
    ELSE '71 or older'
  END AS age_group
FROM customers c
INNER JOIN addresses a ON c.address_id = a.address_id
INNER JOIN cities_states cs ON a.city_state_id = cs.city_state_id
INNER JOIN flights f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, cs.name, c.customer_age
HAVING COUNT(DISTINCT c.customer_id) > 0  -- Exclude rows with no flights
ORDER BY age_group, num_customers_2016_2017 DESC, num_flights_2016 DESC, num_flights_2017 DESC
WITH TIES;  -- Break ties by city name alphabetically

;

SELECT * FROM vw_TopCityCustomerFlightsByAgeGroup
  -- Limit to top 3 cities per age group based on ranking within the view
  WHERE ROW_NUMBER() OVER (PARTITION BY age_group ORDER BY num_customers_2016_2017 DESC, num_flights_2016 DESC, num_flights_2017 DESC) <= 3;

--10)------------------------------------------------------------------------------------------

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 18),
    hire_date DATE,
    position VARCHAR(100),
    department VARCHAR(100),
    salary DECIMAL(10, 2) CHECK (salary >= 0),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20),
    address VARCHAR(255),
    manager_id INT UNIQUE,
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    contract_type VARCHAR(50),
    contract_duration INT CHECK (contract_duration > 0),
    hourly_rate DECIMAL(10, 2) CHECK (hourly_rate >= 0),
    employment_status VARCHAR(50),
    CONSTRAINT chk_manager_id CHECK (manager_id <> employee_id),
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 18),
    gender VARCHAR(10),
    registration_date DATE,
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    address VARCHAR(255),
    frequent_flyer_status VARCHAR(50) DEFAULT 'Regular',
    loyalty_points INT DEFAULT 0 CHECK (loyalty_points >= 0),
    last_flight_date DATE,
    preferred_seat VARCHAR(20),
    preferred_airline VARCHAR(100),
    CONSTRAINT chk_date CHECK (registration_date <= last_flight_date)
);

CREATE TABLE tickets (
    ticket_number INT PRIMARY KEY,
    ticket_price DECIMAL(10, 2) DEFAULT 0 CHECK (ticket_price >= 0),
    purchase_date DATE,
    passenger_name VARCHAR(100),
    passenger_age INT CHECK (passenger_age >= 0),
    passenger_gender VARCHAR(10),
    seat_number VARCHAR(10),
    flight_number INT,
    customer_id INT UNIQUE,
    departure_date DATE,
    luggage_weight DECIMAL(10, 2),
    luggage_size VARCHAR(50),
    booking_reference VARCHAR(20) UNIQUE,
    CONSTRAINT chk_date CHECK(purchase_date <= departure_date)
    CONSTRAINT chk_luggage_weight CHECK (luggage_weight >= 0),
);

CREATE TABLE locations (
    location_id INT UNIQUE,
    city VARCHAR(100),
    country VARCHAR(100),
    airport_code VARCHAR(10) UNIQUE,
    timezone VARCHAR(50) DEFAULT 'EST',
    region VARCHAR(100),
    airtraffic_controller VARCHAR(50)

);

CREATE TABLE planes (
    plane_id INT PRIMARY KEY,
    model VARCHAR(100) DEFAULT '737',
    capacity INT CHECK (capacity > 0),
    manufacturer VARCHAR(100),
    purchase_date DATE,
    status VARCHAR(50) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive'))
);

CREATE TABLE flights (
    flight_number INT PRIMARY KEY,
    departure_time DATE,
    arrival_time DATE,
    route_id INT,
    plane_id INT UNIQUE,
    status VARCHAR(50) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Cancelled', 'Completed'))
    CONSTRAINT chk_time CHECK (departure_time <= arrival_time)
);

CREATE TABLE routes (
    route_id INT PRIMARY KEY,
    origin VARCHAR(100),
    destination VARCHAR(100),
    distance DECIMAL(10, 2) CHECK (distance > 0),
    duration TIME,
    fare DECIMAL(10, 2) DEFAULT 0 CHECK (fare >= 0),
    CONSTRAINT chk_duration_not_null CHECK (duration IS NOT NULL)
);

CREATE TABLE discounts (
    discount_code VARCHAR(20) PRIMARY KEY,
    discount_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    start_date DATE,
    expiry_date DATE,
    description VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive'))
    CONSTRAINT chk_discount_time CHECK(start_date <= expiry_date)


);
--ERROR messages
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 36 [Batch Start Line 45]
Incorrect syntax near the keyword 'TRIGGER'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 77 [Batch Start Line 45]
Incorrect syntax near the keyword 'TRIGGER'.
Msg 137, Level 15, State 2, Procedure Restrict_Final_Price_Update, Line 94 [Batch Start Line 45]
Must declare the scalar variable "@@SERVER_NAME".
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 107 [Batch Start Line 45]
Incorrect syntax near the keyword 'TRIGGER'.
Msg 102, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 114 [Batch Start Line 45]
Incorrect syntax near '*'.
Msg 137, Level 15, State 2, Procedure Restrict_Final_Price_Update, Line 131 [Batch Start Line 45]
Must declare the scalar variable "@@SERVER_NAME".
Msg 102, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 145 [Batch Start Line 45]
Incorrect syntax near 'd'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 148 [Batch Start Line 45]
Incorrect syntax near the keyword 'TRIGGER'.
Msg 137, Level 15, State 2, Procedure Restrict_Final_Price_Update, Line 165 [Batch Start Line 45]
Must declare the scalar variable "@@SERVER_NAME".
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 180 [Batch Start Line 45]
Incorrect syntax near the keyword 'VIEW'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 196 [Batch Start Line 45]
Incorrect syntax near the keyword 'VIEW'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 235 [Batch Start Line 45]
Incorrect syntax near the keyword 'VIEW'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 256 [Batch Start Line 45]
Incorrect syntax near the keyword 'VIEW'.
Msg 319, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 276 [Batch Start Line 45]
Incorrect syntax near the keyword 'with'. If this statement is a common table expression, an xmlnamespaces clause or a change tracking context clause, the previous statement must be terminated with a semicolon.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 290 [Batch Start Line 45]
Incorrect syntax near the keyword 'CURRENT_DATE'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 312 [Batch Start Line 45]
Incorrect syntax near the keyword 'CURRENT_DATE'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 327 [Batch Start Line 45]
Incorrect syntax near the keyword 'CURRENT_DATE'.
Msg 195, Level 15, State 10, Procedure Restrict_Final_Price_Update, Line 350 [Batch Start Line 45]
'LENGTH' is not a recognized built-in function name.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 358 [Batch Start Line 45]
Incorrect syntax near the keyword 'CURRENT_DATE'.
Msg 156, Level 15, State 1, Procedure Restrict_Final_Price_Update, Line 384 [Batch Start Line 45]
Incorrect syntax near the keyword 'CURRENT_DATE'.
