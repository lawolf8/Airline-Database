/* 
Commerical Airline Project
Luke Wolf, Kyle Pterone, Reece Sleater, Michael Brennan
ALL TABLES ARE VERIFIED IN 3RD NORMAL FORM
*/

-- Airplane Identification
CREATE TABLE Airplane(
    serialnumber VARCHAR(250) PRIMARY KEY,
    manufacturerserialnumber VARCHAR(250) PRIMARY KEY,
    model VARCHAR(250) NOT NULL,
    manufacturer VARCHAR(250) NOT NULL,
    capacity INT NOT NULL,
    dateManufactured DATE NOT NULL,
    lastMaintenance DATE NOT NULL,
    airstatus ENUM('Active', 'Depot', 'Maintenance', 'Retired') NOT NULL, 
    alocation VARCHAR(255)
);

-- Cabin Information
CREATE TABLE Cabin(
    cabinID INT AUTO_INCREMENT PRIMARY KEY, 
    serialnumber VARCHAT(250) NOT NULL,
    cabinclass ENUM('Economy', 'Economy Regular', 'Economy Plus', 'Business', 'First Class'),
    seatcapacity INT NOT NULL,
    ammenities VARCHAR(250),
    FOERIGN KEY (serialnumber) REFERENCES Airplane(serialnumber)
);

-- Customer Information
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
);

-- Customer Black List
CREATE TABLE Customerblacklist(
    customerID INT AUTO_INCREMENT PRIMARY KEY,
    reason VARCHAR(250),
    dateofbl DATE,
    FOREIGN KEY (customerID) REFERENCES Customer(customerID)
)

-- Employee List
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
    employementstatus BOOLEAN NOT NULL,
    FOREIGN KEY (serialnumber) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (airplanes) REFERENCES Airplanes(model)
);

--Manufacter Information
CREATE TABLE manufacter(
    manufacter VARCHAR(250) PRIMARY KEY,
    contact_name VARCHAR(100),
    contact_email VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    maddress VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100)
);

--Parts Library
CREATE TABLE partlibrary(
    component_id INT PRIMARY KEY,
    manufacter VARCHAR(250) NOT NULL,
    part_name VARCHAR(250), 
    numberofcompnentsstocked INT,
    endlifehours INT CHECK(endlifehours>0),
    procurement_date DATE,
    partlocation VARCHAR(250),
    FOREIGN KEY (manufacter) REFERENCES partmanufacter(manufacter),
);

--Scheduled Maintenance
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

--Maintenance Records
CREATE TABLE MaintenanceRecord(
    record_id INT PRIMARY KEY,  --References MP table
    aircraft_id VARCHAR(250) NOT NULL,
    maintenancetype CHAR(3) NOT NULL,
    maintenance_date DATE,
    parts_replaced VARCHAR(255),
    technicians VARCHAR(100) NOT NULL,
    labored_hours INT NOT NULL,
    FOREIGN KEY (record_id) REFERENCES AircraftMaintenanceTask(task_id), 
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (maintenancetype) REFERENCES MaintenanceSchedule(maintenancetype),
    FOREIGN KEY (parts_used) REFERENCES UtilizedComponents(component_id),
    FOREIGN KEY (personnel_id) REFERENCES MaintenancePersonnel(employeeID)
);

--Component/Parts Tracking
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

--Maintenance Personnel Records (Uses employee info)
CREATE TABLE MaintenancePersonnel(
    employeeID INT PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    lname VARCHAR(250) NOT NULL,
    qualification VARCHAR(100),
    certification VARCHAR(100),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID),
    FOREIGN KEY (fname) REFERENCES Employee(fname),
    FOREIGN KEY (lname) REFERENCES Employee(lname)
);

-- Maintenance Tasks
CREATE TABLE MaintenanceTask (
    task_id INT PRIMARY KEY,
    task_name VARCHAR(100),
    mdescription VARCHAR(250),
    task_status BOOLEAN
);

