/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 1.3-create_schema_procedures_functions.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script creates the procedural application layer of the database application.
    The application layer is implemented using T-SQL functions and stored procedures.


    Created functions:
    - fn_calculate_reservation_price
    - fn_is_court_available

    Created procedures:
    - usp_create_customer
    - usp_update_customer
    - usp_delete_customer
    - usp_create_reservation
    - usp_cancel_reservation
    - usp_complete_reservation
    - usp_register_payment
    - usp_create_maintenance

*/



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

IF OBJECT_ID('fn_is_court_available', 'FN') IS NOT NULL
    DROP FUNCTION fn_is_court_available;
GO

IF OBJECT_ID('fn_calculate_reservation_price', 'FN') IS NOT NULL
    DROP FUNCTION fn_calculate_reservation_price;
GO


-- Function: fn_calculate_reservation_price
-- Meaning: Calculates the total price of a reservation.
-- Parameters:
-- @court_id    - selected court
-- @start_time  - reservation start date and time
-- @end_time    - reservation end date and time

-- Return value: Total reservation price as DECIMAL(10,2).
-- Returns NULL if the input is invalid or if no valid tariff exists.

-- Business logic: The function finds the sport of the court, then finds the tariff valid
-- for the reservation date, and multiplies price per hour by reservation length.

