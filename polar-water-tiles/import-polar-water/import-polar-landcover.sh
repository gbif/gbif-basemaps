#!/bin/bash
set -o errexit
set -o pipefail
#set -o nounset
shopt -s expand_aliases

export PGPASSWORD=$POSTGRES_PASSWORD
alias psql_cmd="psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --dbname=$POSTGRES_DB --username=$POSTGRES_USER"
alias exec_psql=psql_cmd

function log() {
  tput bold;
  tput setaf 3;
  echo $(date +%Y-%m-%dT%H:%M:%S) $*
  tput sgr0;
}

function hide_inserts() {
  grep -v "INSERT 0 1"
}

function generate_landcover_tiles() {

  log Reprojecting landcover polygons to $PROJECTION
  psql_cmd -f ${PROJECTION}_landcover/reproject_landcover_polygons.sql

  log Setup tables
  psql_cmd -f $PROJECTION/setup_tables.sql

  for i in `seq 0 8`; do
    log Setup BBox tiles $i
    psql_cmd -v zoom=$i -f $PROJECTION/setup_bbox_tiles.sql
  done

  log Simplify landcover polygons
  # This took > 3 hours.
  # Many polygons lower than the min_area are present.
  # For zoom 13
  psql_cmd -v tolerance=2     -v min_area=6         -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 12
  psql_cmd -v tolerance=4     -v min_area=12        -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 11
  psql_cmd -v tolerance=8     -v min_area=25        -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 10
  psql_cmd -v tolerance=15    -v min_area=100       -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 9
  psql_cmd -v tolerance=25    -v min_area=400       -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 8
  psql_cmd -v tolerance=50    -v min_area=2500      -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # For zoom 7
  psql_cmd -v tolerance=100   -v min_area=10000     -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql
  # Lower zooms use Natural Earth data.


  psql_cmd -v tolerance=100   -v min_area=10000     -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql &
  psql_cmd -v tolerance=50    -v min_area=2500      -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql &
  psql_cmd -v tolerance=25    -v min_area=400       -f ${PROJECTION}_landcover/simplify_landcover_polygons.sql &

  split_in_parallel_grid8  7 100 10000
  split_in_parallel_grid8  8  50  2500
  split_in_parallel_grid8  9  25   400
  split_in_parallel_grid8 10  15   100
  split_in_parallel_grid8 11   8    25
  split_in_parallel_grid8 12   4    12
  split_in_parallel_grid8 13   2     6
}

function split_in_parallel() {
  cpuCount=$(grep --count $'^processor\t' /proc/cpuinfo)
  cpus=$((cpuCount - 2))
  cpusminusone=$((cpuCount - 3))

  zoom=$1
  tol=$2
  area=$3

  maxTile=$(( 2**$zoom - 1))

  log Split landcover polygons zoom $zoom using $cpus parallel processes
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
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v x=$x -v y=$y -f ${PROJECTION}_landcover/split_landcover_polygons_by_column_and_row.sql -q &
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

  log Split landcover polygons zoom $zoom '(8-grid)' using $cpus parallel processes
  # Width of the map in tiles
  w=256
  # Decimal radius in map tiles of the 45° parallel, squared.
  #pp=$(( ((4889334.80/9009964.76)*(2**(zoom-1)))**2 ))
  # No floating-point arithmetic in shell scripts.
  pp=4825
  for xb in `seq 57 $cpus 199`; do
    for y in `seq 57 199`; do
      xmax=$(( $xb + $cpusminusone ))
      if [[ $xmax -gt 199 ]]; then
        xmax=199
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
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v grid=8 -v x=$x -v y=$y -f ${PROJECTION}_landcover/split_landcover_polygons_by_column_and_row_higher_grid.sql -q &
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

generate_landcover_tiles
