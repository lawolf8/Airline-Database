
/*1*/	IF OBJECT_ID('tickets') IS NOT NULL DROP TABLE tickets;
/*2*/	IF OBJECT_ID('locations') IS NOT NULL DROP TABLE locations;
/*3*/	IF OBJECT_ID('customers') IS NOT NULL DROP TABLE customers;
/*4*/	IF OBJECT_ID('planes_maintenances') IS NOT NULL DROP TABLE planes_maintenances;
/*5*/	IF OBJECT_ID('maintenances') IS NOT NULL DROP TABLE maintenances;
/*6*/	IF OBJECT_ID('flights_employees') IS NOT NULL DROP TABLE flights_employees;
/*7*/	IF OBJECT_ID('routes_cabin_types') IS NOT NULL DROP TABLE routes_cabin_types;
/*8*/	IF OBJECT_ID('discounts') IS NOT NULL DROP TABLE discounts;
/*9*/	IF OBJECT_ID('location_types') IS NOT NULL DROP TABLE location_types;
/*10*/	IF OBJECT_ID('employees_job_positions') IS NOT NULL DROP TABLE employees_job_positions;
/*11*/	IF OBJECT_ID('payment_types') IS NOT NULL DROP TABLE payment_types;
/*12*/	IF OBJECT_ID('employees') IS NOT NULL DROP TABLE employees;
/*13*/	IF OBJECT_ID('cabin_types') IS NOT NULL DROP TABLE cabin_types;
/*14*/	IF OBJECT_ID('flights') IS NOT NULL DROP TABLE flights;
/*15*/	IF OBJECT_ID('planes') IS NOT NULL DROP TABLE planes;
/*16*/	IF OBJECT_ID('job_positions') IS NOT NULL DROP TABLE job_positions;
/*17*/	IF OBJECT_ID('routes') IS NOT NULL DROP TABLE routes;
/*18*/	IF OBJECT_ID('cities_states') IS NOT NULL DROP TABLE cities_states;
/*19*/	IF OBJECT_ID('weekdays') IS NOT NULL DROP TABLE weekdays;
/*20*/	IF OBJECT_ID('zipcodes') IS NOT NULL DROP TABLE zipcodes;
/*21*/	IF OBJECT_ID('states') IS NOT NULL DROP TABLE states;
/*22*/	IF OBJECT_ID('flights_roles') IS NOT NULL DROP TABLE flights_roles;


 


go

CREATE TABLE employees (
  employee_id					int not null,
  first_name					varchar(50) null,
  last_name						varchar(50) null, 
  birth_date					date null,
  hire_date						date null,
  email							varchar(50) null,
  gender						char null,
  ssn							varchar(50) null,
  phone1						varchar(50) null,
  phone2						varchar(50) null,
  address_line1					varchar(50) null,
  address_line2					varchar(50) null,
  zipcode_id					int null,
  city_state_id					int null,
  job_position_id				int null,
  employee_id_reports_to		int null,
  flight_role_id				int null
);


CREATE TABLE job_positions (
  job_position_id				int not null,
  name							varchar(50) null,
  description					varchar(800) null,
  salary_base					decimal(10,2) null
);



CREATE TABLE tickets (
  ticket_id						int not null,
  flight_id						int null,
  customer_id					int null,
  employee_id					int null,
  purchase_date					date null,
  purchase_time					time null,
  boarding_date					date null,
  boarding_time					time null,
  purchase_location_id			int null,
  cabin_type_id					int null,
  discount_id					int null,
  final_price					decimal(10,2) null,
  payment_type_id				int null
);


CREATE TABLE locations (
  location_id					int not null,
  name							varchar(50) null,
  location_type_id				int null,
  address_line1					varchar(50) null,
  address_line2					varchar(50) null,
  zipcode_id					int null,
  city_state_id					int null
);


CREATE TABLE location_types (
  location_type_id				int not null,
  name							varchar(50) null
);


CREATE TABLE cabin_types (
  cabin_type_id					int not null,
  name							varchar(50) null
);


CREATE TABLE flights (
  flight_id						int not null,
  date							date null,
  start_time_actual				time null,
  end_time_actual				time null,
  route_id						int null,
  plane_id						int null
);

CREATE TABLE routes (
  route_id						int not null,
  city_state_id_origin			int null,
  city_state_id_destination		int null,
  start_time					time null,
  end_time						time null,
  weekday_id					int null
);


CREATE TABLE zipcodes (
  zipcode_id					int not null,
  name							varchar(50) null,
  state_id						int null
);


CREATE TABLE cities_states (
  city_state_id					int not null,
  name							varchar(50) null,
  state_id						int null
);


CREATE TABLE states (
  state_id						int not null,
  name							varchar(50) null
);


