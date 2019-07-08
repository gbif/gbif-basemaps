# Process to create GBIF basemaps

This is adapted from the [OpenMapTiles](https://openmaptiles.org) process

* Import source data into a PostGIS database
* Process that data, e.g. simplify and reproject
* Build the SQL views and functions for the chosen tile schema

Usual use of OpenMapTiles would then be to generate the map for the
small area, but we want to generate a map for the whole world.  This
part of OpenMapTiles' process isn't open source.

We use `postserve` (vector tiles generated directly by PostGIS) plus
a custom messaging system to generate all the required tiles, and
another program to collect them into a MBTiles (SQLite) database.

## 1. Infrastructure

* Set up Docker and Docker-compose, with suitable storage space on fast discs.
* For generating the world's tiles, many CPUs are easiest.
* Alternatively, the database could be duplicated across several servers.

## 2. Set up and import data

1. Clone the [gbif/openmaptiles](https://github.com/gbif/openmaptiles/) repository.

2. In the file .env, set `PROJECTION=3575` to the required projection.

3. Roughly follow the import steps in the README:
   `make` using the Docker command

4. Bring up postgres

5. `import-polar-water`; this takes about 2 hours on merlin.  Or, import the tables generated from an earlier run.
   Or, `import-water` for 4326 projection.

   `import-polar-landcover`; (not yet timed), needed for OSM-based zoom levels.  Only necessary for polar projections.

6. `import-natural-earth`, `import-lakelines`

7. Set `PROJECTION=4326` in .env and `import-osmborder`.  Infrequently, the border should be regenerated from a newer OSM export, see the project.  Revert `PROJECTION=3575` if necessary.

8. Download a planet (the German mirror is extremely fast), `import-osm`.

9. Run the usual `import-sql`

10. Run the SQL scripts to make the extra functions and views needed for the 3575 projection.  These are in `layers_3575` in `openmaptiles`.

11. Run `postserve` and check the result is acceptable — check all zoom levels, and different areas: the Sahara, coastlines, around the equator, projection extent corners, cities.

## 3. Generate the tiles

Tile generation is coordinate by RabbitMQ message queues.

1. One process creates messages for the tiles needed (zoom, column and row).

2. A set of `postserve` containers listen to this queue, and generate the required tiles, sending them to another queue, or to a failure queue if they break.

3. A third process receives the finished tiles and inserts them into an MBTiles database.

The programs for 1. and 3. are in this repository, under `tile-generation-tools`.

Set environment variables in `.env` to give this map queue names:

```
MQ_HOST=mq.gbif.org
MQ_USERNAME=XX
MQ_PASSWORD=XX
MQ_VHOST=/users/XX
MQ_PENDING=pending-4326
MQ_DONE=done-4326
MQ_FAILED=failed-4326
```

1. Generate messages for the zoom levels required:

```
docker-compose run queue-tiles 0 1 2 3 4
```

2. Run `postserve` (TODO; the queue.py script needs to be run.)

3. Pull the tiles from RabbitMQ into an MBTiles database:

```
docker-compose run tiles-to-database --database /output/out.test --create
```

   (Press ^C to end this; the final batch of tiles will then be written and the program exits.)

## 4. View the tiles

```
docker run --rm -it -v $(pwd)/data:/data --publish 8181:80 mb.gbif.org:5000/tileserver-gl-light
```
