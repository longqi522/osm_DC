#!/usr/bin/bash

# define the database name, user name, polygon coordinate which is copied from the geom column in the format of 'POLYGON(...)' and road_id which is copied from the osm_id column

PGDATABASE=$1
USER=$2
POLYGON=$3
ROADID=$4

RUN_ON_MYDB="psql -U "${USER}" -d "${PGDATABASE}" --set ON_ERROR_STOP=on --set AUTOCOMIT=off"

# choose the polygon select from user's argument and use ST_Intersect to compare its lat/long with the geom information from planet_osm_line table to get the intersection between roads and polygon

$RUN_ON_MYDB <<SQL
SELECT
  ST_Intersects(a.geom, b.geom), a.osm_id, a.name
FROM
  planet_osm_line AS a,
  planet_osm_polygon AS b
WHERE b.geom = '${POLYGON}'
AND ST_Intersects(a.geom, b.geom);
commit;
SQL

# choose the road_id from user's argument, use ST_Intersects to make the selection of the roads intersect with it and use ST_Within to make sure all the intersect roads are within the polygon defined by user

$RUN_ON_MYDB <<SQL
SELECT
  ST_Intersects(a.geom, b.geom),
  ST_Within(a.geom, c.geom),
  a.osm_id, a.name
FROM
  planet_osm_line AS a,
  planet_osm_line AS b,
  planet_osm_polygon AS c
WHERE b.osm_id = ${ROADID}
AND c.geom = '${POLYGON}'
AND ST_Within(a.geom, c.geom)
AND ST_Intersects(a.geom, b.geom)
AND a.osm_id != b.osm_id;
commit;
SQL

# find the beginning and endpoint of the road, and find the lines that are intersect with these two points within the range of that polygon. 

$RUN_ON_MYDB <<SQL
SELECT
  (ST_Touches(ST_AsText(ST_Endpoint(b.geom)), a.geom) OR ST_Touches(ST_AsText(ST_Startpoint(b.geom)), a.geom)),
  ST_Within(a.geom, c.geom),
  a.osm_id, a.name
FROM
  planet_osm_line AS a,
  planet_osm_line AS b,
  planet_osm_polygon AS c
WHERE b.osm_id = ${ROADID}
AND c.geom = '${POLYGON}'
AND (ST_Touches(ST_AsText(ST_Endpoint(b.geom)), a.geom) OR ST_Touches(ST_AsText(ST_Startpoint(b.geom)), a.geom))
AND ST_Within(a.geom, c.geom);
commit;
SQL
