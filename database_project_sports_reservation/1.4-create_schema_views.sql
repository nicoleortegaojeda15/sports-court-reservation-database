/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 1.4-create_schema_views.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script creates views that simulate screens of the application. The project doesn't contain a graphical user interface.

    Created views:
    - vw_customer_list
    - vw_court_list
    - vw_reservation_list
    - vw_daily_schedule
    - vw_active_reservations
    - vw_pending_payments
    - vw_courts_under_maintenance
    - vw_available_courts

*/


-- Drop existing views if they already exist. This makes the script easier to run again during development.

IF OBJECT_ID('vw_available_courts', 'V') IS NOT NULL
    DROP VIEW vw_available_courts;
GO

IF OBJECT_ID('vw_courts_under_maintenance', 'V') IS NOT NULL
    DROP VIEW vw_courts_under_maintenance;
GO

IF OBJECT_ID('vw_pending_payments', 'V') IS NOT NULL
    DROP VIEW vw_pending_payments;
GO

IF OBJECT_ID('vw_active_reservations', 'V') IS NOT NULL
    DROP VIEW vw_active_reservations;
GO

IF OBJECT_ID('vw_daily_schedule', 'V') IS NOT NULL
    DROP VIEW vw_daily_schedule;
GO

IF OBJECT_ID('vw_reservation_list', 'V') IS NOT NULL
    DROP VIEW vw_reservation_list;
GO

IF OBJECT_ID('vw_court_list', 'V') IS NOT NULL
    DROP VIEW vw_court_list;
GO

IF OBJECT_ID('vw_customer_list', 'V') IS NOT NULL
    DROP VIEW vw_customer_list;
GO



-- View: vw_customer_list
-- Screen meaning: Displays customers together with basic information about their reservations.
-- This view simulates a customer list screen.

CREATE VIEW vw_customer_list
AS
SELECT
    c.customer_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone,
    c.registration_date,
    c.is_active,
    COUNT(r.reservation_id) AS reservation_count,
    ISNULL(SUM(CASE WHEN rs.status_name = 'Pending' THEN 1 ELSE 0 END),0) AS pending_reservations,
    ISNULL(SUM(CASE WHEN rs.status_name = 'Confirmed' THEN 1 ELSE 0 END),0) AS confirmed_reservations,
    ISNULL(SUM(CASE WHEN rs.status_name = 'Completed' THEN 1 ELSE 0 END),0) AS completed_reservations
FROM Customer c
JOIN Person p
    ON p.person_id = c.person_id
LEFT JOIN Reservation r
    ON r.customer_id = c.customer_id
LEFT JOIN ReservationStatus rs
    ON rs.status_id = r.status_id
GROUP BY
    c.customer_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone,
    c.registration_date,
    c.is_active;
GO



-- View: vw_court_list
-- Screen meaning: Displays all courts with their sport and current basic information.
-- This view simulates a court list screen.

CREATE VIEW vw_court_list
AS
SELECT
    c.court_id,
    c.court_name,
    s.sport_name,
    c.location,
    c.capacity,
    c.is_active,
    COUNT(r.reservation_id) AS total_reservations
FROM Court c
JOIN Sport s
    ON s.sport_id = c.sport_id
LEFT JOIN Reservation r
    ON r.court_id = c.court_id
GROUP BY
    c.court_id,
    c.court_name,
    s.sport_name,
    c.location,
    c.capacity,
    c.is_active;
GO



-- View: vw_reservation_list
-- Screen meaning: Displays reservations with customer, court, sport, status and payment data.
-- This view simulates the main reservation overview screen.

CREATE VIEW vw_reservation_list
AS
SELECT
    r.reservation_id,
    r.start_time,
    r.end_time,
    r.created_at,
    r.cancelled_at,
    r.total_price,
    rs.status_name,
    c.customer_id,
    p.first_name + ' ' + p.last_name AS customer_name,
    p.email AS customer_email,
    co.court_id,
    co.court_name,
    s.sport_name,
    pay.payment_id,
    pay.amount AS paid_amount,
    pay.payment_date,
    pay.payment_method
FROM Reservation r
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN Court co
    ON co.court_id = r.court_id
JOIN Sport s
    ON s.sport_id = co.sport_id
JOIN ReservationStatus rs
    ON rs.status_id = r.status_id
LEFT JOIN Payment pay
    ON pay.reservation_id = r.reservation_id;
GO



