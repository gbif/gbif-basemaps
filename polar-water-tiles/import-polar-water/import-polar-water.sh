#!/bin/bash
set -o errexit
set -o pipefail
#set -o nounset
shopt -s expand_aliases

readonly LAND_POLYGONS_FILE="$IMPORT_DATA_DIR/land_polygons.shp"

export PGPASSWORD=$POSTGRES_PASSWORD
alias psql_cmd="psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --dbname=$POSTGRES_DB --username=$POSTGRES_USER"
alias exec_psql=psql_cmd

function log() {
  tput bold;
  tput setaf 3;
  echo $(date +%Y-%m-%dT%H:%M:%S) $*
  tput sgr0;
}

function download() {
  if [[ ! -f $LAND_POLYGONS_FILE ]]; then
    log Downloading OSM Data land polygons
    #wget -c -O $IMPORT_DATA_DIR/land-polygons-complete-4326.zip --progress=dot:giga http://data.openstreetmapdata.com/land-polygons-complete-4326.zip
    wget -c -O $IMPORT_DATA_DIR/land-polygons-complete-4326.zip --progress=dot:giga http://mb.gbif.org/land-polygons-complete-4326.zip
    cd $IMPORT_DATA_DIR
    log Extracting land polygons
    unzip -j land-polygons-complete-4326.zip '*/land_polygons.shp'
    cd -
  fi
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
  log Importing shapefile
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
  psql_cmd -f $PROJECTION/setup_tables.sql

  for i in `seq 0 13`; do
    log Setup BBox tiles $i
    psql_cmd -v zoom=$i -f $PROJECTION/setup_bbox_tiles.sql
  done

  log Simplify land polygons
  # This took > 3 hours.
  # Many polygons lower than the min_area are present.
  # For zoom 11
  psql_cmd -v tolerance=8     -v min_area=25        -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 10
  psql_cmd -v tolerance=15    -v min_area=100       -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 9
  psql_cmd -v tolerance=25    -v min_area=400       -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 8
  psql_cmd -v tolerance=50    -v min_area=2500      -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 7
  psql_cmd -v tolerance=100   -v min_area=10000     -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 6
  psql_cmd -v tolerance=200   -v min_area=40000     -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 5
  psql_cmd -v tolerance=500   -v min_area=250000    -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 4
  psql_cmd -v tolerance=1000  -v min_area=1000000   -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 3
  psql_cmd -v tolerance=2000  -v min_area=4000000   -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 2
  psql_cmd -v tolerance=4000  -v min_area=16000000  -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 1
  psql_cmd -v tolerance=8000  -v min_area=64000000  -f $PROJECTION/simplify_land_polygons.sql
  # For zoom 0
  psql_cmd -v tolerance=16000 -v min_area=256000000 -f $PROJECTION/simplify_land_polygons.sql

  log Split land polygons zoom 0
  time psql_cmd -v tolerance=16000 -v min_area=256000000 -v zoom=0 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 1
  time psql_cmd -v tolerance=8000  -v min_area=64000000  -v zoom=1 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 2
  time psql_cmd -v tolerance=4000  -v min_area=16000000  -v zoom=2 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 3
  time psql_cmd -v tolerance=2000  -v min_area=4000000   -v zoom=3 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 4
  time psql_cmd -v tolerance=1000  -v min_area=1000000   -v zoom=4 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 5
  time psql_cmd -v tolerance=500   -v min_area=250000    -v zoom=5 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 6
  time psql_cmd -v tolerance=200   -v min_area=40000     -v zoom=6 -f $PROJECTION/split_land_polygons.sql
  log Split land polygons zoom 7
  time psql_cmd -v tolerance=100   -v min_area=10000     -v zoom=7 -f $PROJECTION/split_land_polygons.sql

  log Split land polygons
  split_in_parallel  6 200 40000
  split_in_parallel  7 100 10000
  split_in_parallel  8  50  2500
  split_in_parallel  9  25   400
  split_in_parallel 10  15   100
  split_in_parallel 11   8    25

  log Split land polygons to an 8-grid
  split_in_parallel_grid8 14 0 0

  psql_cmd -f $PROJECTION/create_water_polygons.sql

  # Further zooms (9+) are fast enough from the unsplit data.
  # This took over 1¾ hours.
  # psql_cmd -f $PROJECTION/create_unsplit_polygons.sql
  # This is not fast enough, instead the 8-grid split is used from unsimplified polygons.  This needs
  # work next time, as zooms 9-10 were made the slow way.
}