CREATE FUNCTION  fn_calculate_reservation_price
(
    @court_id INT,
    @start_time DATETIME2(0),
    @end_time DATETIME2(0)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @sport_id INT;
    DECLARE @price_per_hour DECIMAL(10,2);
    DECLARE @minutes INT;
    DECLARE @result DECIMAL(10,2);

    IF @court_id IS NULL OR @start_time IS NULL OR @end_time IS NULL
        RETURN NULL;

    IF @start_time >= @end_time
        RETURN NULL;

    SELECT @sport_id = c.sport_id
    FROM Court c
    WHERE c.court_id = @court_id;

    IF @sport_id IS NULL
        RETURN NULL;

    SELECT TOP 1
        @price_per_hour = t.price_per_hour
    FROM Tariff t
    WHERE t.sport_id = @sport_id
      AND t.valid_from <= CAST(@start_time AS DATE)
      AND (t.valid_to IS NULL OR t.valid_to > CAST(@start_time AS DATE))
    ORDER BY t.valid_from DESC;

    IF @price_per_hour IS NULL
        RETURN NULL;

    SET @minutes = DATEDIFF(MINUTE, @start_time, @end_time);
    SET @result = ROUND((@minutes / 60.0) * @price_per_hour, 2);

    RETURN @result;
END;
GO



-- Function: fn_is_court_available
-- Meaning: Checks whether a court is available in a selected time interval.
-- Parameters:
-- @court_id                - selected court
-- @start_time              - requested start date and time
-- @end_time                - requested end date and time
-- @ignored_reservation_id  - reservation ignored during the check.

-- Return value:  1=court is available / 0=court is not available

-- Business logic: A court is not available if it does not exist, it is inactive, the interval is invalid, it overlaps with 
-- a Pending or Confirmed reservation, or it overlaps with a maintenance period.

CREATE FUNCTION  fn_is_court_available
(
    @court_id INT,
    @start_time DATETIME2(0),
    @end_time DATETIME2(0),
    @ignored_reservation_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 1;

    IF @court_id IS NULL OR @start_time IS NULL OR @end_time IS NULL
        RETURN 0;

    IF @start_time >= @end_time
        RETURN 0;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Court c
        WHERE c.court_id = @court_id
          AND c.is_active = 1
    )
        RETURN 0;

    IF EXISTS
    (
        SELECT 1
        FROM Reservation r
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE r.court_id = @court_id
          AND s.status_name IN ('Pending', 'Confirmed')
          AND (@ignored_reservation_id IS NULL OR r.reservation_id <> @ignored_reservation_id)
          AND @start_time < r.end_time
          AND @end_time > r.start_time
    )
        SET @result = 0;

    IF EXISTS
    (
        SELECT 1
        FROM Maintenance m
        WHERE m.court_id = @court_id
          AND @start_time < m.end_time
          AND @end_time > m.start_time
    )
        SET @result = 0;

    RETURN @result;
END;
GO






-- Procedure: usp_create_customer
-- Meaning: Creates a new customer.
-- Parameters:
-- @first_name - customer's first name
-- @last_name  - customer's last name
-- @email      - customer's unique email address
-- @phone      - customer's phone number, optional

-- Validation: first name, last name and email must not be empty and email must be unique, enforced by AK_Person_email
-- Result: Inserts a new customer and returns the inserted row.

CREATE PROCEDURE usp_create_customer
    @first_name NVARCHAR(50),
    @last_name NVARCHAR(50),
    @email NVARCHAR(100),
    @phone NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @first_name IS NULL OR LEN(LTRIM(RTRIM(@first_name))) = 0
            THROW 50201, 'First name must not be empty.', 1;

        IF @last_name IS NULL OR LEN(LTRIM(RTRIM(@last_name))) = 0
            THROW 50202, 'Last name must not be empty.', 1;

        IF @email IS NULL OR LEN(LTRIM(RTRIM(@email))) = 0
            THROW 50203, 'Email must not be empty.', 1;

        -- Insert personal information
        INSERT INTO Person
            (first_name, last_name, email, phone)
        VALUES
            (
                LTRIM(RTRIM(@first_name)),
                LTRIM(RTRIM(@last_name)),
                LTRIM(RTRIM(@email)),
                @phone
            );

        DECLARE @person_id INT = SCOPE_IDENTITY();

        -- Insert customer
        INSERT INTO Customer
            (person_id)
        VALUES
            (@person_id);

        DECLARE @customer_id INT = SCOPE_IDENTITY();

        -- Return created customer
        SELECT
            c.customer_id,
            p.first_name,
            p.last_name,
            p.email,
            p.phone,
            c.registration_date,
            c.is_active
        FROM Customer c
        JOIN Person p
            ON p.person_id = c.person_id
        WHERE c.customer_id = @customer_id;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO



-- Procedure: usp_update_customer
-- Meaning: Updates customer data.
-- Parameters:
-- @customer_id - customer to update
-- @first_name  - new first name
-- @last_name   - new last name
-- @email       - new email address
-- @phone       - new phone number
-- @is_active   - new activity flag

-- Validation: customer must exist, first name, last name and email must not be empty and email must remain
-- unique, enforced by AK_Person_email.

CREATE PROCEDURE usp_update_customer
    @customer_id INT,
    @first_name NVARCHAR(50),
    @last_name NVARCHAR(50),
    @email NVARCHAR(100),
    @phone NVARCHAR(30) = NULL,
    @is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @customer_id IS NULL
            THROW 50204, 'Customer id must be specified.', 1;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
            THROW 50205, 'Customer does not exist.', 1;

        IF @first_name IS NULL OR LEN(LTRIM(RTRIM(@first_name))) = 0
            THROW 50206, 'First name must not be empty.', 1;

        IF @last_name IS NULL OR LEN(LTRIM(RTRIM(@last_name))) = 0
            THROW 50207, 'Last name must not be empty.', 1;

        IF @email IS NULL OR LEN(LTRIM(RTRIM(@email))) = 0
            THROW 50208, 'Email must not be empty.', 1;

        -- Update personal data
        UPDATE p
        SET
            first_name = LTRIM(RTRIM(@first_name)),
            last_name = LTRIM(RTRIM(@last_name)),
            email = LTRIM(RTRIM(@email)),
            phone = @phone
        FROM Person p
        JOIN Customer c
            ON c.person_id = p.person_id
        WHERE c.customer_id = @customer_id;

        -- Update customer data
        UPDATE Customer
        SET
            is_active = @is_active
        WHERE customer_id = @customer_id;

        -- Return updated customer
        SELECT
            c.customer_id,
            p.first_name,
            p.last_name,
            p.email,
            p.phone,
            c.registration_date,
            c.is_active
        FROM Customer c
        JOIN Person p
            ON p.person_id = c.person_id
        WHERE c.customer_id = @customer_id;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO



-- Procedure: usp_delete_customer
-- Meaning: Deletes a customer only if the customer has no reservations.
-- Parameters:
-- @customer_id - customer to delete

-- Business rule:
-- A customer with reservation history is not physically deleted because reservations
-- must keep their customer reference.
-- If the customer is deleted and the related person is not an employee,
-- the corresponding Person record is deleted as well.

CREATE PROCEDURE usp_delete_customer
    @customer_id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @person_id INT;

        IF @customer_id IS NULL
            THROW 50209, 'Customer id must be specified.', 1;

        SELECT @person_id = person_id
        FROM Customer WITH (UPDLOCK, HOLDLOCK)
        WHERE customer_id = @customer_id;

        IF @person_id IS NULL
            THROW 50210, 'Customer does not exist.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Reservation
            WHERE customer_id = @customer_id
        )
            THROW 50211, 'Customer cannot be deleted because reservations exist.', 1;

        DELETE FROM Customer
        WHERE customer_id = @customer_id;

        -- Delete the Person record only if the person is not also an employee
        IF NOT EXISTS
        (
            SELECT 1
            FROM Employee
            WHERE person_id = @person_id
        )
        BEGIN
            DELETE FROM Person
            WHERE person_id = @person_id;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO


