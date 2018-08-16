#!/usr/bin/bash

# osm file path
OSM_FILE=$1
export PGDATABASE=$2


# clean up any existing db and files
dropdb --if-exists "${PGDATABASE}"


createdb
psql -Xqw -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'

osm2pgsql -c -d "${PGDATABASE}" -U postgres -H localholst --hstore-all -S ./default.style "${PLANET_FILE}"

RUN_ON_MYDB="psql -X -U postgres -h localholst -d ${PGDATABASE} --set ON_ERROR_STOP=on --set AUTOCOMIT=off"

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
