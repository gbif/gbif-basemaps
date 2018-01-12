-- ======================================================================
--
-- Set up helper table with polygons containing the bbox for each tile
--
-- Call like this:
-- psql -d coastlines -v zoom=$ZOOM -f setup_bbox_tiles.sql
--
-- for instance:
-- psql -d coastlines -v zoom=3 -f setup_bbox_tiles.sql
--
-- ======================================================================

-- max value for x or y coordinate in 3575 (Northern Hemisphere extent)
\set cmax (2 ^ 0.5) * 6371007.2
\set pow (2.0 ^ :zoom)::integer
\set tilesize (2*:cmax / :pow)

CREATE VIEW tiles_3575 AS SELECT * FROM generate_series(0, :pow - 1) AS x, generate_series(0, :pow - 1) AS y;
CREATE VIEW bbox_3575 AS SELECT :zoom AS zoom, x, y, x*:tilesize - :cmax AS x1, (:pow - y - 1)*:tilesize - :cmax AS y1, (x+1)*:tilesize - :cmax AS x2, (:pow - y)*:tilesize - :cmax AS y2 FROM tiles_3575;

INSERT INTO bbox_tiles_3575 (zoom, x, y, geom)
    SELECT zoom, x, y, ST_SetSRID(ST_MakeBox2D(ST_MakePoint(x1, y1), ST_MakePoint(x2, y2)), 3575) AS geom
        FROM bbox_3575;

DROP VIEW bbox_3575;
DROP VIEW tiles_3575;
