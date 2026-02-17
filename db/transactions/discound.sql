BEGIN;
/* This script demonstrates how to use BEGIN, SAVEPOINTS, 
 * and ROLLBACK while handling Foreign Key dependencies manually.
 * NOTE: Not the most efficient method (due to manual deletes), 
 * but used to practice Transaction Control Logic.
 */

-- Set a name for the session so it shows up in the Activity Monitor
SET LOCAL application_name = '20%_Discount_FL-567'

UPDATE public."Payment"
SET "Price" = "Price" * 0.8
WHERE "Ticket_ID" IN (
    SELECT "Ticket_ID" FROM public."Ticket" WHERE "Flight_ID" = 'FL-567'
);

SAVEPOINT discount_applied;

DELETE FROM public."Payment"
WHERE "Ticket_ID" IN (
    SELECT "Ticket_ID" FROM public."Ticket" 
    WHERE "Flight_ID" = 'FL-567' AND "Class" = 'Economy'
);

DELETE FROM public."Passenger"
WHERE "Ticket_ID" IN (
    SELECT "Ticket_ID" FROM public."Ticket" 
    WHERE "Flight_ID" = 'FL-567' AND "Class" = 'Economy'
);

DELETE FROM public."Ticket"
WHERE "Flight_ID" = 'FL-567' AND "Class" = 'Economy';

SELECT COUNT(*) FROM public."Ticket" WHERE "Flight_ID" = 'FL-567';

ROLLBACK TO SAVEPOINT discount_applied;

SELECT "Price" FROM public."Payment"; 

COMMIT;