/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 3-drop_schema.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script drops the whole content of the database application.

    It removes only objects belonging to the Sports Court Reservation System:
    - views
    - stored procedures
    - functions
    - triggers
    - indexes
    - tables


    Drop order:
    1. Views are dropped first because they depend on tables.
    2. Procedures and functions are dropped before tables.
    3. Triggers are dropped before tables.
    4. Non-constraint indexes are dropped before tables.
    5. Tables are dropped at the end in an order respecting foreign keys.

*/


-- Drop views

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



-- Drop stored procedures

IF OBJECT_ID('usp_create_maintenance', 'P') IS NOT NULL
    DROP PROCEDURE usp_create_maintenance;
GO

IF OBJECT_ID('usp_register_payment', 'P') IS NOT NULL
    DROP PROCEDURE usp_register_payment;
GO

IF OBJECT_ID('usp_complete_reservation', 'P') IS NOT NULL
    DROP PROCEDURE usp_complete_reservation;
GO

IF OBJECT_ID('usp_cancel_reservation', 'P') IS NOT NULL
    DROP PROCEDURE usp_cancel_reservation;
GO

IF OBJECT_ID('usp_create_reservation', 'P') IS NOT NULL
    DROP PROCEDURE usp_create_reservation;
GO

IF OBJECT_ID('usp_delete_customer', 'P') IS NOT NULL
    DROP PROCEDURE usp_delete_customer;
GO

IF OBJECT_ID('usp_update_customer', 'P') IS NOT NULL
    DROP PROCEDURE usp_update_customer;
GO

IF OBJECT_ID('usp_create_customer', 'P') IS NOT NULL
    DROP PROCEDURE usp_create_customer;
GO



-- Drop functions

IF OBJECT_ID('fn_is_court_available', 'FN') IS NOT NULL
    DROP FUNCTION fn_is_court_available;
GO

IF OBJECT_ID('fn_calculate_reservation_price', 'FN') IS NOT NULL
    DROP FUNCTION fn_calculate_reservation_price;
GO



-- Drop triggers
-- Triggers are dropped explicitly before dropping the tables.

IF OBJECT_ID('trg_payment_confirm_reservation', 'TR') IS NOT NULL
    DROP TRIGGER trg_payment_confirm_reservation;
GO

IF OBJECT_ID('trg_maintenance_no_active_reservation', 'TR') IS NOT NULL
    DROP TRIGGER trg_maintenance_no_active_reservation;
GO

IF OBJECT_ID('trg_reservation_no_maintenance', 'TR') IS NOT NULL
    DROP TRIGGER trg_reservation_no_maintenance;
GO

IF OBJECT_ID('trg_reservation_no_overlap', 'TR') IS NOT NULL
    DROP TRIGGER trg_reservation_no_overlap;
GO



-- Drop non-constraint indexes
-- Primary key and unique indexes are dropped automatically with their tables.
-- Here we drop only indexes created manually in script 1.2.

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Court_sport_id'
      AND object_id = OBJECT_ID('Court')
)
    DROP INDEX IX_Court_sport_id ON Court;
GO


IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Tariff_sport_validity'
      AND object_id = OBJECT_ID('Tariff')
)
    DROP INDEX IX_Tariff_sport_validity ON Tariff;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_customer_id'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_customer_id ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_court_id'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_court_id ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_status_id'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_status_id ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_court_time'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_court_time ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_start_time'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_start_time ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Reservation_status_time'
      AND object_id = OBJECT_ID('Reservation')
)
    DROP INDEX IX_Reservation_status_time ON Reservation;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Payment_employee_id'
      AND object_id = OBJECT_ID('Payment')
)
    DROP INDEX IX_Payment_employee_id ON Payment;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Payment_payment_date'
      AND object_id = OBJECT_ID('Payment')
)
    DROP INDEX IX_Payment_payment_date ON Payment;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Maintenance_court_id'
      AND object_id = OBJECT_ID('Maintenance')
)
    DROP INDEX IX_Maintenance_court_id ON Maintenance;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Maintenance_employee_id'
      AND object_id = OBJECT_ID('Maintenance')
)
    DROP INDEX IX_Maintenance_employee_id ON Maintenance;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Maintenance_court_time'
      AND object_id = OBJECT_ID('Maintenance')
)
    DROP INDEX IX_Maintenance_court_time ON Maintenance;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Maintenance_start_time'
      AND object_id = OBJECT_ID('Maintenance')
)
    DROP INDEX IX_Maintenance_start_time ON Maintenance;
GO



-- Drop tables
-- Tables are dropped in an order respecting foreign key dependencies.

IF OBJECT_ID('Payment', 'U') IS NOT NULL
    DROP TABLE Payment;
GO

IF OBJECT_ID('Maintenance', 'U') IS NOT NULL
    DROP TABLE Maintenance;
GO

IF OBJECT_ID('Reservation', 'U') IS NOT NULL
    DROP TABLE Reservation;
GO

IF OBJECT_ID('Tariff', 'U') IS NOT NULL
    DROP TABLE Tariff;
GO

IF OBJECT_ID('Court', 'U') IS NOT NULL
    DROP TABLE Court;
GO

IF OBJECT_ID('ReservationStatus', 'U') IS NOT NULL
    DROP TABLE ReservationStatus;
GO

IF OBJECT_ID('Customer', 'U') IS NOT NULL
    DROP TABLE Customer;
GO

IF OBJECT_ID('Employee', 'U') IS NOT NULL
    DROP TABLE Employee;
GO

IF OBJECT_ID('Person', 'U') IS NOT NULL
    DROP TABLE Person;
GO

IF OBJECT_ID('Sport', 'U') IS NOT NULL
    DROP TABLE Sport;
GO



-- Control query
-- This query shows remaining project objects.
-- Expected result: No rows should be returned.

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE s.name = 'u95695753'
  AND o.name IN (
        'Customer',
        'Sport',
        'Employee',
        'Person',
        'ReservationStatus',
        'Court',
        'Tariff',
        'Reservation',
        'Payment',
        'Maintenance',
        'vw_customer_list',
        'vw_court_list',
        'vw_reservation_list',
        'vw_daily_schedule',
        'vw_active_reservations',
        'vw_pending_payments',
        'vw_courts_under_maintenance',
        'vw_available_courts',
        'fn_calculate_reservation_price',
        'fn_is_court_available',
        'usp_create_customer',
        'usp_update_customer',
        'usp_delete_customer',
        'usp_create_reservation',
        'usp_cancel_reservation',
        'usp_complete_reservation',
        'usp_register_payment',
        'usp_create_maintenance',
        'trg_reservation_no_overlap',
        'trg_reservation_no_maintenance',
        'trg_maintenance_no_active_reservation',
        'trg_payment_confirm_reservation'
  )
ORDER BY o.type_desc, o.name;
GO