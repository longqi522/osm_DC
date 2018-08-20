#!/usr/bin/bash

# setting osm file path and the name of the database as first two arguments
OSM_FILE=$1
PGDATABASE=$2
STYLE=$3


# create a database in postgres

CONFIGDB="psql -U postgres -h localhost --set ON_ERROR_STOP=on --set AUTOCOMIT=off"

$CONFIGDB <<SQL
create database "${PGDATABASE}";
commit;
SQL

RUN_ON_MYDB="psql -U postgres -h localhost -d "${PGDATABASE}" --set ON_ERROR_STOP=on --set AUTOCOMIT=off"

$RUN_ON_MYDB <<SQL
create extension postgis;
create extension hstore;
commit;
SQL

# import data to the database using osm2pgsql

osm2pgsql -c -d "${PGDATABASE}" -U postgres --hstore-all -S "${STYLE}" "${OSM_FILE}"

# configure three tables in the database

$RUN_ON_MYDB <<SQL
alter table planet_osm_point add column long real;
update planet_osm_point set long=st_x(st_transform(way,4326));
alter table planet_osm_point add column lat real;
update planet_osm_point set lat=st_y(st_transform(way,4326));
alter table planet_osm_point add column street text;
update planet_osm_point set street=tags -> 'addr:street';
commit;
SQL

$RUN_ON_MYDB <<SQL
alter table planet_osm_line add column visibility text;
update planet_osm_line set visibility=tags -> 'trail_visibility';
alter table planet_osm_line add column lane_nums text;
update planet_osm_line set lane_nums=tags -> 'lanes';
alter table planet_osm_line add column turn_lane text;
update planet_osm_line set turn_lane=tags -> 'turn:lanes';
alter table planet_osm_line add column geom text;
update planet_osm_line set geom=st_astext(way);
commit;
SQL


$RUN_ON_MYDB <<SQL
alter table planet_osm_polygon add column geom text;
update planet_osm_polygon set geom=st_astext(way);
commit;
SQL
