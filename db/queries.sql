-- Average Ticket Price per Route
SELECT "Route_ID", ROUND(AVG("Price"),2) AS Average_Ticket_Price
FROM public."Payment" p
JOIN public."Ticket" t ON p."Ticket_ID" = t."Ticket_ID"
JOIN public."Flight" f ON t."Flight_ID" = f."Flight_ID"
GROUP BY "Route_ID";

-- Active Airlines and their count of assigned routes
SELECT DISTINCT 
    a."Name" AS Active_Airline,
    COUNT(u."Route_ID") OVER(PARTITION BY a."Airline_ID") AS Assigned_Routes
FROM public."Airline" a
JOIN public."Uses" u ON a."Airline_ID" = u."Airline_ID"
ORDER BY Assigned_Routes DESC;

-- Hubs of active airlines
SELECT 
    a."Name" AS "Airline",
    air."Name" AS "Hub_Airport",
    air."Country_ID",
    h."Hub_Type"
FROM public."has_hub" h
JOIN public."Airline" a ON h."Airline_ID" = a."Airline_ID"
JOIN public."Airport" air ON h."Airport_ID" = air."Airport_ID"
ORDER BY a."Name";

-- 'Ghost' Airports
SELECT "Airport_ID" FROM public."Airport"
EXCEPT
(
    SELECT "Airport_ID_start" FROM public."Route"
    UNION
    SELECT "Airport_ID_end" FROM public."Route"
);

-- Airlines Operating the Newcastle (NCL) to Enfidha (NBE) Route 
SELECT "Name", "Airline_ID"
FROM public."Airline"
WHERE "Airline_ID" IN (
    SELECT "Airline_ID"
    FROM public."Uses"
    WHERE "Route_ID" IN (
        SELECT "Route_ID"
        FROM public."Route"
        WHERE "Airport_ID_start" = 'NCL' AND "Airport_ID_end" = 'NBE'
    )
);

-- Flight Booking Status Report
SELECT f."Flight_ID", f."Departure_Time"::date AS "Flight_Date", t."Ticket_ID"
FROM public."Flight" f
LEFT JOIN public."Ticket" t ON f."Flight_ID" = t."Flight_ID";

-- Flights with no sales yet
SELECT 
    f."Flight_ID", 
    f."Departure_Time",
    t."Ticket_ID"
FROM public."Flight" f
LEFT JOIN public."Ticket" t ON f."Flight_ID" = t."Flight_ID"
WHERE t."Ticket_ID" IS NULL;

-- Revenue Status Report
SELECT 
    f."Flight_ID", 
    COALESCE(SUM(p."Price"), 0) AS "Total_Revenue"
FROM public."Flight" f
LEFT JOIN public."Ticket" t ON f."Flight_ID" = t."Flight_ID"
LEFT JOIN public."Payment" p ON t."Ticket_ID" = p."Ticket_ID"
GROUP BY f."Flight_ID"
ORDER BY "Total_Revenue" ASC;

-- Ticket Price Categorization
SELECT 
    "Ticket_ID",
    "Price",
    CASE 
        WHEN "Price" > 800 THEN 'High'
        WHEN "Price" BETWEEN 400 AND 800 THEN 'Standard'
        ELSE 'Low'
    END AS "Ticket_range"
FROM public."Payment";


-- Airlines Serving Greece
SELECT DISTINCT "Airline"."Airline_ID", "Airline"."Name"
FROM "Airline"
JOIN "Uses" ON "Airline"."Airline_ID" = "Uses"."Airline_ID"
JOIN "Route" ON "Uses"."Route_ID" = "Route"."Route_ID"
JOIN "Airport" ON "Route"."Airport_ID_start" = "Airport"."Airport_ID" OR "Route"."Airport_ID_end" = "Airport"."Airport_ID"
JOIN "Country" ON "Airport"."Country_ID" = "Country"."Country_ID"
WHERE "Country"."Country_ID" = 'Greece';

-- Airlines Departing from Thessaloniki (SKG)
-- slower
SELECT "Name"
FROM public."Airline"
WHERE "Airline_ID" IN (
  SELECT "Airline_ID"
  FROM public."Uses"
  WHERE "Route_ID" IN (
    SELECT "Route_ID"
    FROM public."Route"
    WHERE "Airport_ID_start" = 'SKG'
  )
);
-- better
SELECT DISTINCT a."Name"
FROM public."Airline" a
JOIN public."Uses" u ON a."Airline_ID" = u."Airline_ID"
JOIN public."Route" r ON u."Route_ID" = r."Route_ID"
WHERE r."Airport_ID_start" = 'SKG';

-- Estimated Revenue by Route Assignment
/* 
   Note: This query calculates revenue based on Route Ownership.
   It may double-count revenue if multiple airlines share a route.
   This is a known limitation of the current schema design.
*/

SELECT a."Name", SUM(t."Price") AS "Total_Revenue"
FROM public."Airline" a
JOIN public."Uses" u ON a."Airline_ID" = u."Airline_ID"
JOIN public."Ticket" t ON u."Route_ID" = t."Route_ID"
GROUP BY a."Name"
ORDER BY "Total_Revenue" DESC;

