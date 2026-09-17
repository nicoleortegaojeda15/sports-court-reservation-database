/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 1.0-create_schema_tables.sql

    Topic:
    Sports Court Reservation System

    This database application manages reservations of sports courts in a sports centre.
    The application stores persons, customers, employees, sports, courts, tariffs,
    reservations, payments and maintenance periods.

    Main business rules:
    - A person can be a customer, an employee or both at the same time.
    - Personal information is stored only once.
    - A customer can create reservations for available sports courts.
    - A court cannot be reserved twice for overlapping time intervals.
    - A court cannot be reserved during a maintenance period.
    - Each reservation has a status (Pending, Confirmed, Cancelled or Completed).
    - A reservation can have at most one payment.
    - Employees can register payments and maintenance periods.

    This script creates all base tables.
*/


------------------------------------------------------------
-- Table: Person

-- Meaning:
-- Stores personal information shared by customers and employees.

-- Columns:
-- person_id
-- first_name
-- last_name
-- email
-- phone
-- is_active
------------------------------------------------------------

CREATE TABLE Person
(
    person_id INT IDENTITY(1,1) NOT NULL,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    phone NVARCHAR(30) NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_Person_is_active DEFAULT 1,

    CONSTRAINT PK_Person
        PRIMARY KEY (person_id),

    CONSTRAINT AK_Person_email
        UNIQUE (email),

    CONSTRAINT CK_Person_first_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(first_name))) > 0),

    CONSTRAINT CK_Person_last_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(last_name))) > 0),

    CONSTRAINT CK_Person_email_not_empty
        CHECK (LEN(LTRIM(RTRIM(email))) > 0)
);
GO



------------------------------------------------------------
-- Table: Customer

-- Meaning:
-- Stores customers of the sports centre.
-- Personal information is stored in table Person.

-- Columns:
-- customer_id       - artificial primary key
-- person_id         - reference to Person
-- registration_date - date when the customer was registered
------------------------------------------------------------

CREATE TABLE Customer
(
    customer_id INT IDENTITY(1,1) NOT NULL,
    person_id INT NOT NULL,
    registration_date DATETIME2(0) NOT NULL
        CONSTRAINT DF_Customer_registration_date DEFAULT SYSDATETIME(),
    is_active BIT NOT NULL
        CONSTRAINT DF_Customer_is_active DEFAULT 1,

    CONSTRAINT PK_Customer
        PRIMARY KEY (customer_id),

    CONSTRAINT AK_Customer_person
        UNIQUE (person_id),

    CONSTRAINT FK_Customer_Person
        FOREIGN KEY (person_id)
        REFERENCES Person(person_id)
);
GO

------------------------------------------------------------
-- Table: Sport

-- Meaning: Stores sports available in the sports centre.

-- Columns:
-- sport_id    - artificial primary key of the sport
-- sport_name  - name of the sport, for example Tennis
-- description - optional description of the sport
------------------------------------------------------------

CREATE TABLE Sport
(
    sport_id INT IDENTITY(1,1) NOT NULL,
    sport_name NVARCHAR(50) NOT NULL,
    description NVARCHAR(250) NULL,

    CONSTRAINT PK_Sport
        PRIMARY KEY (sport_id),

    CONSTRAINT AK_Sport_sport_name
        UNIQUE (sport_name),

    CONSTRAINT CK_Sport_sport_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(sport_name))) > 0)
);
GO

------------------------------------------------------------
-- Table: Employee

-- Meaning:
-- Stores employees of the sports centre.
-- Personal information is stored in table Person.

-- Columns:
-- employee_id - artificial primary key
-- person_id   - reference to Person
-- role_name   - employee role
------------------------------------------------------------

CREATE TABLE Employee
(
    employee_id INT IDENTITY(1,1) NOT NULL,
    person_id INT NOT NULL,
    role_name NVARCHAR(50) NOT NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_Employee_is_active DEFAULT 1,

    CONSTRAINT PK_Employee
        PRIMARY KEY (employee_id),

    CONSTRAINT AK_Employee_person
        UNIQUE (person_id),

    CONSTRAINT FK_Employee_Person
        FOREIGN KEY (person_id)
        REFERENCES Person(person_id),

    CONSTRAINT CK_Employee_role_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(role_name))) > 0)
);
GO

