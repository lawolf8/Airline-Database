/* 
Commerical Airline Project
Luke Wolf, Kyle Pterone, Reece Sleater, Michael Brennan
ALL TABLES ARE VERIFIED IN 3RD NORMAL FORM
*/
--Aircraft Status
CREATE TABLE AircraftStatus (
    statusID INT IDENTITY(1,1) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL
);

-- Airplane Identification
CREATE TABLE Airplane (
    serialnumber VARCHAR(250) PRIMARY KEY,
    manufacturerserialnumber VARCHAR(250) UNIQUE NOT NULL,
    model VARCHAR(250) NOT NULL,
    manufacturer VARCHAR(250) NOT NULL,
    capacity INT NOT NULL,
    dateManufactured DATE NOT NULL,
    lastMaintenance DATE NOT NULL,
    airstatus INT NOT NULL,
    alocation VARCHAR(255),
    FOREIGN KEY (airstatus) REFERENCES AircraftStatus(statusID)
);

--Cabin Class
CREATE TABLE CabinClass (
    classID INT IDENTITY(1,1) PRIMARY KEY,
    className VARCHAR(50) NOT NULL
);

-- Cabin Information
CREATE TABLE Cabin (
    cabinID INT IDENTITY(1,1) PRIMARY KEY, 
    serialnumber VARCHAR(250) NOT NULL,
    classID INT NOT NULL,
    seatcapacity INT NOT NULL,
    ammenities VARCHAR(250),
    FOREIGN KEY (serialnumber) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (classID) REFERENCES CabinClass(classID)
);

-- Customer Information
CREATE TABLE Customer (
    customerID INT IDENTITY(1,1) PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    mname VARCHAR(250),
    lname VARCHAR(250) NOT NULL,
    email VARCHAR(250) NOT NULL, 
    phonenumber VARCHAR(20),
    dateofbirth DATE,
    registration DATE,
    airlinepoints INT DEFAULT 0,
    registrationstatus BIT DEFAULT 0,
    caddress VARCHAR(250)
);

-- Customer Black List
CREATE TABLE Customerblacklist (
    customerID INT,
    reason VARCHAR(250),
    dateofbl DATE,
    PRIMARY KEY (customerID),
    FOREIGN KEY (customerID) REFERENCES Customer(customerID)
);

-- Position Table
CREATE TABLE Position (
    positionID INT IDENTITY(1,1) PRIMARY KEY,
    position VARCHAR(250) NOT NULL
);

-- Employee Table
CREATE TABLE Employee (
    employeeID INT IDENTITY(1,1) PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    mname VARCHAR(250),
    lname VARCHAR(250) NOT NULL,
    email VARCHAR(250) NOT NULL,
    phonenumber VARCHAR(20) NOT NULL,
    dateofbirth DATE NOT NULL,
    positionID INT NOT NULL,
    onboarddate DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    employeeLevel INT NOT NULL CHECK (employeeLevel BETWEEN 1 AND 10),
    employementstatus BIT NOT NULL,
    FOREIGN KEY (positionID) REFERENCES Position(positionID)
);

-- EmployeeAirplane (managing many-to-many relationship between Employee and Airplane)
CREATE TABLE EmployeeAirplane (
    employeeID INT,
    serialNumber VARCHAR(250),
    PRIMARY KEY (employeeID, serialNumber),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID),
    FOREIGN KEY (serialNumber) REFERENCES Airplane(serialNumber)
);

-- Manufacturer Information
CREATE TABLE Manufacturer (
    manufacturer VARCHAR(250) PRIMARY KEY,
    contact_name VARCHAR(100),
    contact_email VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    maddress VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100)
);

-- Parts Library
CREATE TABLE PartsLibrary (
    component_id INT PRIMARY KEY,
    manufacturer VARCHAR(250) NOT NULL,
    part_name VARCHAR(250), 
    numberofcomponentsstocked INT,
    endlifehours INT CHECK (endlifehours > 0),
    procurement_date DATE,
    partlocation VARCHAR(250),
    FOREIGN KEY (manufacturer) REFERENCES Manufacturer(manufacturer)
);

-- Scheduled Maintenance
CREATE TABLE MaintenanceSchedule (
    schedule_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250) NOT NULL,
    maintenance_type CHAR(3) NOT NULL,
    task_description VARCHAR(255),
    due_date DATE NOT NULL,
    due_hours INT,
    expected_labored_hours INT NOT NULL,
    task_comments VARCHAR(250),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Maintenance Records
