-- ======================================================================
-- Create water polygons
--
-- Creates split water polygons from all split land polygons.
--
-- Call like this:
-- psql -d coastlines -f create_water_polygons.sql
--
-- ======================================================================

-- This is a helper view that makes the following INSERT easier to write.
-- For every tile this view contains the union of all land polygons in that tile.
CREATE VIEW merged_land_polygons_3575 AS
    SELECT tolerance, min_area, zoom, x, y, ST_Union(geometry) AS geometry
        FROM split_land_polygons_3575 p
        GROUP BY tolerance, min_area, zoom, x, y;

INSERT INTO split_water_polygons_3575 (tolerance, min_area, zoom, x, y, geometry)
    SELECT p.tolerance, p.min_area, p.zoom, p.x, p.y, ST_Multi( ST_CollectionExtract((ST_Dump( ST_Difference( ST_Intersection(ST_Transform(ST_GeomFromEWKT('SRID=4326;POLYGON((-180 0,180 0,178 0,176 0,174 0,172 0,170 0,168 0,166 0,164 0,162 0,160 0,158 0,156 0,154 0,152 0,150 0,148 0,146 0,144 0,142 0,140 0,138 0,136 0,134 0,132 0,130 0,128 0,126 0,124 0,122 0,120 0,118 0,116 0,114 0,112 0,110 0,108 0,106 0,104 0,102 0,100 0,98 0,96 0,94 0,92 0,90 0,88 0,86 0,84 0,82 0,80 0,78 0,76 0,74 0,72 0,70 0,68 0,66 0,64 0,62 0,60 0,58 0,56 0,54 0,52 0,50 0,48 0,46 0,44 0,42 0,40 0,38 0,36 0,34 0,32 0,30 0,28 0,26 0,24 0,22 0,20 0,18 0,16 0,14 0,12 0,10 0,8 0,6 0,4 0,2 0,0 0,-2 0,-4 0,-6 0,-8 0,-10 0,-12 0,-14 0,-16 0,-18 0,-20 0,-22 0,-24 0,-26 0,-28 0,-30 0,-32 0,-34 0,-36 0,-38 0,-40 0,-42 0,-44 0,-46 0,-48 0,-50 0,-52 0,-54 0,-56 0,-58 0,-60 0,-62 0,-64 0,-66 0,-68 0,-70 0,-72 0,-74 0,-76 0,-78 0,-80 0,-82 0,-84 0,-86 0,-88 0,-90 0,-92 0,-94 0,-96 0,-98 0,-100 0,-102 0,-104 0,-106 0,-108 0,-110 0,-112 0,-114 0,-116 0,-118 0,-120 0,-122 0,-124 0,-126 0,-128 0,-130 0,-132 0,-134 0,-136 0,-138 0,-140 0,-142 0,-144 0,-146 0,-148 0,-150 0,-152 0,-154 0,-156 0,-158 0,-160 0,-162 0,-164 0,-166 0,-168 0,-170 0,-172 0,-174 0,-176 0,-178 0,-180 0))'), 3575), b.geometry), p.geometry))).geom, 3))

        FROM merged_land_polygons_3575 p, bbox_tiles_3575 b
        WHERE p.zoom = b.zoom
          AND p.x = b.x
          AND p.y = b.y;

-- If there are no land polygons in a tile, no water polygon will be created for it.
-- This INSERT adds the water polygons in that case.
INSERT INTO split_water_polygons_3575 (tolerance, min_area, zoom, x, y, geometry)
    SELECT p.tolerance, p.min_area, b.zoom, x, y, ST_Multi( ST_CollectionExtract((ST_Dump( ST_Intersection(ST_Transform(ST_GeomFromEWKT('SRID=4326;POLYGON((-180 0,180 0,178 0,176 0,174 0,172 0,170 0,168 0,166 0,164 0,162 0,160 0,158 0,156 0,154 0,152 0,150 0,148 0,146 0,144 0,142 0,140 0,138 0,136 0,134 0,132 0,130 0,128 0,126 0,124 0,122 0,120 0,118 0,116 0,114 0,112 0,110 0,108 0,106 0,104 0,102 0,100 0,98 0,96 0,94 0,92 0,90 0,88 0,86 0,84 0,82 0,80 0,78 0,76 0,74 0,72 0,70 0,68 0,66 0,64 0,62 0,60 0,58 0,56 0,54 0,52 0,50 0,48 0,46 0,44 0,42 0,40 0,38 0,36 0,34 0,32 0,30 0,28 0,26 0,24 0,22 0,20 0,18 0,16 0,14 0,12 0,10 0,8 0,6 0,4 0,2 0,0 0,-2 0,-4 0,-6 0,-8 0,-10 0,-12 0,-14 0,-16 0,-18 0,-20 0,-22 0,-24 0,-26 0,-28 0,-30 0,-32 0,-34 0,-36 0,-38 0,-40 0,-42 0,-44 0,-46 0,-48 0,-50 0,-52 0,-54 0,-56 0,-58 0,-60 0,-62 0,-64 0,-66 0,-68 0,-70 0,-72 0,-74 0,-76 0,-78 0,-80 0,-82 0,-84 0,-86 0,-88 0,-90 0,-92 0,-94 0,-96 0,-98 0,-100 0,-102 0,-104 0,-106 0,-108 0,-110 0,-112 0,-114 0,-116 0,-118 0,-120 0,-122 0,-124 0,-126 0,-128 0,-130 0,-132 0,-134 0,-136 0,-138 0,-140 0,-142 0,-144 0,-146 0,-148 0,-150 0,-152 0,-154 0,-156 0,-158 0,-160 0,-162 0,-164 0,-166 0,-168 0,-170 0,-172 0,-174 0,-176 0,-178 0,-180 0))'), 3575), geometry))).geom, 3))
        FROM bbox_tiles_3575 b, (SELECT distinct tolerance, min_area, zoom from split_land_polygons_3575) p
        WHERE b.zoom=p.zoom
          AND x || '-' || y || '-' || b.zoom NOT IN (SELECT x || '-' || y || '-' || zoom FROM split_land_polygons_3575);

DROP VIEW merged_land_polygons_3575;

CREATE INDEX split_water_polygons_3575_idx
    ON split_water_polygons_3575
    USING GIST (geometry);