CREATE TABLE customers (
  customer_id					int not null,
  first_name					varchar(50) null,
  last_name						varchar(50) null, 
  birth_date					date null,
  start_date					date null,
  email							varchar(50) null,
  gender						char null,
  phone1						varchar(50) null,
  phone2						varchar(50) null,
  address_line1					varchar(50) null,
  address_line2					varchar(50) null,
  zipcode_id					int null,
  city_state_id					int null
);


CREATE TABLE planes (
  plane_id						int not null,
  fabrication_date				date null,
  first_use_date				date null,
  brand							varchar(50) null,
  model							varchar(50) null,
  capacity						int null
);


CREATE TABLE planes_maintenances (
  plane_maintenance_id			int not null,
  plane_id						int not null,
  maintenance_id				int not null,
  date							date null,
  status						int null,
  observations					varchar(50) null,
  employee_id					int null
);


CREATE TABLE maintenances (
  maintenance_id				int not null,
  name							varchar(800) null,
  observations					varchar(800) null
);


CREATE TABLE flights_employees (
  flight_id						int not null,
  employee_id					int not null
);


CREATE TABLE flights_roles (
  flight_role_id				int not null,
  name							varchar(50) null
);


CREATE TABLE routes_cabin_types (
  route_cabin_type_id			int not null,
  route_id						int not null,
  cabin_type_id					int not null,
  price							decimal(10,2) null,
  start_date					date null,
  end_date						date null
);


CREATE TABLE employees_job_positions (
  employee_job_position_id		int not null,
  employee_id					int not null,
  job_position_id				int not null,
  salary						decimal(10,2) null,
  start_date					date null,
  end_date						date null
);


CREATE TABLE discounts (
  discount_id				    int not null,
  name							varchar(50) null,
  percentage					decimal(5,2) null,
  observations					varchar(800) null,					
  start_date					date null,
  end_date						date null
);


CREATE TABLE payment_types (
  payment_type_id				int not null,
  name							varchar(50) null
);


CREATE TABLE weekdays (
  weekday_id					int not null,
  name							varchar(50) null,
  day_order						int null
);






ALTER TABLE employees ADD CONSTRAINT pk_employees PRIMARY KEY (employee_id);
ALTER TABLE tickets ADD CONSTRAINT pk_tickets PRIMARY KEY (ticket_id);
ALTER TABLE locations ADD CONSTRAINT pk_locations PRIMARY KEY (location_id);
ALTER TABLE cabin_types ADD CONSTRAINT pk_cabin_types PRIMARY KEY (cabin_type_id);
ALTER TABLE flights ADD CONSTRAINT pk_flights PRIMARY KEY (flight_id);
ALTER TABLE routes ADD CONSTRAINT pk_routes PRIMARY KEY (route_id);
ALTER TABLE customers ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);
ALTER TABLE planes ADD CONSTRAINT pk_trains PRIMARY KEY (plane_id);
ALTER TABLE planes_maintenances ADD CONSTRAINT pk_planes_maintenances PRIMARY KEY (plane_maintenance_id);
ALTER TABLE maintenances ADD CONSTRAINT pk_maintenances PRIMARY KEY (maintenance_id);
ALTER TABLE flights_employees ADD CONSTRAINT pk_flights_employees PRIMARY KEY (flight_id, employee_id);
ALTER TABLE routes_cabin_types ADD CONSTRAINT pk_routes_cabin_type PRIMARY KEY (route_cabin_type_id);
ALTER TABLE discounts ADD CONSTRAINT pk_discounts PRIMARY KEY (discount_id);
ALTER TABLE job_positions ADD CONSTRAINT pk_job_positions PRIMARY KEY (job_position_id);
ALTER TABLE location_types ADD CONSTRAINT pk_location_types PRIMARY KEY (location_type_id);
ALTER TABLE cities_states ADD CONSTRAINT pk_cities_states PRIMARY KEY (city_state_id);
ALTER TABLE states ADD CONSTRAINT pk_states PRIMARY KEY (state_id);
ALTER TABLE weekdays ADD CONSTRAINT pk_weekdays PRIMARY KEY (weekday_id);
ALTER TABLE zipcodes ADD CONSTRAINT pk_zipcodes PRIMARY KEY (zipcode_id);
ALTER TABLE employees_job_positions ADD CONSTRAINT pk_employees_job_positions PRIMARY KEY (employee_job_position_id);
ALTER TABLE payment_types ADD CONSTRAINT pk_payment_types PRIMARY KEY (payment_type_id);
ALTER TABLE flights_roles ADD CONSTRAINT pk_flights_roles PRIMARY KEY (flight_role_id);

go