function split_in_parallel() {
  cpuCount=$(grep --count $'^processor\t' /proc/cpuinfo)
  cpus=$((cpuCount - 2))
  cpusminusone=$((cpuCount - 3))

  zoom=$1
  tol=$2
  area=$3

  maxTile=$(( 2**$zoom - 1))

  log Split land polygons zoom $zoom using $cpus parallel processes
  # Width of the map in tiles
  w=$(( 2**$zoom ))
  maxTile=$(( $w - 1 ))
  # Decimal radius in map tiles of the Equator, squared.
  pp=$(( 2**($zoom-1) * 2**($zoom-1) ))
  for xb in `seq 0 $cpus $maxTile`; do
    for y in `seq 0 $maxTile`; do
      xmax=$(( $xb + $cpusminusone ))
      if [[ $xmax -gt $maxTile ]]; then
        xmax=$maxTile
      fi
      for x in `seq $xb $xmax`; do

        # Convert to coordinate of corner of tile closest to North Pole
        xnp=$(( $x - ($w/2) ))
        if [[ $x -lt $(($w/2)) ]]; then
          xnp=$(( $xnp + 1 ))
        fi
        ynp=$(( $y - ($w/2) ))
        if [[ $y -lt $(($w/2)) ]]; then
          ynp=$(( $ynp + 1 ))
        fi

        if [[ $(( $xnp * $xnp + $ynp * $ynp )) -le $pp ]]; then
          log Zoom $zoom column $x row $y
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v x=$x -v y=$y -f $PROJECTION/split_land_polygons_by_column_and_row.sql -q &
          while [[ $(jobs | wc -l) -ge $cpusminusone ]]; do
            sleep 1
          done
        else
          log "Zoom $zoom column $x row $y not in northern hemisphere"
        fi
      done
    done
  done
  wait
}

function split_in_parallel_grid8() {
  cpuCount=$(grep --count $'^processor\t' /proc/cpuinfo)
  cpus=$((cpuCount - 2))
  cpusminusone=$((cpuCount - 3))

  zoom=$1
  tol=$2
  area=$3

  log Split land polygons zoom $zoom '(8-grid)' using $cpus parallel processes
  # Width of the map in tiles
  w=256
  # Decimal radius in map tiles of the Equator, squared.
  pp=$(( 128 * 128 ))
  for xb in `seq 0 $cpus 255`; do
    for y in `seq 0 255`; do
      xmax=$(( $xb + $cpusminusone ))
      if [[ $xmax -gt 255 ]]; then
        xmax=255
      fi
      for x in `seq $xb $xmax`; do

        # Convert to coordinate of corner of tile closest to North Pole
        xnp=$(( $x - ($w/2) ))
        if [[ $x -lt $(($w/2)) ]]; then
          xnp=$(( $xnp + 1 ))
        fi
        ynp=$(( $y - ($w/2) ))
        if [[ $y -lt $(($w/2)) ]]; then
          ynp=$(( $ynp + 1 ))
        fi

        if [[ $(( $xnp * $xnp + $ynp * $ynp )) -le $pp ]]; then
          log Zoom $zoom '(8-grid)' column $x row $y
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v grid=8 -v x=$x -v y=$y -f $PROJECTION/split_land_polygons_by_column_and_row_higher_grid.sql -q &
          while [[ $(jobs | wc -l) -ge $cpusminusone ]]; do
            sleep 1
          done
        else
          log "Zoom $zoom (8-grid) column $x row $y not in northern 45°"
        fi
      done
    done
  done
  wait
}

download

generate_water_tiles