-- View: vw_daily_schedule
-- Screen meaning: Displays reservation schedule by day.
-- Here it shows all reservations with a reservation_date column.

CREATE VIEW vw_daily_schedule
AS
SELECT
    CAST(r.start_time AS DATE) AS reservation_date,
    r.start_time,
    r.end_time,
    co.court_name,
    s.sport_name,
    p.first_name + ' ' + p.last_name AS customer_name,
    rs.status_name,
    r.total_price
FROM Reservation r
JOIN Court co
    ON co.court_id = r.court_id
JOIN Sport s
    ON s.sport_id = co.sport_id
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN ReservationStatus rs
    ON rs.status_id = r.status_id;
GO



-- View: vw_active_reservations
-- Screen meaning: Displays only active reservations. Active means that the reservation status is Pending or Confirmed.

CREATE VIEW vw_active_reservations
AS
SELECT
    r.reservation_id,
    r.start_time,
    r.end_time,
    rs.status_name,
    c.customer_id,
    p.first_name + ' ' + p.last_name AS customer_name,
    co.court_id,
    co.court_name,
    s.sport_name,
    r.total_price
FROM Reservation r
JOIN ReservationStatus rs
    ON rs.status_id = r.status_id
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN Court co
    ON co.court_id = r.court_id
JOIN Sport s
    ON s.sport_id = co.sport_id
WHERE rs.status_name IN ('Pending', 'Confirmed');
GO



-- View: vw_pending_payments
-- Screen meaning: Displays reservations that are still waiting for payment. These are Pending reservations without a payment record.

CREATE VIEW vw_pending_payments
AS
SELECT
    r.reservation_id,
    r.start_time,
    r.end_time,
    c.customer_id,
    p.first_name + ' ' + p.last_name AS customer_name,
    p.email AS customer_email,
    co.court_name,
    s.sport_name,
    r.total_price
FROM Reservation r
JOIN ReservationStatus rs
    ON rs.status_id = r.status_id
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN Court co
    ON co.court_id = r.court_id
JOIN Sport s
    ON s.sport_id = co.sport_id
LEFT JOIN Payment pay
    ON pay.reservation_id = r.reservation_id
WHERE rs.status_name = 'Pending'
  AND pay.payment_id IS NULL;
GO



-- View: vw_courts_under_maintenance
-- Screen meaning: Displays courts with maintenance periods.
-- This view simulates a maintenance overview screen.

CREATE VIEW vw_courts_under_maintenance
AS
SELECT
    m.maintenance_id,
    m.start_time,
    m.end_time,
    co.court_id,
    co.court_name,
    s.sport_name,
    m.reason,
    e.employee_id,
    p.first_name + ' ' + p.last_name AS registered_by
FROM Maintenance m
JOIN Court co
    ON co.court_id = m.court_id
JOIN Sport s
    ON s.sport_id = co.sport_id
JOIN Employee e
    ON e.employee_id = m.employee_id
JOIN Person p
    ON p.person_id = e.person_id;
GO



-- View: vw_available_courts
-- Screen meaning: Displays courts that are normally available.
-- This view doesn't check availability for a selected time interval because a normal view can't accept parameters. Time availability is
-- checked by function fn_is_court_available and procedure usp_create_reservation.

-- The view shows active courts and their current tariff.

CREATE VIEW vw_available_courts
AS
SELECT
    co.court_id,
    co.court_name,
    s.sport_name,
    co.location,
    co.capacity,
    t.price_per_hour
FROM Court co
JOIN Sport s
    ON s.sport_id = co.sport_id
LEFT JOIN Tariff t
    ON t.sport_id = s.sport_id
   AND t.valid_from <= CAST(SYSDATETIME() AS DATE)
   AND (t.valid_to IS NULL OR t.valid_to > CAST(SYSDATETIME() AS DATE))
WHERE co.is_active = 1;
GO



-- Control query
-- This query lists created views from this script.

SELECT
    s.name AS schema_name,
    v.name AS view_name
FROM sys.views v
JOIN sys.schemas s
    ON v.schema_id = s.schema_id
WHERE s.name = 'u95695753'
  AND v.name IN (
        'vw_customer_list',
        'vw_court_list',
        'vw_reservation_list',
        'vw_daily_schedule',
        'vw_active_reservations',
        'vw_pending_payments',
        'vw_courts_under_maintenance',
        'vw_available_courts'
  )
ORDER BY v.name;
GO