#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
shopt -s expand_aliases

readonly LAND_POLYGONS_FILE="$IMPORT_DATA_DIR/land_polygons.shp"

export PGPASSWORD=$POSTGRES_PASSWORD
alias psql_cmd="psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --dbname=$POSTGRES_DB --username=$POSTGRES_USER"
alias exec_psql=psql_cmd

function log() {
  tput bold;
  tput setaf 3;
  echo $*
  tput reset
}

function import_shp() {
  local shp_file=$1
  local table_name=$2
  shp2pgsql -s 4326 -D -I -g geometry "$shp_file" "$table_name" | exec_psql | hide_inserts
}

function hide_inserts() {
  grep -v "INSERT 0 1"
}

function generate_water_tiles() {
  local table_name="osm_land_polygons_4326"
  import_shp "$LAND_POLYGONS_FILE" "$table_name"

  log Reprojecting land polygons to $PROJECTION
  psql_cmd -f $PROJECTION/reproject_land_polygons.sql

  log 'Calculate required resolutions (TODO)'
  #>>> [(2**0.5)*6371007.2 / (512 * 2**i) for i in range(14)]

  #[17597.587476985624, 8798.793738492812, 4399.396869246406, 2199.698434623203, 1099.8492173116015, 549.9246086558007, 274.96230432790037, 137.48115216395018, 68.74057608197509, 34.370288040987546, 17.185144020493773, 8.592572010246887, 4.296286005123443, 2.1481430025617216]

  #[16000, 8000, 4000, 2000, 1000, 500, 200, 100, 50, 25, 15, 8, 4, 2]

  #[16000, 8000, 4000, z0-2
  #2000, 1000, 500, z3-5
  #200, 100, 50, z6-8
  #25, 15, 8, z9-11
  #4, 2, 1] z12-14

  #So make 0, 8, 50, 500, 4000

  log Setup tables
  psql_cmd -f 3573/setup_tables.sql

  log Setup BBox tiles
  for i in 0 3 6; do
    log $i
    psql_cmd -v zoom=$i -f $PROJECTION/setup_bbox_tiles.sql
  done

  log Simplify land polygons
  # This took > 3 hours.
  # For zoom 6
  psql_cmd -v tolerance=50 -v min_area=2500 -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 3
  psql_cmd -v tolerance=500 -v min_area=250000 -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 0
  psql_cmd -v tolerance=4000 -v min_area=16000000 -f $PROJECTION/simplify_land_polygons.sql

  log Split land polygons
  # Zoom 0
  time psql_cmd -v tolerance=4000 -v min_area=16000000 -v zoom=0 -f $PROJECTION/split_land_polygons.sql
  # Zoom 3
  time psql_cmd -v tolerance=500 -v min_area=250000 -v zoom=3 -f $PROJECTION/split_land_polygons.sql
  # Zoom 6
  for xb in `seq 0 10 63`; do
    for y in `seq 0 63`; do
      for x in `seq $xb $(( $xb + 9 ))`; do
        log Zoom 6 column $x row $y;
        psql_cmd -v tolerance=50 -v min_area=2500 -v zoom=6 -v x=$x -v y=$y -f $PROJECTION/split_land_polygons_by_column_and_row.sql -q &
      done;
      wait;
    done;
  done

  psql_cmd -f $PROJECTION/create_water_polygons.sql

  # Further zooms (9+) are fast enough from the unsplit data.
  psql_cmd -f $PROJECTION/create_unsplit_polygons.sql
}

generate_water_tiles