------------------------------------------------------------
-- Table: ReservationStatus

-- Meaning: Stores allowed reservation statuses.
-- Example values are Pending, Confirmed, Cancelled and Completed.

-- Columns:
-- status_id   - artificial primary key of the status
-- status_name - unique name of the reservation status
------------------------------------------------------------

CREATE TABLE ReservationStatus
(
    status_id INT IDENTITY(1,1) NOT NULL,
    status_name NVARCHAR(30) NOT NULL,

    CONSTRAINT PK_ReservationStatus
        PRIMARY KEY (status_id),

    CONSTRAINT AK_ReservationStatus_status_name
        UNIQUE (status_name),

    CONSTRAINT CK_ReservationStatus_status_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(status_name))) > 0)
);
GO

------------------------------------------------------------
-- Table: Court

-- Meaning: Stores sports courts available in the sports centre.
-- Each court belongs to exactly one sport.

-- Columns:
-- court_id   - artificial primary key of the court
-- sport_id   - reference to the sport played on the court
-- court_name - unique court name
-- location   - physical location of the court inside the centre
-- capacity   - maximum number of players allowed on the court
-- is_active  - indicates whether the court is normally available
------------------------------------------------------------

CREATE TABLE Court
(
    court_id INT IDENTITY(1,1) NOT NULL,
    sport_id INT NOT NULL,
    court_name NVARCHAR(50) NOT NULL,
    location NVARCHAR(100) NULL,
    capacity INT NOT NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_Court_is_active DEFAULT 1,

    CONSTRAINT PK_Court
        PRIMARY KEY (court_id),

    CONSTRAINT AK_Court_court_name
        UNIQUE (court_name),

    CONSTRAINT FK_Court_Sport
        FOREIGN KEY (sport_id)
        REFERENCES Sport(sport_id),

    CONSTRAINT CK_Court_court_name_not_empty
        CHECK (LEN(LTRIM(RTRIM(court_name))) > 0),

    CONSTRAINT CK_Court_capacity_positive
        CHECK (capacity > 0)
);
GO

------------------------------------------------------------
-- Table: Tariff

-- Meaning: Stores prices per hour for each sport.
-- A tariff can be valid only for a limited period of time.

-- Columns:
-- tariff_id      - artificial primary key of the tariff
-- sport_id       - reference to the sport
-- price_per_hour - price for one hour of reservation
-- valid_from     - first date when the tariff is valid
-- valid_to       - last date when the tariff is valid, NULL means still valid
------------------------------------------------------------

CREATE TABLE Tariff
(
    tariff_id INT IDENTITY(1,1) NOT NULL,
    sport_id INT NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,

    CONSTRAINT PK_Tariff
        PRIMARY KEY (tariff_id),

    CONSTRAINT AK_Tariff_sport_valid_from
        UNIQUE (sport_id, valid_from),

    CONSTRAINT FK_Tariff_Sport
        FOREIGN KEY (sport_id)
        REFERENCES Sport(sport_id),

    CONSTRAINT CK_Tariff_price_per_hour_positive
        CHECK (price_per_hour > 0),

    CONSTRAINT CK_Tariff_valid_dates
        CHECK (valid_to IS NULL OR valid_to > valid_from)
);
GO

------------------------------------------------------------
-- Table: Reservation

-- Meaning: Stores reservations created by customers.
-- Each reservation is connected with one customer, one court and one status.

-- Columns:
-- reservation_id - artificial primary key of the reservation
-- customer_id    - reference to the customer who created the reservation
-- court_id       - reference to the reserved court
-- status_id      - reference to the current reservation status
-- start_time     - start date and time of the reservation
-- end_time       - end date and time of the reservation
-- created_at    
-- cancelled_at  
-- total_price    
------------------------------------------------------------

