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
    fname VARCHAR(255) NOT NULL,
    mname VARCHAR(255),
    lname VARCHAR(255),
    email VARCHAR(255), 
    
)