-- Aircraft-MaintenanceTask Mapping  ***WHAT IS THE POINT OF THIS?
CREATE TABLE AircraftMaintenanceTask (
    aircraft_id VARCHAR(250), --NOT PRIMARY KEY
    task_id INT PRIMARY KEY (task_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (task_id) REFERENCES MaintenanceTask(task_id)
);
/*
-- Create table for Maintenance Alerts and Notifications
CREATE TABLE MaintenanceAlert (
alert_id INT PRIMARY KEY,
aircraft_id INT,
alert_type VARCHAR(50),
alert_date DATE,
description VARCHAR(255),
FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);
*/
--Inventory Management (Food, paper, etc)
CREATE TABLE SupplyInventory (
    inventory_id INT PRIMARY KEY,
    supply_name VARCHAR(100),
    supplier VARCHAR(200),
    quantity INT,
    slocation VARCHAR(100),
    procurement_date DATE,
    FOREIGN KEY supplier REFERENES manufacter(manufacter)
);

--Compliance and Regulatory Data
CREATE TABLE Compliance (
    compliance_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250),
    document_type VARCHAR(50),
    document_number VARCHAR(50), --Unique?
    compliance_date DATE,
    expiration_date DATE,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

--Aircraft Health (Status) Monitoring
CREATE TABLE HealthMonitoring (
    monitoring_id INT PRIMARY KEY, --DIFF between this and part monitor?
    partmonitor_id INT,
    aircraft_id VARHCAR(250),
    monitoring_date DATE,
    system_name VARCHAR(100),
    astatus VARCHAR(20),  --Same as airplane status?
    healthdate DATE,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (partmonitor_id) REFERENCES UtilizedComponents(component_id)
);
-- Incident and Accident Reports
CREATE TABLE Incident (
    incident_id INT PRIMARY KEY,
    aircraft_id VARHCAR(250),
    incident_date DATE,
    idescription VARCHAR(250),
    investigation_status VARCHAR(50),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Reliability and Performance Metrics
CREATE TABLE PerformanceMetrics (
    metric_id INT PRIMARY KEY,
    aircraft_id VARHCAR(250),
    metric_name VARCHAR(100),
    PMvalue DECIMAL(10,2),
    metric_date DATE,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Routes Tables
CREATE TABLE aRoute (
    route_id INT PRIMARY KEY,
    origin VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    day_of_week VARCHAR(9),
    triplength DECIMAL(10,2) NOT NULL,
    model VARCHAR(250) NOT NULL,
    FOREIGN KEY model REFERENCES Airplane(model)
);

-- Flights
CREATE TABLE Flight (
    flight_id INT PRIMARY KEY,
    route_id INT NOT NULL,
    aircraft_id INT NOT NULL,
    departurelocation VARCHAR(250) NOT NULL,
    departure_date DATE NOT NULL,
    departure_time TIME,
    arrivallocation VARCHAR(250) NOT NULL,
    arrival_date DATE NOT NULL,
    arrival_time TIME,
    flightlength INT, 
    FOREIGN KEY (departurelocation, arrivallocation) REFERENCES AirportLocations(airport_id),
    FOREIGN KEY (route_id) REFERENCES aRoute(route_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Airport Locations
CREATE TABLE AirportLocations (
    airport_id CHAR(3) PRIMARY KEY,
    airport_code VARCHAR(3) UNIQUE,
    airport_name VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
);

-- Tickets
Create Table Tickets (
    Ticket_no Int Primary Key,
    Ticket_Price REAL NOT NULL,
    flight_id INT NOT NULL,
    CABINCLASS ENUM('Active', 'Depot', 'Maintenance', 'Retired') NOT NULL,
    Discount_percentage INT, 
    Ticketpriceafterdiscount REAL,
    FOREIGN KEY (flight_id) REFERENCES flight(flight_id),
    FOREIGN KEY (discount_percentage) REFERENCES Discounts(discount_percentage),
);

 -- Discounts
CREATE TABLE Discounts (
    discount_percentage Int Primary Key,
    discount_applied Int,
    discounttype VARCHAR(50) NOT NULL,
);

-- Airport Services
CREATE TABLE AirportServices (
    service_id SERIAL PRIMARY KEY,
    airport_id INT,
    totallaborhours REAL NOT NULL,
    employeeID INT,
    service_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (airport_id) REFERENCES AirportLocations(airport_id),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
);

-- Crew Scheduling
CREATE TABLE CrewSchedulelog (
    schedule_id SERIAL PRIMARY KEY,
    flight_id INT, --Does not need to be on a flight
    employee_id INT NOT NULL,
    duty_date DATE NOT NULL,
    duty_shift_start TIME NOT NULL,
    duty_shift_end TIME NOT NULL,
    duty_type VARCHAR(50),
    FOREIGN KEY (flight_id) REFERENCES Flight(flight_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(employeeID)
);