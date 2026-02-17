BEGIN;
/* This transaction updates the Foreign Key constraints to implement 'ON DELETE CASCADE'.
 * * 1. FLIGHT -> TICKET: If a flight is cancelled and deleted, its tickets are automatically removed.
 * 2. TICKET -> PAYMENT: If a ticket is deleted, its corresponding payment record is automatically wiped.
 * * PASSENGER SAFETY: Note that we do NOT cascade to the Passenger table. This acts as a 
 * "Safety Lock"—the database will block a deletion if it would leave a Passenger 
 * without their historical booking data.
 */

ALTER TABLE public."Ticket" 
DROP CONSTRAINT fk_flight;

ALTER TABLE public."Ticket"
ADD CONSTRAINT "v2_fk_flight"
FOREIGN KEY ("Flight_ID") 
REFERENCES public."Flight" ("Flight_ID") 
ON DELETE CASCADE;

ALTER TABLE public."Payment" 
DROP CONSTRAINT IF EXISTS "fk_ticket";

ALTER TABLE public."Payment"
ADD CONSTRAINT "v2_fk_ticket"
FOREIGN KEY ("Ticket_ID") 
REFERENCES public."Ticket" ("Ticket_ID") 
ON DELETE CASCADE;

COMMIT;