-- Query 1

-- X, Y Coordinates
SELECT 
    ST_X(geom) AS x_coord, 
    ST_Y(geom) AS y_coord
FROM public."Airport";

-- Area
SELECT 
    ST_Area(geom) AS area
FROM public."Country";

-- Query 2

/* Greek Airports within 100km Buffer 
 * It finds airports inside Greece that are specifically close to the national perimeter 
 * (within 100km of the boundary)
 */

SELECT 
    a."Airport_ID", 
    a."Name", 
    a.geom
FROM public."Airport" a, public."Country" c
WHERE c."Country_ID" = 'Greece'
AND ST_DWithin(
    a.geom::geography,
    (SELECT ST_Union(geom) 
     FROM public."Country" 
     WHERE "Country_ID" = 'Greece')::geography,
    100000
);

-- Query 3

/* These queries demonstrate three distinct PostGIS spatial relationship 
 * functions to find airports that are geographically located within 
 * the borders of Greece.
 */

-- Intersection (General overlap)
SELECT a.*, b.*
FROM public."Airport" a
JOIN public."Country" b
ON ST_Intersects(a.geom, b.geom)
WHERE b."Country_ID" = 'Greece';

-- Containment (Standard Point-in-Polygon)
SELECT a.*, c.*
FROM public."Airport" a
JOIN public."Country" c
ON ST_Contains(c.geom, a.geom)
WHERE c."Country_ID" = 'Greece';

-- Coverage (Strict Boundary Check)
SELECT a.*
FROM public."Airport" a
JOIN public."Country" c
ON ST_CoveredBy(a.geom, c.geom)
WHERE c."Country_ID" = 'Greece';

-- Query 4

/* Identifying Nearby Airport Clusters
 * This query finds pairs of airports located within 1,000 meters (1km) of each other.
 */

SELECT a1.*, a2.*
FROM public."Airport" a1, public."Airport" a2
WHERE ST_Distance(a1.geom, a2.geom) < 1000
AND a1."Airport_ID" <> a2."Airport_ID"
LIMIT 5;

-- Query 5

/* Neighboring Countries of Greece
 * This query identifies all countries that share a physical land or sea border with Greece.
*/

SELECT 
    c."Country_ID", 
    c.geom
FROM public."Country" c, public."Country" g
WHERE ST_Touches(c.geom, g.geom)
AND g."Country_ID" = 'Greece';

-- Query 6

/* Identifying Countries Traversed by Flight Routes
 * This query determines which countries a specific flight path (ATH-CGN) passes through.
*/

SELECT DISTINCT
    r."Route_ID",
    c1."Country_ID" AS "Country",
    c1.geom
FROM public."Route" r
JOIN public."Country" c1 
ON (ST_Crosses(r.geom, c1.geom) 
    OR ST_Within(r.geom, c1.geom))
AND r.geom && c1.geom
WHERE r."Route_ID" = 'ATH-CGN';

-- Query 7

/* Identifying Airports near Dimokritos (5-Degree Buffer)
 * This query creates a circular "zone" around Dimokritos Airport and finds any other airport that falls within that circle.
*/

SELECT *
FROM public."Airport" a
WHERE ST_Intersects(
    ST_Buffer(a.geom, 5),
    (SELECT a1.geom 
     FROM public."Airport" a1 
     WHERE a1."Name" = 'Dimokritos Airport')
);

-- Query 8

-- NOTE: This analysis is purely geographic and does not account for time scheduling.

/* Detecting Consecutive Routes from ATH
 * This query is designed to find "connecting flights" or route sequences. It identifies cases where one flight ends exactly where another one begins.
*/

SELECT DISTINCT 
    r1."Route_ID" AS Route1_ID, 
    r1.geom AS Route1_geom, 
    r2."Route_ID" AS Route2_ID, 
    r2.geom AS Route2_geom
FROM public."Route" r1
JOIN public."Route" r2 
ON ST_Equals(
    ST_StartPoint(r2.geom), 
    ST_EndPoint(r1.geom)
)
WHERE r1."Route_ID" <> r2."Route_ID"
AND r1."Airport_ID_start" = 'ATH';

-- Query 9

/*Comparing Connections to Direct Routes
 * This query glues two connecting flight legs together into one long path. 
 * Then, it checks if that combined path perfectly matches or "covers" 
 * the path of the direct flight from Athens to Geneva.
*/

CREATE VIEW public."Combined_Routes" AS
SELECT 
    r1."Route_ID" AS Route1_ID, 
    r2."Route_ID" AS Route2_ID, 
    ST_Union(r1.geom, r2.geom) AS combined_geom
FROM public."Route" r1
JOIN public."Route" r2 
ON ST_Equals(
    ST_StartPoint(r2.geom), 
    ST_EndPoint(r1.geom)
)
WHERE r1."Route_ID" <> r2."Route_ID"
AND r1."Airport_ID_start" = 'ATH';

SELECT *
FROM public."Combined_Routes" AS c
WHERE EXISTS (
    SELECT 1
    FROM public."Route" AS r
    WHERE r."Airport_ID_start" = 'ATH'
    AND r."Airport_ID_end" = 'GVA'
    AND ST_Covers(c.combined_geom, r.geom)
);
