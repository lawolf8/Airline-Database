/* 
Commerical Airline Project
Luke Wolf, Kyle Pterone, Reese Sleater, Michael Brennan
*/

/*
"High Level" Tables
*/
CREATE TABLE Airplane(
    serialnumber VARCHAR(250) PRIMARY KEY,  -- Serial Number Primary Key
    manufacturerserialnumber VARCHAR(250) PRIMARY KEY,
    model VARCHAR(250) NOT NULL,
    manufacturer VARCHAR(250) NOT NULL,
    capacity INT NOT NULL,
    dateManufactured DATE NOT NULL,
    lastMaintenance DATE NOT NULL,
    astatus ENUM('Active', 'Depot', 'Maintenance', 'Retired') NOT NULL, 
    alocation VARCHAR(255)
);

CREATE TABLE Cabin(
    cabinID INT AUTO_INCREMENT PRIMARY KEY, 
    serialnumber VARCHAT(250) NOT NULL,
    cabinclass ENUM('Economy', 'Economy Regular', 'Economy Plus', 'Business', 'First Class'),
    seatcapacity INT NOT NULL,
    ammenities VARCHAR(250),
    FOERIGN KEY (serialnumber) REFERENCES Airplane(serialnumber)
);

CREATE TABLE Customer(
    customerID INT AUTO_INCREMENT PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    mname VARCHAR(250),
    lname VARCHAR(250) NOT NULL,
    email VARCHAR(250) NOT NULL, 
    phonenumber VARCHAR(20),
    dateofbirth DATE,
    registration DATE,
    airlinepoints INT DEFAULT 0,
    registrationstatus BOOLEAN DEFAULT FALSE,
    caddress VARCHAR(250)
)

CREATE TABLE Employee(
    employeeID INT AUTO_INCREMENT PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    mname VARCHAR(250),
    lname VARCHAR(250) NOT NULL,
    email VARCHAR(250) NOT NULL, 
    phonenumber VARCHAR(20) NOT NULL,
    dateofbirth DATE NOT NULL,
    position VARCHAR(250) NOT NULL,
    onboarddate DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    serialnumber VARCHAR(250),
    employeeLevel INT NOT NULL CHECK (employeeLevel BETWEEN 1 AND 10),
    airplanes VARCHAR(250),
    FOREIGN KEY (serialnumber) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (airplanes) REFERENCES Airplanes(model)
);

/*
Maintence Tables
*/
-- Create table for Maintenance Schedules
--Create table for manufacter
CREATE TABLE partmanufacter(
    manufacter VARCHAR(250) NOT NULL PRIMARY KEY,
    memail VARCHAR(250) NOT NULL,
    mphone VARCHAR(250) NOT NULL, 
);

--Table for number of parts stocked
CREATE TABLE partlibrary(
    component_id INT PRIMARY KEY,
    manufacter VARCHAR(250) NOT NULL,
    part_name VARCHAR(250), 
    numberofcompnentsstocked INT,
    endlifehours INT CHECK(endlifehours>0),
    FOREIGN KEY (manufacter) REFERENCES partmanufacter(manufacter),
)

CREATE TABLE MaintenanceSchedule(
    schedule_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250) NOT NULL,
    maintenancetype CHAR(3) NOT NULL,
    task_description VARCHAR(255),
    due_date DATE NOT NULL,
    due_hours INT,
    expected_labored_hours INT NOT NULL,
    task_comments VARCHAR(250),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Create table for Maintenance Records
CREATE TABLE MaintenanceRecord(
    record_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250) NOT NULL,
    maintenancetype CHAR(3) NOT NULL,
    maintenance_date DATE,
    description VARCHAR(255),
    parts_replaced VARCHAR(255),
    technicians VARCHAR(100) NOT NULL,
    labored_hours INT NOT NULL,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (maintenancetype) REFERENCES MaintenanceSchedule(maintenancetype),
    FOREIGN KEY (parts_used) REFERENCES UtilizedComponents(component_id)
);

-- Create table for Component Tracking
CREATE TABLE UtilizedComponents(
    component_id INT,
    aircraft_id VARCHAR(250),
    component_name VARCHAR(100),
    manufacturer VARCHAR(250) NOT NULL,
    installation_date DATE NOT NULL,
    removal_date DATE,
    status ENUM('Early life', 'End life', 'Removed'),
    labored_hours INT NOT NULL,
    maintence_comments VARCHAR(250)
    part_hours INT,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (manufacturer) REFERENCES partmanufacter(manufacter),
    FOREIGN KEY (component_id) REFERENCES partlibrary(component_id)
);


