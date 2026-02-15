-- Average Ticket Price per Route
SELECT "Route_ID", ROUND(AVG("Price"),2) AS Average_Ticket_Price
FROM public."Payment" p
JOIN public."Ticket" t ON p."Ticket_ID" = t."Ticket_ID"
JOIN public."Flight" f ON t."Flight_ID" = f."Flight_ID"
GROUP BY "Route_ID";

-- Active Airlines
SELECT DISTINCT 
    a."Name" AS Active_Airline,
    COUNT(u."Route_ID") OVER(PARTITION BY a."Airline_ID") AS Assigned_Routes
FROM public."Airline" a
JOIN public."Uses" u ON a."Airline_ID" = u."Airline_ID"
ORDER BY Assigned_Routes DESC;

-- Hubs of actvie airlines
SELECT 
    a."Name" AS "Airline",
    air."Name" AS "Hub_Airport",
    air."City",
    air."Country",
    h."Hub_Type"
FROM public."has_hub" h
JOIN public."Airline" a ON h."Airline_ID" = a."Airline_ID"
JOIN public."Airport" air ON h."Airport_ID" = air."Airport_ID"
ORDER BY a."Name";

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

