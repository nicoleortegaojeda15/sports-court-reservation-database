/*
    Author: Nicole María Ortega Ojeda
    Academic year: 2025/2026
    Database system: Microsoft SQL Server
    Script: 4-test_script.sql

    Topic:
    Sports Court Reservation System

    Meaning of this script:
    This script demonstrates the functionality of the database application.

    It tests:
    - views simulating application screens
    - scalar functions
    - public stored procedures
    - triggers
    - constraints and expected errors
    - transactions and locking logic used in reservation creation

*/


-- Cleanup of data possibly created by previous test executions.

DELETE FROM Payment
WHERE reservation_id IN
(
    SELECT reservation_id
    FROM Reservation
    WHERE customer_id IN
    (
        SELECT c.customer_id
        FROM Customer c
        JOIN Person p
            ON p.person_id = c.person_id
        WHERE p.email IN
        (
            'robert.taylor@example.test',
            'robert.taylor.updated@example.test',
            'temporary.customer@example.test'
        )
    )
);

DELETE FROM Reservation
WHERE customer_id IN
(
    SELECT c.customer_id
    FROM Customer c
    JOIN Person p
        ON p.person_id = c.person_id
    WHERE p.email IN
    (
        'robert.taylor@example.test',
        'robert.taylor.updated@example.test',
        'temporary.customer@example.test'
    )
);

DELETE FROM Maintenance
WHERE reason = 'Goal repair';

DELETE FROM Customer
WHERE person_id IN
(
    SELECT person_id
    FROM Person
    WHERE email IN
    (
        'robert.taylor@example.test',
        'robert.taylor.updated@example.test',
        'temporary.customer@example.test'
    )
);

DELETE FROM Person
WHERE email IN
(
    'robert.taylor@example.test',
    'robert.taylor.updated@example.test',
    'temporary.customer@example.test'
);
GO


-- TEST 1: Show customers before changes.

PRINT 'TEST 1: Show all customers before changes';

SELECT *
FROM vw_customer_list;
GO


-- TEST 2: Show all courts.

PRINT 'TEST 2: Show all courts';

SELECT *
FROM vw_court_list;
GO


-- TEST 3: Show all reservations.

PRINT 'TEST 3: Show all reservations';

SELECT *
FROM vw_reservation_list
ORDER BY reservation_id;
GO


-- TEST 4: Test function fn_calculate_reservation_price. Tennis price is 300 per hour. For 2 hours the expected result is 600.

PRINT 'TEST 4: Calculate reservation price';

DECLARE @tennis_court_id INT;

SELECT @tennis_court_id = court_id
FROM Court
WHERE court_name = 'Tennis Court 1';

SELECT 
    fn_calculate_reservation_price(
        @tennis_court_id,
        '2026-06-24 13:00:00',
        '2026-06-24 15:00:00'
    ) AS calculated_price;
GO


-- TEST 5: Check a free interval. Expected result: is_available = 1.

PRINT 'TEST 5: Check available court';

DECLARE @tennis_court_id INT;

SELECT @tennis_court_id = court_id
FROM Court
WHERE court_name = 'Tennis Court 1';

SELECT 
    fn_is_court_available(
        @tennis_court_id,
        '2026-06-24 13:00:00',
        '2026-06-24 15:00:00',
        NULL
    ) AS is_available;
GO


-- TEST 6: Check an occupied interval. Tennis Court 1 already has a confirmed reservation on 2026-06-20 10:00-12:00. 
-- Expected result: is_available = 0.

PRINT 'TEST 6: Check unavailable court because of existing reservation';

DECLARE @tennis_court_id INT;

SELECT @tennis_court_id = court_id
FROM Court
WHERE court_name = 'Tennis Court 1';

SELECT 
    fn_is_court_available(
        @tennis_court_id,
        '2026-06-20 10:30:00',
        '2026-06-20 11:30:00',
        NULL
    ) AS is_available;
GO


-- TEST 7: Create a new customer.

PRINT 'TEST 7: Create a new customer';

EXEC usp_create_customer
    @first_name = 'Robert',
    @last_name = 'Taylor',
    @email = 'robert.taylor@example.test',
    @phone = '+420777777777';
GO


-- TEST 8: Update the new customer.

PRINT 'TEST 8: Update created customer';

DECLARE @customer_id INT;

SELECT @customer_id = c.customer_id
FROM Customer c
JOIN Person p
    ON p.person_id = c.person_id
WHERE p.email = 'robert.taylor@example.test';

EXEC usp_update_customer
    @customer_id = @customer_id,
    @first_name = 'Robert',
    @last_name = 'Taylor',
    @email = 'robert.taylor.updated@example.test',
    @phone = '+420777000777',
    @is_active = 1;
GO


-- TEST 9: Try to create a customer with duplicate email. This call should end with an error because Person.email is unique.

PRINT 'TEST 9: Try to create customer with duplicate email - expected error';

