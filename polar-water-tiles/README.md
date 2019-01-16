Generating Water Tiles from Open Street Map
===========================================

OpenStreetMap records the coastline boundary as a very large polygon for each continent and island.  This is slow to work with at low zooms.

The OpenMapTiles process uses pre-split tiles from OpenStreetMapData.com, in 3857 projection.  For 4326 projection, OpenStreetMapData.com provide an alternative download.

However, when using either download in polar projections (3575, 3031) empty triangles appear where the data was split into tiles.

It's therefore necessary to reproject the coastline polygons before splitting them into tiles.  This project does this operation.

It creates a reprojected, simplified and split output for use at zooms 0-3 and 4-6.  For higher zooms, the reprojected data (without simplification or splitting) can be used.

Steps
#####

(For running independently, this is normally integrated into an OpenMapTiles project.)

- Start the Postgres database

```
docker-compose up -d postgres
```

- Import, reproject and split the data.  This will take a while (hours).

```
docker-compose run import
```

- Preview the output

```
docker-compose run preview
```

Look at http://localhost:8080/index_3575.html and http://localhost:8080/index_3031.html.

**Use these Docker modules within an OpenMapTiles project.** (Nothing has been written to export the data.)