CREATE TABLE MaintenanceRecord (
    record_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250) NOT NULL,
    maintenance_type CHAR(3) NOT NULL,
    maintenance_date DATE,
    parts_replaced VARCHAR(255),
    technicians VARCHAR(100) NOT NULL,
    labored_hours INT NOT NULL,
    FOREIGN KEY (record_id) REFERENCES MaintenanceSchedule(schedule_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

--Component Status ID
CREATE TABLE ComponentLifeStatus (
    statusID INT IDENTITY(1,1) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL
);

-- Component/Parts Tracking
CREATE TABLE UtilizedComponents (
    component_id INT,
    aircraft_id VARCHAR(250),
    component_name VARCHAR(100),
    manufacturer VARCHAR(250) NOT NULL,
    installation_date DATE NOT NULL,
    removal_date DATE,
    statusID INT NOT NULL,
    labored_hours INT NOT NULL,
    maintenance_comments VARCHAR(250),
    part_hours INT,
    PRIMARY KEY (component_id, aircraft_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (manufacturer) REFERENCES Manufacturer(manufacturer),
    FOREIGN KEY (statusID) REFERENCES ComponentLifeStatus(statusID)
);

-- Maintenance Personnel Records (Uses employee info)
CREATE TABLE MaintenancePersonnel(
    employeeID INT PRIMARY KEY,
    fname VARCHAR(250) NOT NULL,
    lname VARCHAR(250) NOT NULL,
    qualification VARCHAR(100),
    certification VARCHAR(100)
);

-- Maintenance Tasks
CREATE TABLE MaintenanceTask (
    task_id INT PRIMARY KEY,
    task_name VARCHAR(100),
    description VARCHAR(250),
    task_status BIT
);

-- Aircraft-MaintenanceTask Mapping
CREATE TABLE AircraftMaintenanceTask (
    aircraft_id VARCHAR(250),
    task_id INT,
    PRIMARY KEY (aircraft_id, task_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (task_id) REFERENCES MaintenanceTask(task_id)
);

-- Inventory Management (Food, paper, etc.)
CREATE TABLE SupplyInventory (
    inventory_id INT PRIMARY KEY,
    supply_name VARCHAR(100),
    supplier VARCHAR(250),
    quantity INT,
    slocation VARCHAR(100),
    procurement_date DATE,
    FOREIGN KEY (supplier) REFERENCES Manufacturer(manufacturer) 
);

-- Compliance and Regulatory Data
CREATE TABLE Compliance (
    compliance_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250),
    document_type VARCHAR(50),
    document_number VARCHAR(50) UNIQUE,
    compliance_date DATE,
    expiration_date DATE,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Aircraft Health (Status) Monitoring
CREATE TABLE HealthMonitoring (
    monitoring_id INT PRIMARY KEY,
    partmonitor_id INT,
    aircraft_id VARCHAR(250), 
    monitoring_date DATE,
    system_name VARCHAR(100),
    airstatus INT NOT NULL, 
    healthdate DATE,
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber),
    FOREIGN KEY (partmonitor_id) REFERENCES UtilizedComponents(component_id),
    FOREIGN KEY (airstatus) REFERENCES AircraftStatus(statusID)
);

-- Incident and Accident Reports
CREATE TABLE Incident (
    incident_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250),
    incident_date DATE,
    description VARCHAR(250), 
    investigation_status VARCHAR(50),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Reliability and Performance Metrics
CREATE TABLE PerformanceMetrics (
    metric_id INT PRIMARY KEY,
    aircraft_id VARCHAR(250),
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
    model VARCHAR(250) NOT NULL
);

-- Flights
CREATE TABLE Flight (
    flight_id INT PRIMARY KEY,
    route_id INT NOT NULL,
    aircraft_id VARCHAR(250) NOT NULL,
    departure_date DATE NOT NULL,
    departure_time TIME,
    arrival_date DATE NOT NULL,
    arrival_time TIME,
    flightlength INT,
    FOREIGN KEY (route_id) REFERENCES aRoute(route_id),
    FOREIGN KEY (aircraft_id) REFERENCES Airplane(serialnumber)
);

-- Airport Locations
CREATE TABLE AirportLocations (
    airport_id CHAR(3) PRIMARY KEY,
    airport_code VARCHAR(3) UNIQUE,
    airport_name VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100)
);

-- Tickets
CREATE TABLE Tickets (
    ticket_no INT PRIMARY KEY,
    ticket_price REAL NOT NULL,
    flight_id INT NOT NULL,
    classID INT NOT NULL, 
    discount_percentage INT,
    ticketpriceafterdiscount REAL,
    FOREIGN KEY (flight_id) REFERENCES Flight(flight_id),
    FOREIGN KEY (classID) REFERENCES CabinClass(classID)
);

 -- Discounts
CREATE TABLE Discounts (
    discount_percentage INT PRIMARY KEY,
    discount_applied INT,
    discount_type VARCHAR(50) NOT NULL 
);

-- Airport Services
CREATE TABLE AirportServices (
    service_id INT IDENTITY(1,1) PRIMARY KEY,
    airport_id CHAR(3),
    totallaborhours REAL NOT NULL,
    employeeID INT,
    service_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (airport_id) REFERENCES AirportLocations(airport_id),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
);

-- Crew Scheduling
CREATE TABLE CrewScheduleLog (
    schedule_id INT IDENTITY(1,1) PRIMARY KEY,
    flight_id INT,
    employee_id INT NOT NULL,
    duty_date DATE NOT NULL,
    duty_shift_start TIME NOT NULL,
    duty_shift_end TIME NOT NULL,
    duty_type VARCHAR(50),
    FOREIGN KEY (flight_id) REFERENCES Flight(flight_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(employeeID)
);