BEGIN TRY
    EXEC usp_create_customer
        @first_name = 'Duplicate',
        @last_name = 'Customer',
        @email = 'michael.johnson@example.test',
        @phone = '+420999999999';
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 10: Create a valid reservation. Basketball price is 600 per hour. For 2 hours the expected price is 1200.

PRINT 'TEST 10: Create a valid reservation';

DECLARE @customer_id INT;
DECLARE @court_id INT;

SELECT @customer_id = c.customer_id
FROM Customer c
JOIN Person p
    ON p.person_id = c.person_id
WHERE p.email = 'robert.taylor.updated@example.test';

SELECT @court_id = court_id
FROM Court
WHERE court_name = 'Basketball Court 1';

EXEC usp_create_reservation
    @customer_id = @customer_id,
    @court_id = @court_id,
    @start_time = '2026-06-24 10:00:00',
    @end_time = '2026-06-24 12:00:00';
GO


-- TEST 11: Show pending payments.

PRINT 'TEST 11: Show pending payments';

SELECT *
FROM vw_pending_payments
ORDER BY reservation_id;
GO


-- TEST 12: Try to create an overlapping reservation. This call should end with an error.

PRINT 'TEST 12: Try to create overlapping reservation - expected error';

BEGIN TRY
    DECLARE @customer_id INT;
    DECLARE @court_id INT;

    SELECT @customer_id = c.customer_id
    FROM Customer c
    JOIN Person p
        ON p.person_id = c.person_id
    WHERE p.email = 'laura.garcia@example.test';

    SELECT @court_id = court_id
    FROM Court
    WHERE court_name = 'Basketball Court 1';

    EXEC usp_create_reservation
        @customer_id = @customer_id,
        @court_id = @court_id,
        @start_time = '2026-06-24 11:00:00',
        @end_time = '2026-06-24 13:00:00';
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 13: Try to create a reservation during maintenance. Padel Court 2 has maintenance on 2026-06-23 08:00-12:00. 
-- This call should end with an error.

PRINT 'TEST 13: Try to create reservation during maintenance - expected error';

BEGIN TRY
    DECLARE @customer_id INT;
    DECLARE @court_id INT;

    SELECT @customer_id = c.customer_id
    FROM Customer c
    JOIN Person p
        ON p.person_id = c.person_id
    WHERE p.email = 'laura.garcia@example.test';

    SELECT @court_id = court_id
    FROM Court
    WHERE court_name = 'Padel Court 2';

    EXEC usp_create_reservation
        @customer_id = @customer_id,
        @court_id = @court_id,
        @start_time = '2026-06-23 09:00:00',
        @end_time = '2026-06-23 10:00:00';
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 14:Register payment for the reservation created in TEST 10. The trigger should change reservation status from Pending to Confirmed.

PRINT 'TEST 14: Register payment for created reservation';

DECLARE @reservation_id INT;
DECLARE @employee_id INT;

SELECT @reservation_id = r.reservation_id
FROM Reservation r
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN Court co
    ON co.court_id = r.court_id
WHERE p.email = 'robert.taylor.updated@example.test'
  AND co.court_name = 'Basketball Court 1'
  AND r.start_time = '2026-06-24 10:00:00';

SELECT @employee_id = e.employee_id
FROM Employee e
JOIN Person p
    ON p.person_id = e.person_id
WHERE p.email = 'john.smith@sportscentre.test';

EXEC usp_register_payment
    @reservation_id = @reservation_id,
    @employee_id = @employee_id,
    @amount = 1200.00,
    @payment_method = 'Card';
GO


-- TEST 15: Check that the reservation is now Confirmed.

PRINT 'TEST 15: Check reservation after payment';

SELECT *
FROM vw_reservation_list
WHERE customer_email = 'robert.taylor.updated@example.test'
ORDER BY reservation_id;
GO


-- TEST 16: Try to register a second payment for the same reservation. This call should end with an error.

PRINT 'TEST 16: Try to register duplicate payment - expected error';

BEGIN TRY
    DECLARE @reservation_id INT;
    DECLARE @employee_id INT;

    SELECT @reservation_id = r.reservation_id
    FROM Reservation r
    JOIN Customer c
        ON c.customer_id = r.customer_id
    JOIN Person p
        ON p.person_id = c.person_id
    JOIN Court co
        ON co.court_id = r.court_id
    WHERE p.email = 'robert.taylor.updated@example.test'
      AND co.court_name = 'Basketball Court 1'
      AND r.start_time = '2026-06-24 10:00:00';

    SELECT @employee_id = e.employee_id
    FROM Employee e
    JOIN Person p
        ON p.person_id = e.person_id
    WHERE p.email = 'john.smith@sportscentre.test';

    EXEC usp_register_payment
        @reservation_id = @reservation_id,
        @employee_id = @employee_id,
        @amount = 1200.00,
        @payment_method = 'Card';
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 17: Complete the confirmed reservation.

PRINT 'TEST 17: Complete confirmed reservation';

