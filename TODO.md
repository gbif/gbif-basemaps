Tasks for base maps:

- Generate contours and basyometry layers

- Hide outside-projection circle on polar projections

# Regenerate all with with additional layers
-- Need to get postgis vector tile generation working
-- previously, failed because tolerances were wrong
-- try just importing a single layer (border)

# Time of steps on my desktop:

import-water: 4 minutes
import-natural-earth: <2 minutes
import-lakelines: <10 seconds
import-osmborder: <6 minutes
import-osm (Norway): 14 minutes?
import-sql: 4 minutes

# Tiles are too big, should be 10-50kB for most zooms, up to 150kB for Z14.
# But ours are 512px, so 40-200kB for most zooms, up to 600kB for Z14.

Tile size 256 × 0.00028px/m = tiles on screen are 0.07168m (72mm)

Zoom level 7, Mercator, tile size 256:
128 × 256 pixels to cover 40075km at Equator
128 × 256 pixels to cover 128 × 0.07168m = 9.17504 m of map (map is 9 metres wide)
So scale of map is 1 : 2.28947e-07

3px for a minimum length, = 6.8684e-07


Resolution 0.000114984 px/metre
Pixel size 0.00028m (0.28mm)
0.000114984 px/m ÷ 0.00028m/px = 0.410657

zres(zoom) → 40075016.6855785/((1.0*pixel_scale)*2**zoom)

###########################
# GBIF Maps Build Process #
###########################

1. clone gbif/openmaptiles
2. clone and docker build all the GBIF forks
3. bring it all up

15:28:58 openmaptiles@clickhouse-vh.~ =# SELECT osm_id, name, subclass, ST_AsText(geometry) FROM osm_poi_polygon WHERE geometry = '0101000020E6100000000000000000F87F000000000000F87F' limit 1000;
  osm_id   │                name                │     subclass     │  st_astext
───────────┼────────────────────────────────────┼──────────────────┼─────────────
 342749999 │                                    │ park             │ POINT EMPTY
  -2178442 │ Московский Яхтенный Порт           │ marina           │ POINT EMPTY

→ DELETE FROM osm_poi_polygon WHERE geometry = '0101000020E6100000000000000000F87F000000000000F87F';

Ditto:
→ DELETE FROM osm_water_polygon WHERE geometry = '0101000020E6100000000000000000F87F000000000000F87F';

# Finalizing the SQLite database

sqlite3 -csv 4326_13-14.mbtiles 'select count(*), zoom_level from tiles group by zoom_level' -column -header

Then see if things are missing, and it's usually easiest to delete whole columns and regenerate them.

./set-metadata *.mbtiles
(TODO: Set it properly.)
