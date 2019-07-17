#!/bin/bash
set -o errexit
set -o pipefail
#set -o nounset
shopt -s expand_aliases

readonly LAND_POLYGONS_FILE="$IMPORT_DATA_DIR/land_polygons.shp"

export PGPASSWORD=$POSTGRES_PASSWORD
alias psql_cmd="psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --dbname=$POSTGRES_DB --username=$POSTGRES_USER"
alias exec_psql=psql_cmd

cpuCount=$(grep --count $'^processor\t' /proc/cpuinfo)
cpus=$((cpuCount - 2))
cpusminusone=$((cpuCount - 3))


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

  # TODO: This should probably be done twice, once for the NH for Z0-6, once for >45° for Z7+.
  log Reprojecting land polygons to $PROJECTION
  psql_cmd -f $PROJECTION/reproject_land_polygons.sql

  log 'Calculate required resolutions (TODO)'
  #>>> [(2**0.5)*6371007.2 / (512 * 2**i) for i in range(14)]

  #[17597.587476985624, 8798.793738492812, 4399.396869246406, 2199.698434623203, 1099.8492173116015, 549.9246086558007, 274.96230432790037, 137.48115216395018, 68.74057608197509, 34.370288040987546, 17.185144020493773, 8.592572010246887, 4.296286005123443, 2.1481430025617216]

  #[16000, 8000, 4000, 2000, 1000, 500, 200, 100, 50, 25, 15, 8, 4, 2]

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
  #   Split land polygons zoom 6
  split_in_parallel  6 200 40000

  # These zooms are clipped to 45°N.  This method seemed slow…
  #   Split land polygons zoom 7
  #split_in_parallel  7 100 10000
  #   Split land polygons zoom 8
  #split_in_parallel  8  50  2500
  #   Split land polygons zoom 9 to an 8-grid
  #split_in_parallel_grid8  9  25   400
  #   Split land polygons zoom 10 to an 8-grid
  #split_in_parallel_grid8 10  15   100
  #   Split land polygons zoom 11 to an 8-grid
  #split_in_parallel_grid8 11   8    25
  # …so just do zoom 14, and then simplify those land polygons.
  # TODO: Does this cause problems simplifying things close to tile boundaries?
  #   Split land polygons zoom 14 to an 8-grid
  split_in_parallel_grid8 14   0     0

  # …simplify those land polygons
  simplify_land_polygon_tiles 13    2     6
  simplify_land_polygon_tiles 12    4    12
  simplify_land_polygon_tiles 11    8    25
  simplify_land_polygon_tiles 10   15   100
  simplify_land_polygon_tiles  9   25   400
  simplify_land_polygon_tiles  8   50  2500
  simplify_land_polygon_tiles  7  100 10000

  psql_cmd -v zoom=14 -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=13 -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=12 -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=11 -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=10 -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=9  -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=8  -f 3575/create_water_polygons_grid8.sql -q &
  psql_cmd -v zoom=7  -f 3575/create_water_polygons_grid8.sql -q &
  wait

  psql_cmd -f $PROJECTION/create_water_polygons.sql

  create_missing_water_tiles_grid8 14
  create_missing_water_tiles_grid8 13
  create_missing_water_tiles_grid8 12
  create_missing_water_tiles_grid8 11
  create_missing_water_tiles_grid8 10
  create_missing_water_tiles_grid8 9
  create_missing_water_tiles_grid8 8
  create_missing_water_tiles_grid8 7
}

function split_in_parallel() {
  zoom=$1
  tol=$2
  area=$3

  maxTile=$(( 2**$zoom - 1))

  log Split land polygons zoom $zoom using $cpus parallel processes
  # Width of the map in tiles
  w=$(( 2**$zoom ))
  maxTile=$(( $w - 1 ))
  minTile=0
  # Decimal radius in map tiles of the Equator, squared.
  pp=$(( 2**($zoom-1) * 2**($zoom-1) ))
  for xb in `seq $minTile $cpus $maxTile`; do
    for y in `seq $minTile 1025`; do
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
            sleep 0.5
          done
        #else
        #  log "Zoom $zoom column $x row $y not in northern hemisphere" " $xnp \* $xnp + $ynp \* $ynp =" $(( $xnp * $xnp + $ynp * $ynp ))
        fi
      done
    done
  done
  wait
}

function split_in_parallel_grid8() {
  zoom=$1
  tol=$2
  area=$3

  log Split land polygons zoom $zoom '(8-grid)' using $cpus parallel processes
  # Width of the map in tiles
  w=256
  # Decimal radius in map tiles of the 45° parallel, squared.
  # select ST_asewkt( ST_Transform(ST_GeomFromEWKT('SRID=4326;POINT(10 45)'), 3575) );
  # SRID=3575;POINT(-1.3570630183354e-10 -4889334.80295488)
  # select ST_asewkt( ST_Transform(ST_GeomFromEWKT('SRID=4326;POINT(10 -89.99999999)'), 3575) );
  # SRID=3575;POINT(-3.53661943115395e-10 -12742014.3618369)
  # select zoom, x, y from bbox_tiles_3575 where geometry && ST_Transform(ST_GeomFromEWKT('SRID=4326;POINT(10 45)'), 3575) order by zoom;
  #pp=$(( ((4889334.80/9009964.76)*(2**(zoom-1)))**2 ))
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
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v grid=8 -v x=$x -v y=$y -f $PROJECTION/split_land_polygons_by_column_and_row_higher_grid.sql -q &
          while [[ $(jobs | wc -l) -ge $cpusminusone ]]; do
            sleep 0.5
          done
        #else
        #  log "Zoom $zoom (8-grid) column $x row $y not in northern 45°"
        fi
      done
    done
  done
  wait
}

function simplify_land_polygon_tiles() {
  zoom=$1
  tol=$2
  area=$3

  log Simplify land polygon tiles zoom $zoom '(8-grid)' using $cpus parallel processes
  # Width of the map in tiles
  w=256
  # Decimal radius in map tiles of the 45° parallel, squared.
  #pp=$(( ((4889334.80/9009964.76)*(2**(zoom-1)))**2 ))
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
          psql_cmd -v tolerance=$tol -v min_area=$area -v zoom=$zoom -v x=$x -v y=$y -f $PROJECTION/simplify_land_polygon_tiles.sql -q &
          while [[ $(jobs | wc -l) -ge $cpusminusone ]]; do
            sleep 0.5
          done
        #else
        #  log "Zoom $zoom (8-grid) column $x row $y not in northern 45°"
        fi
      done
    done
  done
  wait
}

function create_missing_water_tiles_grid8() {
  zoom=$1
  tol=$2
  area=$3

  log Create missing water zoom $zoom '(8-grid)' using $cpus parallel processes
  # Width of the map in tiles
  w=256
  # Decimal radius in map tiles of the 45° parallel, squared.
  #pp=$(( ((4889334.80/9009964.76)*(2**(zoom-1)))**2 ))
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
          psql_cmd -v zoom=$zoom -v x=$x -v y=$y -f $PROJECTION/create_missing_water_tiles_grid8.sql -q &
          while [[ $(jobs | wc -l) -ge $cpusminusone ]]; do
            sleep 0.5
          done
        #else
        #  log "Zoom $zoom (8-grid) column $x row $y not in northern 45°"
        fi
      done
    done
  done
  wait
}

download

generate_water_tiles
