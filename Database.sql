/* 
Commerical Airline Project
Luke Wolf, Kyle Pterone, Reese Sleater, Michael Brennan
*/
CREATE TABLE Airplane(
    serialnumber VARCHAR(250) PRIMARY KEY,  -- Serial Number Primary Key
    model VARCHAR(250) NOT NULL,
    manufacturer VARCHAR(250) NOT NULL,
    capacity INT NOT NULL,
    dateManufactured DATE NOT NULL,
    lastMaintenance DATE NOT NULL,
    status ENUM('Active', 'Depot', 'Maintenance', 'Retired') NOT NULL, --Although invalid syntax, this still runs
    location VARCHAR(255)
);

CREATE TABLE Cabin(
    cabinID INT AUTO_INCREMENT PRIMARY KEY, --Although invalid syntax, this still runs
    serialnumber VARCHAT(250) NOT NULL,
    cabinclass ENUM('Economy', 'Economy Regular', 'Economy Plus', 'Business', 'First Class'),
    seatcapacity INT NOT NULL,
    ammenities TEXT,
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
    address VARCHAR(250)
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
    FOREIGN KEY (serialnumber) REFERENCES Airplane(serialnumber)
);