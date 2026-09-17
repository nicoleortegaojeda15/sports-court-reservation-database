/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 1.1-create_schema_triggers.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script creates triggers for rules that cannot be completely checked
    by simple constraints.

    Implemented business rules:
    - A court cannot have two active reservations with overlapping time intervals.
    - A court cannot be reserved during a maintenance period.
    - A maintenance period cannot be created if it conflicts with an active reservation.
    - When a payment is registered, the related reservation is automatically confirmed.

*/


-- Trigger: trg_reservation_no_overlap
-- Table: Reservation
-- Meaning: This trigger prevents overlapping active reservations for the same court.

-- Why this is implemented as a trigger:
-- A CHECK constraint can validate values only in the current row.
-- It cannot compare the inserted or updated reservation with other reservations already stored in the table.

-- Active reservation statuses: Pending / Confirmed

-- Cancelled reservations are ignored because they do not block the court.
-- Completed reservations are also ignored for future reservations.

CREATE TRIGGER trg_reservation_no_overlap
ON Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN Reservation r
            ON r.court_id = i.court_id
           AND r.reservation_id <> i.reservation_id
           AND i.start_time < r.end_time
           AND i.end_time > r.start_time
        JOIN ReservationStatus si
            ON si.status_id = i.status_id
        JOIN ReservationStatus sr
            ON sr.status_id = r.status_id
        WHERE si.status_name IN ('Pending', 'Confirmed')
          AND sr.status_name IN ('Pending', 'Confirmed')
    )
    BEGIN
        THROW 50101, 'The court already has an active reservation in the selected time interval.', 1;
    END;
END;
GO



-- Trigger: trg_reservation_no_maintenance
-- Table: Reservation
-- Meaning: This trigger prevents creating or updating an active reservation during a maintenance period of the same court.

-- Why this is implemented as a trigger:
-- A CHECK constraint cannot compare a reservation interval with maintenance intervals stored in another table.

-- Active reservation statuses: Pending / Confirmed

-- Cancelled and completed reservations are ignored.

CREATE TRIGGER trg_reservation_no_maintenance
ON Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN ReservationStatus s
            ON s.status_id = i.status_id
        JOIN Maintenance m
            ON m.court_id = i.court_id
           AND i.start_time < m.end_time
           AND i.end_time > m.start_time
        WHERE s.status_name IN ('Pending', 'Confirmed')
    )
    BEGIN
        THROW 50102, 'The court is under maintenance in the selected time interval.', 1;
    END;
END;
GO



-- Trigger: trg_maintenance_no_active_reservation
-- Table: Maintenance
-- Meaning: This trigger prevents creating or updating a maintenance period that overlaps with an active reservation of the same court.

-- Why this is implemented as a trigger:
-- A CHECK constraint cannot compare a maintenance interval with reservations stored in another table.

-- Active reservation statuses: Pending / Confirmed

-- Cancelled and completed reservations are ignored.

CREATE TRIGGER trg_maintenance_no_active_reservation
ON Maintenance
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN Reservation r
            ON r.court_id = i.court_id
           AND i.start_time < r.end_time
           AND i.end_time > r.start_time
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE s.status_name IN ('Pending', 'Confirmed')
    )
    BEGIN
        THROW 50103, 'The maintenance period conflicts with an active reservation.', 1;
    END;
END;
GO



-- Trigger: trg_payment_confirm_reservation
-- Table: Payment
-- Meaning: When a payment is inserted, the related reservation is automatically changed to status Confirmed.

-- Why this is implemented as a trigger:
-- The payment represents a business event. After the payment exists, the system should keep the reservation status consistent automatically.

-- This trigger does not confirm cancelled or completed reservations.
-- If a payment is inserted for a cancelled reservation, an error is raised.
-- The UNIQUE constraint AK_Payment_reservation_id already prevents two payments for the same reservation.

CREATE TRIGGER trg_payment_confirm_reservation
ON Payment
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN Reservation r
            ON r.reservation_id = i.reservation_id
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE s.status_name = 'Cancelled'
    )
    BEGIN
        THROW 50104, 'Payment cannot be registered for a cancelled or completed reservation.', 1;
    END;


    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN Reservation r
            ON r.reservation_id = i.reservation_id
        WHERE i.amount <> r.total_price
    )
    BEGIN
        THROW 50105, 'Payment amount must be equal to the reservation total price.', 1;
    END;


    UPDATE r
    SET r.status_id =
        (
            SELECT status_id
            FROM ReservationStatus
            WHERE status_name = 'Confirmed'
        )
    FROM Reservation r
    JOIN inserted i
        ON i.reservation_id = r.reservation_id
    JOIN ReservationStatus s
        ON s.status_id = r.status_id
    WHERE s.status_name = 'Pending';
END;
GO