-- Create table for Maintenance Personnel Records
CREATE TABLE MaintenancePersonnel(
personnel_id INT PRIMARY KEY,
name VARCHAR(100),
qualification VARCHAR(100),
certification VARCHAR(100)
);

-- Create table for Maintenance Tasks
CREATE TABLE MaintenanceTask (
task_id INT PRIMARY KEY,
task_name VARCHAR(100),
description VARCHAR(255)
);

-- Create table for Aircraft-MaintenanceTask Mapping
CREATE TABLE AircraftMaintenanceTask (
aircraft_id INT,
task_id INT,
PRIMARY KEY (aircraft_id, task_id),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id),
FOREIGN KEY (task_id) REFERENCES MaintenanceTask(task_id)
);

-- Create table for Maintenance Alerts and Notifications
CREATE TABLE MaintenanceAlert (
alert_id INT PRIMARY KEY,
aircraft_id INT,
alert_type VARCHAR(50),
alert_date DATE,
description VARCHAR(255),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

-- Create table for Inventory Management
CREATE TABLE Inventory (
inventory_id INT PRIMARY KEY,
part_name VARCHAR(100),
quantity INT,
location VARCHAR(100),
procurement_date DATE
);

-- Create table for Compliance and Regulatory Data
CREATE TABLE Compliance (
compliance_id INT PRIMARY KEY,
aircraft_id INT,
document_type VARCHAR(50),
document_number VARCHAR(50),
compliance_date DATE,
expiration_date DATE,
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

-- Create table for Aircraft Health Monitoring
CREATE TABLE HealthMonitoring (
monitoring_id INT PRIMARY KEY,
aircraft_id INT,
monitoring_date DATE,
system_name VARCHAR(100),
status VARCHAR(20),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);
-- Create table for Incident and Accident Reports
CREATE TABLE Incident (
incident_id INT PRIMARY KEY,
aircraft_id INT,
incident_date DATE,
description VARCHAR(255),
investigation_status VARCHAR(50),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

-- Create table for Reliability and Performance Metrics
CREATE TABLE PerformanceMetrics (
metric_id INT PRIMARY KEY,
aircraft_id INT,
metric_name VARCHAR(100),
value DECIMAL(10,2),
metric_date DATE,
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);
-- Create table for Routes
CREATE TABLE Route (
route_id INT PRIMARY KEY,
origin VARCHAR(100),
destination VARCHAR(100),
day_of_week VARCHAR(10),
schedule_time TIME
);

/*
Routes Tables
*/
CREATE TABLE Route (
route_id INT PRIMARY KEY,
origin VARCHAR(100),
destination VARCHAR(100),
day_of_week VARCHAR(10),
schedule_time TIME
);

-- Create the Flight table with composite primary key
CREATE TABLE Flight (
flight_id INT,
route_id INT,
aircraft_id INT,
departure_date DATE,
departure_time TIME,
arrival_date DATE,
arrival_time TIME,
PRIMARY KEY (flight_id, departure_date, departure_time),
FOREIGN KEY (route_id) REFERENCES Route(route_id),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

/*
Routes and Schedules
*/
-- Create table for Routes
CREATE TABLE Route (
route_id INT PRIMARY KEY,
origin_id int,
destination_id int,
day_of_week VARCHAR(10),
schedule_time TIME,
FOREIGN KEY (origin_id) REFERENCES AirportLocations(Airport_id),
FOREIGN KEY (destination_id) REFERENCES AirportLocations(Airport_id)
);

-- Create the Flight table with composite primary key
CREATE TABLE Flight (
flight_id INT,
route_id INT,
aircraft_id INT,
departure_date DATE,
departure_time TIME,
arrival_date DATE,
arrival_time TIME,
PRIMARY KEY (flight_id, departure_date, departure_time),
FOREIGN KEY (route_id) REFERENCES Route(route_id),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

-- Create table for Airport Locations
CREATE TABLE AirportLocations (
airport_id Int PRIMARY KEY,
airport_code VARCHAR(3) UNIQUE,
airport_name VARCHAR(255),
city VARCHAR(100),
country VARCHAR(100),
);

-- Create a table for ticket ID, and pricing
Create Table Tickets (
    Ticket_no Int Primary Key,
    Ticket_Price Int,
    FOREIGN KEY (flight_id, departure_date, departure_time)
    );

 -- Create a table for Discounts
CREATE TABLE Discounts (
    discount_percentage Int Primary Key,
    discount_applied Int,
    );

    
    
