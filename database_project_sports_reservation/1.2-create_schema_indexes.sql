/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 1.2-create_schema_indexes.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script creates indexes for the database schema.

    The indexes are created especially for:
    - all foreign key columns
    - frequent searches in reservations
    - frequent searches in maintenance periods
    - queries used later by views, procedures and functions

*/



-- Indexes for table Customer

-- FK_Customer_Person uses column person_id.
-- This index supports joins between Customer and Person.

CREATE INDEX IX_Customer_person_id
ON Customer (person_id);
GO



-- Indexes for table Employee

-- FK_Employee_Person uses column person_id.
-- This index supports joins between Employee and Person.

CREATE INDEX IX_Employee_person_id
ON Employee (person_id);
GO


-- Indexes for table Court

-- FK_Court_Sport uses column sport_id.
-- This index supports joins between Court and Sport and queries listing all courts for a selected sport.

CREATE INDEX IX_Court_sport_id
ON Court (sport_id);
GO



-- Indexes for table Tariff

-- This index supports searching for the currently valid tariff of a selected sport and date.

CREATE INDEX IX_Tariff_sport_validity
ON Tariff (sport_id, valid_from);
GO



-- Indexes for table Reservation

-- FK_Reservation_Customer uses column customer_id.
-- This index supports queries listing reservations of one customer.

CREATE INDEX IX_Reservation_customer_id
ON Reservation (customer_id);
GO


-- FK_Reservation_Court uses column court_id.
-- This index supports joins between Reservation and Court.

CREATE INDEX IX_Reservation_court_id
ON Reservation (court_id);
GO


-- FK_Reservation_ReservationStatus uses column status_id.
-- This index supports filtering reservations by their status.

CREATE INDEX IX_Reservation_status_id
ON Reservation (status_id);
GO


-- This index is important for checking court availability.
-- It supports searches for reservations of a selected court in a selected time interval.

CREATE INDEX IX_Reservation_court_time
ON Reservation (court_id, start_time, end_time);
GO


-- This index supports daily schedules and views ordered by reservation time.

CREATE INDEX IX_Reservation_start_time
ON Reservation (start_time);
GO


-- This index supports queries searching reservations by status and time.
-- It will be useful for views such as active reservations or daily schedule.

CREATE INDEX IX_Reservation_status_time
ON Reservation (status_id, start_time, end_time);
GO



-- Indexes for table Payment

-- FK_Payment_Reservation uses column reservation_id.
-- The column already has a UNIQUE constraint, but this explicit index is not necessary because SQL Server automatically 
-- creates an index for the unique constraint AK_Payment_reservation_id, so we don't create another duplicate index on reservation_id.



-- FK_Payment_Employee uses column employee_id.
-- This index supports joins between Payment and Employee and queries listing payments registered by one employee.

CREATE INDEX IX_Payment_employee_id
ON Payment (employee_id);
GO


-- This index supports filtering and ordering payments by payment date.

CREATE INDEX IX_Payment_payment_date
ON Payment (payment_date);
GO



-- Indexes for table Maintenance

-- FK_Maintenance_Court uses column court_id.
-- This index supports joins between Maintenance and Court.

CREATE INDEX IX_Maintenance_court_id
ON Maintenance (court_id);
GO


-- FK_Maintenance_Employee uses column employee_id.
-- This index supports joins between Maintenance and Employee.

CREATE INDEX IX_Maintenance_employee_id
ON Maintenance (employee_id);
GO


-- This index is important for checking if a court is under maintenance during a selected time interval.

CREATE INDEX IX_Maintenance_court_time
ON Maintenance (court_id, start_time, end_time);
GO


-- This index supports views listing maintenance periods by time.

CREATE INDEX IX_Maintenance_start_time
ON Maintenance (start_time);
GO