CREATE TABLE Reservation
(
    reservation_id INT IDENTITY(1,1) NOT NULL,
    customer_id INT NOT NULL,
    court_id INT NOT NULL,
    status_id INT NOT NULL,
    start_time DATETIME2(0) NOT NULL,
    end_time DATETIME2(0) NOT NULL,
    created_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_Reservation_created_at DEFAULT SYSDATETIME(),
    cancelled_at DATETIME2(0) NULL,
    total_price DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_Reservation
        PRIMARY KEY (reservation_id),

    CONSTRAINT FK_Reservation_Customer
        FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id),

    CONSTRAINT FK_Reservation_Court
        FOREIGN KEY (court_id)
        REFERENCES Court(court_id),

    CONSTRAINT FK_Reservation_ReservationStatus
        FOREIGN KEY (status_id)
        REFERENCES ReservationStatus(status_id),

    CONSTRAINT CK_Reservation_time_interval
        CHECK (start_time < end_time),

    CONSTRAINT CK_Reservation_total_price_not_negative
        CHECK (total_price >= 0),

    CONSTRAINT CK_Reservation_cancelled_after_created
        CHECK (cancelled_at IS NULL OR cancelled_at >= created_at)
);
GO

------------------------------------------------------------
-- Table: Payment

-- Meaning: Stores payments for reservations.
-- Each reservation can have at most one payment.

-- Columns:
-- payment_id     - artificial primary key of the payment
-- reservation_id - reference to the paid reservation
-- employee_id    - employee who registered the payment
-- amount         
-- payment_date  
-- payment_method 
------------------------------------------------------------

CREATE TABLE Payment
(
    payment_id INT IDENTITY(1,1) NOT NULL,
    reservation_id INT NOT NULL,
    employee_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME2(0) NOT NULL
        CONSTRAINT DF_Payment_payment_date DEFAULT SYSDATETIME(),
    payment_method NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_Payment
        PRIMARY KEY (payment_id),

    CONSTRAINT AK_Payment_reservation_id
        UNIQUE (reservation_id),

    CONSTRAINT FK_Payment_Reservation
        FOREIGN KEY (reservation_id)
        REFERENCES Reservation(reservation_id),

    CONSTRAINT FK_Payment_Employee
        FOREIGN KEY (employee_id)
        REFERENCES Employee(employee_id),

    CONSTRAINT CK_Payment_amount_positive
        CHECK (amount > 0),

    CONSTRAINT CK_Payment_method
        CHECK (payment_method IN ('Cash', 'Card', 'BankTransfer'))
);
GO

------------------------------------------------------------
-- Table: Maintenance

-- Meaning: Stores maintenance periods for sports courts.
-- During maintenance, a court is not available for reservations.

-- Columns:
-- maintenance_id - artificial primary key of the maintenance record
-- court_id       - reference to the court under maintenance
-- employee_id    - employee who registered the maintenance
-- start_time     
-- end_time       
-- reason         - reason or description of the maintenance
------------------------------------------------------------

CREATE TABLE Maintenance
(
    maintenance_id INT IDENTITY(1,1) NOT NULL,
    court_id INT NOT NULL,
    employee_id INT NOT NULL,
    start_time DATETIME2(0) NOT NULL,
    end_time DATETIME2(0) NOT NULL,
    reason NVARCHAR(250) NOT NULL,

    CONSTRAINT PK_Maintenance
        PRIMARY KEY (maintenance_id),

    CONSTRAINT FK_Maintenance_Court
        FOREIGN KEY (court_id)
        REFERENCES Court(court_id),

    CONSTRAINT FK_Maintenance_Employee
        FOREIGN KEY (employee_id)
        REFERENCES Employee(employee_id),

    CONSTRAINT CK_Maintenance_time_interval
        CHECK (start_time < end_time),

    CONSTRAINT CK_Maintenance_reason_not_empty
        CHECK (LEN(LTRIM(RTRIM(reason))) > 0)
);
GO