DECLARE @reservation_id INT;

SELECT @reservation_id = r.reservation_id
FROM Reservation r
JOIN Customer c
    ON c.customer_id = r.customer_id
JOIN Person p
    ON p.person_id = c.person_id
JOIN Court co
    ON co.court_id = r.court_id
WHERE p.email = 'robert.taylor.updated@example.test'
  AND co.court_name = 'Basketball Court 1'
  AND r.start_time = '2026-06-24 10:00:00';

EXEC usp_complete_reservation
    @reservation_id = @reservation_id;
GO


-- TEST 18: Try to cancel a completed reservation. This call should end with an error.

PRINT 'TEST 18: Try to cancel completed reservation - expected error';

BEGIN TRY
    DECLARE @reservation_id INT;

    SELECT @reservation_id = r.reservation_id
    FROM Reservation r
    JOIN Customer c
        ON c.customer_id = r.customer_id
    JOIN Person p
        ON p.person_id = c.person_id
    JOIN Court co
        ON co.court_id = r.court_id
    WHERE p.email = 'robert.taylor.updated@example.test'
      AND co.court_name = 'Basketball Court 1'
      AND r.start_time = '2026-06-24 10:00:00';

    EXEC usp_cancel_reservation
        @reservation_id = @reservation_id;
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 19: Create a valid maintenance period.

PRINT 'TEST 19: Create valid maintenance period';

DECLARE @court_id INT;
DECLARE @employee_id INT;

SELECT @court_id = court_id
FROM Court
WHERE court_name = 'Football Field 1';

SELECT @employee_id = e.employee_id
FROM Employee e
JOIN Person p
    ON p.person_id = e.person_id
WHERE p.email = 'peter.wilson@sportscentre.test';

EXEC usp_create_maintenance
    @court_id = @court_id,
    @employee_id = @employee_id,
    @start_time = '2026-06-24 08:00:00',
    @end_time = '2026-06-24 10:00:00',
    @reason = 'Goal repair';
GO


-- TEST 20: Try to create maintenance during an active reservation. Tennis Court 1 has a confirmed reservation on 2026-06-20 10:00-12:00. 
-- This call should end with an error.

PRINT 'TEST 20: Try to create maintenance during active reservation - expected error';

BEGIN TRY
    DECLARE @court_id INT;
    DECLARE @employee_id INT;

    SELECT @court_id = court_id
    FROM Court
    WHERE court_name = 'Tennis Court 1';

    SELECT @employee_id = e.employee_id
    FROM Employee e
    JOIN Person p
        ON p.person_id = e.person_id
    WHERE p.email = 'peter.wilson@sportscentre.test';

    EXEC usp_create_maintenance
        @court_id = @court_id,
        @employee_id = @employee_id,
        @start_time = '2026-06-20 10:30:00',
        @end_time = '2026-06-20 11:30:00',
        @reason = 'Cleaning during reservation';
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 21: Try to delete a customer with reservations. This call should end with an error.

PRINT 'TEST 21: Try to delete customer with reservations - expected error';

BEGIN TRY
    DECLARE @customer_id INT;

    SELECT @customer_id = c.customer_id
    FROM Customer c
    JOIN Person p
        ON p.person_id = c.person_id
    WHERE p.email = 'michael.johnson@example.test';

    EXEC usp_delete_customer
        @customer_id = @customer_id;
END TRY
BEGIN CATCH
    PRINT 'Expected error was caught:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- TEST 22: Create and delete a customer without reservations.

PRINT 'TEST 22: Create and delete customer without reservations';

EXEC usp_create_customer
    @first_name = 'Temporary',
    @last_name = 'Customer',
    @email = 'temporary.customer@example.test',
    @phone = NULL;
GO

DECLARE @customer_id INT;

SELECT @customer_id = c.customer_id
FROM Customer c
JOIN Person p
    ON p.person_id = c.person_id
WHERE p.email = 'temporary.customer@example.test';

EXEC usp_delete_customer
    @customer_id = @customer_id;
GO


-- TEST 23: Show final customer list.

PRINT 'TEST 23: Show customers after changes';

SELECT *
FROM vw_customer_list
ORDER BY customer_id;
GO


-- TEST 24: Show final reservation list.

PRINT 'TEST 24: Show reservations after changes';

SELECT *
FROM vw_reservation_list
ORDER BY reservation_id;
GO


-- TEST 25: Show active reservations.

PRINT 'TEST 25: Show active reservations';

SELECT *
FROM vw_active_reservations
ORDER BY reservation_id;
GO


-- TEST 26: Show courts under maintenance.

PRINT 'TEST 26: Show courts under maintenance';

SELECT *
FROM vw_courts_under_maintenance
ORDER BY start_time;
GO


-- TEST 27: Show available courts.

PRINT 'TEST 27: Show available courts';

SELECT *
FROM vw_available_courts
ORDER BY court_id;
GO

PRINT 'Test script finished.';
GO