ALTER TABLE planes_maintenances ADD CONSTRAINT fk_planes_maintenances_planes FOREIGN KEY (plane_id) REFERENCES planes (plane_id);
ALTER TABLE planes_maintenances ADD CONSTRAINT fk_planes_maintenances_maintenances FOREIGN KEY (maintenance_id) REFERENCES maintenances (maintenance_id);
ALTER TABLE planes_maintenances ADD CONSTRAINT fk_planes_maintenances_employees FOREIGN KEY (employee_id) REFERENCES employees (employee_id);

ALTER TABLE flights ADD CONSTRAINT fk_flights_routes FOREIGN KEY (route_id) REFERENCES routes (route_id);
ALTER TABLE flights ADD CONSTRAINT fk_flights_planes FOREIGN KEY (plane_id) REFERENCES planes (plane_id);

ALTER TABLE tickets ADD CONSTRAINT fk_tickets_customers FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_flights FOREIGN KEY (flight_id) REFERENCES flights (flight_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_locations FOREIGN KEY (purchase_location_id) REFERENCES locations (location_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_cabin_types FOREIGN KEY (cabin_type_id) REFERENCES cabin_types(cabin_type_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_employees FOREIGN KEY (employee_id) REFERENCES employees (employee_id);
ALTER TABLE tickets ADD CONSTRAINT fk_discounts_tickets FOREIGN KEY (discount_id) REFERENCES discounts (discount_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_payment_types FOREIGN KEY (payment_type_id) REFERENCES payment_types (payment_type_id);

ALTER TABLE flights_employees ADD CONSTRAINT fk_flights_employees_employees FOREIGN KEY (employee_id) REFERENCES employees (employee_id);
ALTER TABLE flights_employees ADD CONSTRAINT fk_flights_employees_flights FOREIGN KEY (flight_id) REFERENCES flights (flight_id);

ALTER TABLE routes_cabin_types ADD CONSTRAINT fk_routes_cabin_type_routes FOREIGN KEY (route_id) REFERENCES routes (route_id);
ALTER TABLE routes_cabin_types ADD CONSTRAINT fk_routes_cabin_type_cabin_types FOREIGN KEY (cabin_type_id) REFERENCES cabin_types (cabin_type_id);

ALTER TABLE employees_job_positions ADD CONSTRAINT fk_employees_job_positions_job_positions FOREIGN KEY (job_position_id) REFERENCES job_positions (job_position_id);
ALTER TABLE employees_job_positions ADD CONSTRAINT fk_employees_job_positions_employees FOREIGN KEY (employee_id) REFERENCES employees (employee_id);

ALTER TABLE routes ADD CONSTRAINT fk_routes_cities_states_origin FOREIGN KEY (city_state_id_origin) REFERENCES cities_states (city_state_id);
ALTER TABLE routes ADD CONSTRAINT fk_routes_cities_states_destination FOREIGN KEY (city_state_id_destination) REFERENCES cities_states (city_state_id);
ALTER TABLE routes ADD CONSTRAINT fk_routes_weekdays FOREIGN KEY (weekday_id) REFERENCES weekdays (weekday_id);

ALTER TABLE cities_states ADD CONSTRAINT fk_cities_states_states FOREIGN KEY (state_id) REFERENCES states (state_id);

ALTER TABLE employees ADD CONSTRAINT fk_employees_cities_states FOREIGN KEY (city_state_id) REFERENCES cities_states (city_state_id);
ALTER TABLE employees ADD CONSTRAINT fk_employees_zipcodes FOREIGN KEY (zipcode_id) REFERENCES zipcodes (zipcode_id);
ALTER TABLE employees ADD CONSTRAINT fk_employees_flights_roles FOREIGN KEY (flight_role_id) REFERENCES flights_roles (flight_role_id);

ALTER TABLE customers ADD CONSTRAINT fk_customers_cities_states FOREIGN KEY (city_state_id) REFERENCES cities_states (city_state_id);
ALTER TABLE customers ADD CONSTRAINT fk_customers_zipcodes FOREIGN KEY (zipcode_id) REFERENCES zipcodes (zipcode_id);

ALTER TABLE locations ADD CONSTRAINT fk_locations_zipcodes FOREIGN KEY (zipcode_id) REFERENCES zipcodes (zipcode_id);
ALTER TABLE locations ADD CONSTRAINT fk_locations_cities_states FOREIGN KEY (city_state_id) REFERENCES cities_states (city_state_id);
ALTER TABLE locations ADD CONSTRAINT fk_locations_location_types FOREIGN KEY (location_type_id) REFERENCES location_types (location_type_id);

ALTER TABLE zipcodes ADD CONSTRAINT fk_zipcodes_states FOREIGN KEY (state_id) REFERENCES states (state_id);