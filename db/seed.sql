INSERT INTO public."Flight" ("Flight_ID", "Departure_Time", "Arrival_Time", "Route_ID")
SELECT 
    'FL-999', 
    '2026-02-15 13:50:00'::timestamptz,
    -- Logic: Departure + (Distance / Speed) + 30 mins
    ('2026-02-15 13:50:00'::timestamptz + 
      date_trunc('second',(ST_DistanceSphere(a1.geom, a2.geom) / 1000 / 800 * INTERVAL '1 hour') + 
      INTERVAL '30 minutes')), 
    'SKG-ATH'
FROM public."Route" r
JOIN public."Airport" a1 ON r."Airport_ID_start" = a1."Airport_ID"
JOIN public."Airport" a2 ON r."Airport_ID_end" = a2."Airport_ID"
WHERE r."Route_ID" = 'SKG-ATH';

INSERT INTO public."Flight" ("Flight_ID", "Departure_Time", "Arrival_Time", "Route_ID")
SELECT 
    'FL-567', 
    '2026-02-20 17:00:00'::timestamptz,
    date_trunc('second',('2026-02-20 17:00:00'::timestamptz + 
      (ST_DistanceSphere(a1.geom, a2.geom) / 1000 / 800 * INTERVAL '1 hour') + 
      INTERVAL '30 minutes')), 
    'SKG-NUE'
FROM public."Route" r
JOIN public."Airport" a1 ON r."Airport_ID_start" = a1."Airport_ID"
JOIN public."Airport" a2 ON r."Airport_ID_end" = a2."Airport_ID"
WHERE r."Route_ID" = 'SKG-NUE';

INSERT INTO public."Ticket" ("Ticket_ID", "Class", "Flight_ID")
VALUES
('TKT-9990001111', 'Economy', 'FL-567'),
('TKT-9990001112', 'Business', 'FL-567'),
('TKT-9990001113', 'First Class', 'FL-567');

INSERT INTO public."Payment" ("Payment_ID", "Ticket_ID", "Date", "Price", "Method")
VALUES 
(101, 'TKT-9990001111', '2026-02-10', 150.00, 'Cash'),
(102, 'TKT-9990001112', '2026-01-23', 450.50, 'Card'), 
(103, 'TKT-9990001113', '2025-12-06', 980.00, 'Card'); 

INSERT INTO public."Passenger" ("Passenger_ID", "Full_Name", "Phone", "Age", "Country_ID", "Ticket_ID")
VALUES
(1, 'Eleni Papadopoulou', '+30 697 123 4567', 28, 'Slovakia', 'TKT-9990001111'),
(2, 'Despoina Mauroudi', '+49 151 9876 5432', 25, 'Japan', 'TKT-9990001112'),
(3, 'Eleonora Stoikopoulou', '+1 212 555 0199', 26, 'Greece', 'TKT-9990001113');

--------------------------------------------------------------------------------
-- HUB MANAGEMENT OPTIONS
--------------------------------------------------------------------------------

-- OPTION 1: Static Hub Table
/* It counts flights per airport, ranks them by volume using ROW_NUMBER(), 
 * and inserts only the #1 most-used airport into the "has_hub" table.
 */
INSERT INTO public."has_hub" ("Airline_ID", "Airport_ID")
SELECT "Airline_ID", "Airport_ID_start"
FROM (
    SELECT u."Airline_ID", r."Airport_ID_start", 
           COUNT(*) as flight_count,
           ROW_NUMBER() OVER(PARTITION BY u."Airline_ID" ORDER BY COUNT(*) DESC) as rank
    FROM public."Uses" u
    JOIN public."Route" r ON u."Route_ID" = r."Route_ID"
    GROUP BY u."Airline_ID", r."Airport_ID_start"
) ranked_hubs
WHERE rank = 1;


-- OPTION 2: Dynamic Hub View 
/* * ALTERNATIVE APPROACH: 
 * If we aren't sure about the hubs, or if the flight schedule changes weekly, 
 * we should NOT use a static table. Instead, we use this View.
 *
 * WHY A VIEW?
 * 1. Real-time: It always reflects the CURRENT most-used airport.
 * 2. Accuracy: If an airline switches its main base, the View updates automatically.
 * 3. Integrity: It prevents "stale" data in the 'has_hub' table.
 */

CREATE VIEW v_calculated_airline_hubs AS
SELECT "Airline_ID", "Airport_ID_start" AS "Main_Hub"
FROM (
    SELECT u."Airline_ID", r."Airport_ID_start", 
           COUNT(*) as flight_count,
           ROW_NUMBER() OVER(PARTITION BY u."Airline_ID" ORDER BY COUNT(*) DESC) as rank
    FROM public."Uses" u
    JOIN public."Route" r ON u."Route_ID" = r."Route_ID"
    GROUP BY u."Airline_ID", r."Airport_ID_start"
) ranked_hubs
WHERE rank = 1;