-- Procedure: usp_create_reservation
-- Meaning: Creates a new reservation for a customer and a court.
-- Parameters:
-- @customer_id - customer creating the reservation
-- @court_id    - selected court
-- @start_time  - reservation start date and time
-- @end_time    - reservation end date and time

-- Business logic: customer must exist and be active, court must exist and be active, time interval must be valid, court must 
-- not be under maintenance, court must not have another active overlapping reservation, total price is calculated automatically 
-- by fn_calculate_reservation_price and new reservation is created with status Pending

-- Concurrency: This procedure uses serializable isolation level and UPDLOCK/HOLDLOCK when checking reservations and 
-- maintenance periods. This prevents two parallel transactions from creating overlapping reservations for the same court.

CREATE PROCEDURE usp_create_reservation
    @customer_id INT,
    @court_id INT,
    @start_time DATETIME2(0),
    @end_time DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pending_status_id INT;
    DECLARE @total_price DECIMAL(10,2);

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        IF @customer_id IS NULL
            THROW 50212, 'Customer id must be specified.', 1;

        IF @court_id IS NULL
            THROW 50213, 'Court id must be specified.', 1;

        IF @start_time IS NULL OR @end_time IS NULL
            THROW 50214, 'Reservation start time and end time must be specified.', 1;

        IF @start_time >= @end_time
            THROW 50215, 'Reservation start time must be before reservation end time.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Customer WITH (UPDLOCK, HOLDLOCK)
            WHERE customer_id = @customer_id
              AND is_active = 1
        )
            THROW 50216, 'Active customer does not exist.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Court WITH (UPDLOCK, HOLDLOCK)
            WHERE court_id = @court_id
              AND is_active = 1
        )
            THROW 50217, 'Active court does not exist.', 1;

        SELECT @pending_status_id = status_id
        FROM ReservationStatus
        WHERE status_name = 'Pending';

        IF @pending_status_id IS NULL
            THROW 50218, 'Reservation status Pending does not exist.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Reservation r WITH (UPDLOCK, HOLDLOCK)
            JOIN ReservationStatus s
                ON s.status_id = r.status_id
            WHERE r.court_id = @court_id
              AND s.status_name IN ('Pending', 'Confirmed')
              AND @start_time < r.end_time
              AND @end_time > r.start_time
        )
            THROW 50219, 'The court already has an active reservation in the selected time interval.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Maintenance m WITH (UPDLOCK, HOLDLOCK)
            WHERE m.court_id = @court_id
              AND @start_time < m.end_time
              AND @end_time > m.start_time
        )
            THROW 50220, 'The court is under maintenance in the selected time interval.', 1;

        SET @total_price = fn_calculate_reservation_price(@court_id, @start_time, @end_time);

        IF @total_price IS NULL
            THROW 50221, 'Reservation price could not be calculated.', 1;

        INSERT INTO Reservation
            (customer_id, court_id, status_id, start_time, end_time, total_price)
        VALUES
            (@customer_id, @court_id, @pending_status_id, @start_time, @end_time, @total_price);

        COMMIT TRANSACTION;

        SELECT *
        FROM Reservation
        WHERE reservation_id = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO



-- Procedure: usp_cancel_reservation
-- Meaning: Cancels an existing reservation.
-- Parameters:
-- @reservation_id - reservation to cancel

