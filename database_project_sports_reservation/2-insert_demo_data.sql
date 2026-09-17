/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 2-insert_demo_data.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script inserts demonstration data into the tables created by 1.0-create_schema_tables.sql.

    The inserted data is used to demonstrate the functionality of the database application, views, triggers, 
    procedures and functions in later scripts.

    The demo data contains:
    - reservation statuses
    - sports
    - employees
    - customers
    - courts
    - tariffs
    - reservations
    - payments
    - maintenance periods

*/


-- Reservation statuses: These records define the allowed states of a reservation.
-- They are referenced from the Reservation table.

INSERT INTO ReservationStatus
    (status_name)
VALUES
    ('Pending'),
    ('Confirmed'),
    ('Cancelled'),
    ('Completed');
GO



-- Sports: These records define sports available in the sports centre.
-- Each court belongs to one of these sports.

INSERT INTO Sport
    (sport_name, description)
VALUES
    ('Tennis', 'Outdoor and indoor tennis courts.'),
    ('Padel', 'Padel courts for doubles matches.'),
    ('Football', 'Small football fields for five-a-side football.'),
    ('Basketball', 'Basketball courts for training and matches.');
GO


-- Person: These records define personal common data.

INSERT INTO Person
    (first_name, last_name, email, phone)
VALUES
    ('John', 'Smith', 'john.smith@sportscentre.test', NULL),
    ('Anna', 'Brown', 'anna.brown@sportscentre.test', NULL),
    ('Peter', 'Wilson', 'peter.wilson@sportscentre.test', NULL),
    ('Michael', 'Johnson', 'michael.johnson@example.test', '+420111111111'),
    ('Laura', 'Garcia', 'laura.garcia@example.test', '+420222222222'),
    ('David', 'Miller', 'david.miller@example.test', '+420333333333'),
    ('Sofia', 'Martinez', 'sofia.martinez@example.test', '+420444444444'),
    ('Daniel', 'Lopez', 'daniel.lopez@example.test', '+420555555555'),
    ('Emma', 'Davis', 'emma.davis@example.test', '+420666666666');
GO


-- Employees: These records represent employees of the sports centre.
-- Employees can register payments and maintenance periods.

INSERT INTO Employee
    (person_id, role_name, is_active)
VALUES
(
    (SELECT person_id
     FROM Person
     WHERE email = 'john.smith@sportscentre.test'),
    'Receptionist',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'anna.brown@sportscentre.test'),
    'Manager',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'peter.wilson@sportscentre.test'),
    'Maintenance',
    1
);
GO


-- Customers: These records represent registered customers.
-- Email is unique and works as a candidate key.

INSERT INTO Customer
    (person_id, registration_date, is_active)
VALUES
(
    (SELECT person_id
     FROM Person
     WHERE email = 'michael.johnson@example.test'),
    '2026-01-10 09:00:00',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'laura.garcia@example.test'),
    '2026-01-12 10:30:00',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'david.miller@example.test'),
    '2026-02-01 15:15:00',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'sofia.martinez@example.test'),
    '2026-02-05 11:45:00',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'daniel.lopez@example.test'),
    '2026-02-20 08:20:00',
    1
),
(
    (SELECT person_id
     FROM Person
     WHERE email = 'emma.davis@example.test'),
    '2026-03-03 17:00:00',
    0
);
GO



-- Courts: These records represent sports courts.
-- The sport_id values are obtained by subqueries so that the script does not depend on concrete identity values.

INSERT INTO Court
    (sport_id, court_name, location, capacity, is_active)
VALUES
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Tennis'),
        'Tennis Court 1',
        'Outdoor area A',
        4,
        1
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Tennis'),
        'Tennis Court 2',
        'Indoor hall A',
        4,
        1
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Padel'),
        'Padel Court 1',
        'Indoor hall B',
        4,
        1
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Padel'),
        'Padel Court 2',
        'Indoor hall B',
        4,
        1
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Football'),
        'Football Field 1',
        'Outdoor area C',
        10,
        1
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Basketball'),
        'Basketball Court 1',
        'Indoor hall C',
        10,
        1
    );
GO



-- Tariffs: These records define prices per hour for each sport. 
-- The function for price calculation will use these tariffs later.

INSERT INTO Tariff
    (sport_id, price_per_hour, valid_from, valid_to)
VALUES
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Tennis'),
        300.00,
        '2026-01-01',
        NULL
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Padel'),
        400.00,
        '2026-01-01',
        NULL
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Football'),
        800.00,
        '2026-01-01',
        NULL
    ),
    (
        (SELECT sport_id FROM Sport WHERE sport_name = 'Basketball'),
        600.00,
        '2026-01-01',
        NULL
    );
GO



-- Reservations: These records represent already existing reservations.

-- Status meanings:
-- Pending   - reservation was created but not paid yet
-- Confirmed - reservation was paid and confirmed
-- Cancelled - reservation was cancelled
-- Completed - reservation already took place

-- The total_price values are inserted explicitly here for demo purposes.

