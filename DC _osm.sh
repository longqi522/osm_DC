#!/usr/bin/bash

# osm file path
OSM_FILE='data.osm.pbf'


# su postgres
createdb DC

psql -U postgres -d DC -c 'CREATE DATABASE DC; CREATE EXTENSION postgis; CREATE EXTENSION hstore;'

osm2pgsql -c -d DC -U postgres -H localholst --hstore-all  "${PLANET_FILE}"



