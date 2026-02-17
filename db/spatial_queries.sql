-- X, Y Coordinates
SELECT ST_X(geom) AS x_coord, ST_Y(geom) AS y_coord
FROM public."Airport"

-- Area
SELECT ST_Area(geom) AS area
FROM public."Country"


SELECT a."Airport_ID", a."Name", a.geom
FROM public."Airport" a, public."Country" c
WHERE c."Country_ID" = 'Greece'
AND ST_DWithin(a.geom::geography, (SELECT ST_Union(geom) FROM public."Country" WHERE "Country_ID" = 'Greece')::geography, 100000)