INSERT INTO Reservation
    (customer_id, court_id, status_id, start_time, end_time, created_at, cancelled_at, total_price)
VALUES
    (
        (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email = 'michael.johnson@example.test'),
        (SELECT court_id FROM Court WHERE court_name = 'Tennis Court 1'),
        (SELECT status_id FROM ReservationStatus WHERE status_name = 'Confirmed'),
        '2026-06-20 10:00:00',
        '2026-06-20 12:00:00',
        '2026-06-18 09:00:00',
        NULL,
        600.00
    ),
    (
        (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email = 'laura.garcia@example.test'),
        (SELECT court_id FROM Court WHERE court_name = 'Padel Court 1'),
        (SELECT status_id FROM ReservationStatus WHERE status_name = 'Pending'),
        '2026-06-21 16:00:00',
        '2026-06-21 17:30:00',
        '2026-06-19 13:20:00',
        NULL,
        600.00
    ),
    (
        (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email = 'david.miller@example.test'),
        (SELECT court_id FROM Court WHERE court_name = 'Football Field 1'),
        (SELECT status_id FROM ReservationStatus WHERE status_name = 'Completed'),
        '2026-06-10 18:00:00',
        '2026-06-10 20:00:00',
        '2026-06-08 12:00:00',
        NULL,
        1600.00
    ),
    (
        (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email = 'sofia.martinez@example.test'),
        (SELECT court_id FROM Court WHERE court_name = 'Basketball Court 1'),
        (SELECT status_id FROM ReservationStatus WHERE status_name = 'Cancelled'),
        '2026-06-22 14:00:00',
        '2026-06-22 15:00:00',
        '2026-06-18 15:00:00',
        '2026-06-19 08:30:00',
        600.00
    ),
    (
        (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email = 'daniel.lopez@example.test'),
        (SELECT court_id FROM Court WHERE court_name = 'Tennis Court 2'),
        (SELECT status_id FROM ReservationStatus WHERE status_name = 'Pending'),
        '2026-06-25 09:00:00',
        '2026-06-25 10:00:00',
        '2026-06-20 10:00:00',
        NULL,
        300.00
    );
GO



-- Payments: These records represent payments for confirmed or completed reservations.
-- One reservation can have at most one payment.

INSERT INTO Payment
    (reservation_id, employee_id, amount, payment_date, payment_method)
VALUES
    (
        (
            SELECT reservation_id
            FROM Reservation
            WHERE customer_id = (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email='michael.johnson@example.test')
              AND court_id = (SELECT court_id FROM Court WHERE court_name = 'Tennis Court 1')
              AND start_time = '2026-06-20 10:00:00'
        ),
        (SELECT e.employee_id FROM Employee e JOIN Person p ON p.person_id = e.person_id
WHERE p.email='john.smith@sportscentre.test'),
        600.00,
        '2026-06-18 09:10:00',
        'Card'
    ),
    (
        (
            SELECT reservation_id
            FROM Reservation
            WHERE customer_id = (SELECT c.customer_id FROM Customer c JOIN Person p ON p.person_id = c.person_id
WHERE p.email= 'david.miller@example.test')
              AND court_id = (SELECT court_id FROM Court WHERE court_name = 'Football Field 1')
              AND start_time = '2026-06-10 18:00:00'
        ),
        (SELECT e.employee_id FROM Employee e JOIN Person p ON p.person_id = e.person_id
WHERE p.email= 'anna.brown@sportscentre.test'),
        1600.00,
        '2026-06-08 12:15:00',
        'BankTransfer'
    );
GO



-- Maintenance: These records represent periods when courts are unavailable.
-- They will be used later to test that reservations cannot be created during maintenance periods.

INSERT INTO Maintenance
    (court_id, employee_id, start_time, end_time, reason)
VALUES
    (
        (SELECT court_id FROM Court WHERE court_name = 'Padel Court 2'),
        (SELECT e.employee_id FROM Employee e JOIN Person p ON p.person_id=e.person_id
WHERE p.email='peter.wilson@sportscentre.test'),
        '2026-06-23 08:00:00',
        '2026-06-23 12:00:00',
        'Regular surface maintenance'
    ),
    (
        (SELECT court_id FROM Court WHERE court_name = 'Tennis Court 2'),
        (SELECT e.employee_id FROM Employee e JOIN Person p ON p.person_id=e.person_id
WHERE p.email='peter.wilson@sportscentre.test'),
        '2026-06-26 09:00:00',
        '2026-06-26 11:00:00',
        'Net replacement'
    );
GO



-- Control selects: 
-- These select statements are not necessary for the data insertion itself.
-- They are included to show the inserted demo data after the script execution.

SELECT * FROM Person;
SELECT * FROM ReservationStatus;
SELECT * FROM Sport;
SELECT * FROM Employee;
SELECT * FROM Customer;
SELECT * FROM Court;
SELECT * FROM Tariff;
SELECT * FROM Reservation;
SELECT * FROM Payment;
SELECT * FROM Maintenance;
GO