-- Business rule: Only Pending or Confirmed reservations can be cancelled. Completed reservations cannot be cancelled.
-- Already Cancelled reservations can't be cancelled again.

CREATE PROCEDURE usp_cancel_reservation
    @reservation_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @current_status NVARCHAR(30);
    DECLARE @cancelled_status_id INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @reservation_id IS NULL
            THROW 50222, 'Reservation id must be specified.', 1;

        SELECT @current_status = s.status_name
        FROM Reservation r WITH (UPDLOCK, HOLDLOCK)
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE r.reservation_id = @reservation_id;

        IF @current_status IS NULL
            THROW 50223, 'Reservation does not exist.', 1;

        IF @current_status = 'Cancelled'
            THROW 50224, 'Reservation is already cancelled.', 1;

        IF @current_status = 'Completed'
            THROW 50225, 'Completed reservation cannot be cancelled.', 1;

        SELECT @cancelled_status_id = status_id
        FROM ReservationStatus
        WHERE status_name = 'Cancelled';

        IF @cancelled_status_id IS NULL
            THROW 50226, 'Reservation status Cancelled does not exist.', 1;

        UPDATE Reservation
        SET status_id = @cancelled_status_id,
            cancelled_at = SYSDATETIME()
        WHERE reservation_id = @reservation_id;

        COMMIT TRANSACTION;

        SELECT *
        FROM Reservation
        WHERE reservation_id = @reservation_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO



-- Procedure: usp_complete_reservation
-- Meaning: Marks a reservation as completed.
-- Parameters:
-- @reservation_id - reservation to complete

-- Business rule: Only Confirmed reservations can be completed. Pending reservations must be paid first.

CREATE PROCEDURE usp_complete_reservation
    @reservation_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @current_status NVARCHAR(30);
    DECLARE @completed_status_id INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @reservation_id IS NULL
            THROW 50227, 'Reservation id must be specified.', 1;

        SELECT @current_status = s.status_name
        FROM Reservation r WITH (UPDLOCK, HOLDLOCK)
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE r.reservation_id = @reservation_id;

        IF @current_status IS NULL
            THROW 50228, 'Reservation does not exist.', 1;

        IF @current_status <> 'Confirmed'
            THROW 50229, 'Only confirmed reservations can be completed.', 1;

        SELECT @completed_status_id = status_id
        FROM ReservationStatus
        WHERE status_name = 'Completed';

        IF @completed_status_id IS NULL
            THROW 50230, 'Reservation status Completed does not exist.', 1;

        UPDATE Reservation
        SET status_id = @completed_status_id
        WHERE reservation_id = @reservation_id;

        COMMIT TRANSACTION;

        SELECT *
        FROM Reservation
        WHERE reservation_id = @reservation_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO



-- Procedure: usp_register_payment
--  Meaning: Registers a payment for a reservation.
-- Parameters:
-- @reservation_id  - reservation being paid
-- @employee_id     - employee who registers the payment
-- @amount          - paid amount
-- @payment_method  - Cash, Card or BankTransfer

-- Business logic: reservation must exist, employee must exist and be active, payment must not already exist for the reservation,
-- amount must be positive, amount must be equal to reservation total price and payment method must be valid

-- Trigger interaction: After inserting a payment, trigger trg_payment_confirm_reservation automatically
-- changes Pending reservation status to Confirmed.

