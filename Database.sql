/* 
Commerical Airline Project
Luke Wolf, Kyle Pterone, Reese Sleater, Michael Brennan
*/
CREATE TABLE Airplane(
    serialnumber VARCHAR(250) PRIMARY KEY,
    model VARCHAR(250) NOT NULL,
    manufacturer VARCHAR(250) NOT NULL,
    capacity INT NOT NULL,
    dateManufactured DATE NOT NULL,
    lastMaintenance DATE NOT NULL,
    status ENUM('Active', 'Depot', 'Maintenance', 'Retired') NOT NULL, --Although invalid syntax, this still runs
    location VARCHAR(255)
);