-- Global Airport Distribution
SELECT c."Country_ID" AS "Country", COUNT(a."Airport_ID") AS "Total_Airports"
FROM public."Country" c
JOIN public."Airport" a ON c."Country_ID" = a."Country_ID"
GROUP BY c."Country_ID"
ORDER BY "Total_Airports" DESC;

-- Passenger revenue ranking
SELECT pa."Full_Name", SUM(p."Price") AS "Total_Spent"
FROM public."Passenger" pa
JOIN public."Ticket" t ON pa."Ticket_ID" = t."Ticket_ID"
JOIN public."Payment" p ON t."Ticket_ID" = p."Ticket_ID"
GROUP BY pa."Full_Name"
ORDER BY "Total_Spent" DESC
LIMIT 10;

-- Above Average Spenders
WITH AveragePrice AS (
    SELECT AVG("Price") AS avg_val FROM public."Payment"
)
SELECT pass."Full_Name", p."Price"
FROM public."Payment" p
JOIN public."Ticket" t ON p."Ticket_ID" = t."Ticket_ID"
JOIN public."Passenger" pass ON t."Ticket_ID" = pass."Ticket_ID"
CROSS JOIN AveragePrice
WHERE p."Price" > AveragePrice.avg_val;

-- Global Passenger Ranking
SELECT 
    pass."Full_Name", 
    p."Ticket_ID", 
    p."Price",
    DENSE_RANK() OVER (ORDER BY p."Price" DESC) AS price_rank
FROM public."Payment" p
JOIN public."Ticket" t ON p."Ticket_ID" = t."Ticket_ID"
JOIN public."Passenger" pass ON t."Ticket_ID" = pass."Ticket_ID"
ORDER BY price_rank ASC;

-- Top Passenger ticket per flight
WITH FlightLeaderboard AS (
    SELECT 
        t."Flight_ID",
        pass."Full_Name", 
        p."Price",
        DENSE_RANK() OVER (PARTITION BY t."Flight_ID" ORDER BY p."Price" DESC) AS price_rank
    FROM public."Payment" p
    JOIN public."Ticket" t ON p."Ticket_ID" = t."Ticket_ID"
    JOIN public."Passenger" pass ON t."Ticket_ID" = pass."Ticket_ID"
)
SELECT "Flight_ID", "Full_Name", "Price"
FROM FlightLeaderboard
WHERE price_rank = 1;

-- Next flight
SELECT 
    "Flight_ID", 
    "Route_ID", 
    "Departure_Time",
    LEAD("Departure_Time") OVER(ORDER BY "Departure_Time") AS "Next_Flight_Departure",
    LEAD("Departure_Time") OVER(ORDER BY "Departure_Time") - "Departure_Time" AS "Time_Between_Flights"
FROM public."Flight";

-- Return Flights
SELECT 
    f1."Flight_ID" AS Outbound_Flight,
    f2."Flight_ID" AS Return_Flight,
    r1."Airport_ID_start" AS Origin,
    r1."Airport_ID_end" AS Destination,
    f1."Departure_Time" AS Leaves_Home,
    f2."Departure_Time" AS Returns_Home
FROM public."Flight" f1
JOIN public."Route" r1 ON f1."Route_ID" = r1."Route_ID"
INNER JOIN public."Flight" f2 ON f1."Flight_ID" != f2."Flight_ID"
JOIN public."Route" r2 ON f2."Route_ID" = r2."Route_ID"
WHERE 
    r1."Airport_ID_start" = r2."Airport_ID_end" 
    AND r1."Airport_ID_end" = r2."Airport_ID_start"
    AND f2."Departure_Time" > f1."Arrival_Time" + INTERVAL '2 hours'
    AND f2."Departure_Time" <= f1."Departure_Time" + INTERVAL '1 month'
ORDER BY f1."Departure_Time";

-- Total Revenue per Flight by Ticket Class
SELECT 
    f."Flight_ID",
    SUM(CASE WHEN t."Class" = 'Economy' THEN p."Price" ELSE 0 END) AS "Economy_Rev",
    SUM(CASE WHEN t."Class" = 'Business' THEN p."Price" ELSE 0 END) AS "Business_Rev",
    SUM(CASE WHEN t."Class" = 'First Class' THEN p."Price" ELSE 0 END) AS "FirstClass_Rev"
FROM public."Flight" f
JOIN public."Ticket" t ON f."Flight_ID" = t."Flight_ID"
JOIN public."Payment" p ON t."Ticket_ID" = p."Ticket_ID"
GROUP BY f."Flight_ID";

-- Chronological Airport Activity Log
SELECT 
    "Flight_ID",
    'Departure' AS event_type,
    "Departure_Time" AS event_time
FROM public."Flight"

UNION ALL

SELECT 
    "Flight_ID",
    'Arrival' AS event_type,
    "Arrival_Time" AS event_time
FROM public."Flight"

ORDER BY event_time;