CREATE PROCEDURE usp_register_payment
    @reservation_id INT,
    @employee_id INT,
    @amount DECIMAL(10,2),
    @payment_method NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @reservation_status NVARCHAR(30);
    DECLARE @reservation_price DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @reservation_id IS NULL
            THROW 50231, 'Reservation id must be specified.', 1;

        IF @employee_id IS NULL
            THROW 50232, 'Employee id must be specified.', 1;

        IF @amount IS NULL OR @amount <= 0
            THROW 50233, 'Payment amount must be positive.', 1;

        IF @payment_method NOT IN ('Cash', 'Card', 'BankTransfer')
            THROW 50234, 'Invalid payment method.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employee WITH (UPDLOCK, HOLDLOCK)
            WHERE employee_id = @employee_id
              AND is_active = 1
        )
            THROW 50235, 'Active employee does not exist.', 1;

        SELECT
            @reservation_status = s.status_name,
            @reservation_price = r.total_price
        FROM Reservation r WITH (UPDLOCK, HOLDLOCK)
        JOIN ReservationStatus s
            ON s.status_id = r.status_id
        WHERE r.reservation_id = @reservation_id;

        IF @reservation_status IS NULL
            THROW 50236, 'Reservation does not exist.', 1;

        IF @reservation_status IN ('Cancelled', 'Completed')
            THROW 50237, 'Payment cannot be registered for a cancelled or completed reservation.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Payment WITH (UPDLOCK, HOLDLOCK)
            WHERE reservation_id = @reservation_id
        )
            THROW 50238, 'Payment already exists for this reservation.', 1;

        IF @amount <> @reservation_price
            THROW 50239, 'Payment amount must be equal to the reservation total price.', 1;

        INSERT INTO Payment
            (reservation_id, employee_id, amount, payment_method)
        VALUES
            (@reservation_id, @employee_id, @amount, @payment_method);

        COMMIT TRANSACTION;

        SELECT *
        FROM Payment
        WHERE payment_id = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO



-- Procedure: usp_create_maintenance
-- Meaning: Creates a maintenance period for a court.
-- Parameters:
-- @court_id     - court under maintenance
-- @employee_id  - employee who registers maintenance
-- @start_time   - maintenance start date and time
-- @end_time     - maintenance end date and time
-- @reason       - reason of maintenance

-- Business logic: court must exist, employee must exist and be active, time interval must be valid, reason must not be empty,
-- maintenance must not overlap with an active reservation and maintenance should not overlap with another maintenance period

-- Trigger interaction: Trigger trg_maintenance_no_active_reservation also checks that maintenance does not conflict with active reservations.

CREATE PROCEDURE usp_create_maintenance
    @court_id INT,
    @employee_id INT,
    @start_time DATETIME2(0),
    @end_time DATETIME2(0),
    @reason NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        IF @court_id IS NULL
            THROW 50240, 'Court id must be specified.', 1;

        IF @employee_id IS NULL
            THROW 50241, 'Employee id must be specified.', 1;

        IF @start_time IS NULL OR @end_time IS NULL
            THROW 50242, 'Maintenance start time and end time must be specified.', 1;

        IF @start_time >= @end_time
            THROW 50243, 'Maintenance start time must be before maintenance end time.', 1;

        IF @reason IS NULL OR LEN(LTRIM(RTRIM(@reason))) = 0
            THROW 50244, 'Maintenance reason must not be empty.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Court WITH (UPDLOCK, HOLDLOCK)
            WHERE court_id = @court_id
        )
            THROW 50245, 'Court does not exist.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employee WITH (UPDLOCK, HOLDLOCK)
            WHERE employee_id = @employee_id
              AND is_active = 1
        )
            THROW 50246, 'Active employee does not exist.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Reservation r WITH (UPDLOCK, HOLDLOCK)
            JOIN ReservationStatus s
                ON s.status_id = r.status_id
            WHERE r.court_id = @court_id
              AND s.status_name IN ('Pending', 'Confirmed')
              AND @start_time < r.end_time
              AND @end_time > r.start_time
        )
            THROW 50247, 'Maintenance period conflicts with an active reservation.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Maintenance m WITH (UPDLOCK, HOLDLOCK)
            WHERE m.court_id = @court_id
              AND @start_time < m.end_time
              AND @end_time > m.start_time
        )
            THROW 50248, 'Maintenance period overlaps with another maintenance period.', 1;

        INSERT INTO Maintenance
            (court_id, employee_id, start_time, end_time, reason)
        VALUES
            (@court_id, @employee_id, @start_time, @end_time, LTRIM(RTRIM(@reason)));

        COMMIT TRANSACTION;

        SELECT *
        FROM Maintenance
        WHERE maintenance_id = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO



-- Control query
-- This query lists created procedures and functions from this script.
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE s.name = 'u95695753'
  AND o.name IN (
        'fn_calculate_reservation_price',
        'fn_is_court_available',
        'usp_create_customer',
        'usp_update_customer',
        'usp_delete_customer',
        'usp_create_reservation',
        'usp_cancel_reservation',
        'usp_complete_reservation',
        'usp_register_payment',
        'usp_create_maintenance'
  )
ORDER BY o.type_desc, o.name;
GO