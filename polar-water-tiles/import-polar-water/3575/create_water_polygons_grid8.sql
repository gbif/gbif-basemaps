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

DELETE FROM split_water_polygons_3575 WHERE zoom = 1000+:zoom;
INSERT INTO split_water_polygons_3575 (tolerance, min_area, zoom, x, y, geometry)
    SELECT p.tolerance, p.min_area, p.zoom, p.x, p.y, ST_Multi( ST_CollectionExtract((ST_Dump( ST_Difference( ST_Intersection(ST_Transform(ST_GeomFromEWKT('SRID=4326;POLYGON((-180 45,180 45,178 45,176 45,174 45,172 45,170 45,168 45,166 45,164 45,162 45,160 45,158 45,156 45,154 45,152 45,150 45,148 45,146 45,144 45,142 45,140 45,138 45,136 45,134 45,132 45,130 45,128 45,126 45,124 45,122 45,120 45,118 45,116 45,114 45,112 45,110 45,108 45,106 45,104 45,102 45,100 45,98 45,96 45,94 45,92 45,90 45,88 45,86 45,84 45,82 45,80 45,78 45,76 45,74 45,72 45,70 45,68 45,66 45,64 45,62 45,60 45,58 45,56 45,54 45,52 45,50 45,48 45,46 45,44 45,42 45,40 45,38 45,36 45,34 45,32 45,30 45,28 45,26 45,24 45,22 45,20 45,18 45,16 45,14 45,12 45,10 45,8 45,6 45,4 45,2 45,0 45,-2 45,-4 45,-6 45,-8 45,-10 45,-12 45,-14 45,-16 45,-18 45,-20 45,-22 45,-24 45,-26 45,-28 45,-30 45,-32 45,-34 45,-36 45,-38 45,-40 45,-42 45,-44 45,-46 45,-48 45,-50 45,-52 45,-54 45,-56 45,-58 45,-60 45,-62 45,-64 45,-66 45,-68 45,-70 45,-72 45,-74 45,-76 45,-78 45,-80 45,-82 45,-84 45,-86 45,-88 45,-90 45,-92 45,-94 45,-96 45,-98 45,-100 45,-102 45,-104 45,-106 45,-108 45,-110 45,-112 45,-114 45,-116 45,-118 45,-120 45,-122 45,-124 45,-126 45,-128 45,-130 45,-132 45,-134 45,-136 45,-138 45,-140 45,-142 45,-144 45,-146 45,-148 45,-150 45,-152 45,-154 45,-156 45,-158 45,-160 45,-162 45,-164 45,-166 45,-168 45,-170 45,-172 45,-174 45,-176 45,-178 45,-180 45))'), 3575), b.geometry), p.geometry))).geom, 3))

        FROM merged_land_polygons_3575 p, bbox_tiles_3575 b
        WHERE p.zoom = 1000+:zoom AND b.zoom = 8
          AND p.x = b.x
          AND p.y = b.y;

-- If there are no land polygons in a tile, no water polygon will be created for it.
-- This INSERT adds the water polygons in that case.
--INSERT INTO split_water_polygons_3575 (tolerance, min_area, zoom, x, y, geometry)
--    SELECT p.tolerance, p.min_area, b.zoom, x, y, ST_Multi( ST_CollectionExtract((ST_Dump( ST_Intersection(ST_Transform(ST_GeomFromEWKT('SRID=4326;POLYGON((-180 45,180 45,178 45,176 45,174 45,172 45,170 45,168 45,166 45,164 45,162 45,160 45,158 45,156 45,154 45,152 45,150 45,148 45,146 45,144 45,142 45,140 45,138 45,136 45,134 45,132 45,130 45,128 45,126 45,124 45,122 45,120 45,118 45,116 45,114 45,112 45,110 45,108 45,106 45,104 45,102 45,100 45,98 45,96 45,94 45,92 45,90 45,88 45,86 45,84 45,82 45,80 45,78 45,76 45,74 45,72 45,70 45,68 45,66 45,64 45,62 45,60 45,58 45,56 45,54 45,52 45,50 45,48 45,46 45,44 45,42 45,40 45,38 45,36 45,34 45,32 45,30 45,28 45,26 45,24 45,22 45,20 45,18 45,16 45,14 45,12 45,10 45,8 45,6 45,4 45,2 45,0 45,-2 45,-4 45,-6 45,-8 45,-10 45,-12 45,-14 45,-16 45,-18 45,-20 45,-22 45,-24 45,-26 45,-28 45,-30 45,-32 45,-34 45,-36 45,-38 45,-40 45,-42 45,-44 45,-46 45,-48 45,-50 45,-52 45,-54 45,-56 45,-58 45,-60 45,-62 45,-64 45,-66 45,-68 45,-70 45,-72 45,-74 45,-76 45,-78 45,-80 45,-82 45,-84 45,-86 45,-88 45,-90 45,-92 45,-94 45,-96 45,-98 45,-100 45,-102 45,-104 45,-106 45,-108 45,-110 45,-112 45,-114 45,-116 45,-118 45,-120 45,-122 45,-124 45,-126 45,-128 45,-130 45,-132 45,-134 45,-136 45,-138 45,-140 45,-142 45,-144 45,-146 45,-148 45,-150 45,-152 45,-154 45,-156 45,-158 45,-160 45,-162 45,-164 45,-166 45,-168 45,-170 45,-172 45,-174 45,-176 45,-178 45,-180 45))'), 3575), geometry))).geom, 3))
--        FROM bbox_tiles_3575 b, (SELECT distinct tolerance, min_area, zoom from split_land_polygons_3575) p
--       WHERE p.zoom = 1011 AND b.zoom = 8
--          AND x || '-' || y || '-' || b.zoom NOT IN (SELECT x || '-' || y || '-' || zoom FROM split_land_polygons_3575);

--DROP VIEW merged_land_polygons_3575;

--CREATE INDEX
--    ON split_water_polygons_3575
--    USING GIST (geometry);
