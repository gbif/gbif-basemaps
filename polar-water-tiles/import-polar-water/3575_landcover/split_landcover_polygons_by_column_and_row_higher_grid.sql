-- ======================================================================
--
-- Split landcover polygons into tiles
--
-- This can either split non-simplified landcover polygons or simplified landcover
-- polygons. Set tolerance=0 and min_area=0 to use non-simplified landcover
-- polygons, otherwise the simplified polygons with the given parameters
-- are used.
--
-- Call like this:
-- psql -d $DB -v tolerance=$TOLERANCE -v min_area=$MIN_AREA -v zoom=$ZOOM -f split_landcover_polygons.sql
--
-- for instance:
-- psql -d coastlines -v tolerance=300 -v min_area=300000 -v zoom=3 -f split_landcover_polygons.sql
--
-- ======================================================================

-- Only one of the following INSERT statements will do anything thanks to the
-- last condition (:tolerance (!)=0).

-- case 1: split non-simplified polygons
INSERT INTO split_landcover_polygons_3575 (id, osm_id, landuse, leisure, "natural", wetland, tolerance, min_area, zoom, x, y, geometry)
    SELECT p.id, p.osm_id, p.landuse, p.leisure, p.natural, p.wetland, 0, 0, :zoom, b.x, b.y, ST_Multi(ST_Intersection(p.geometry, b.geometry))
        FROM osm_landcover_polygons_3575 p, bbox_tiles_3575 b
        WHERE p.geometry && b.geometry
          AND ST_Intersects(p.geometry, b.geometry)
          AND b.zoom=:grid
          AND ST_GeometryType(ST_Multi(ST_Intersection(p.geometry, b.geometry))) = 'ST_MultiPolygon'
          AND :tolerance=0
          AND b.x=:x
          AND b.y=:y;

-- case 2: split simplified polygons
INSERT INTO split_landcover_polygons_3575 (id, osm_id, landuse, leisure, "natural", wetland, tolerance, min_area, zoom, x, y, geometry)
    SELECT p.id, p.osm_id, p.landuse, p.leisure, p.natural, p.wetland, p.tolerance, p.min_area, :zoom, b.x, b.y, ST_Multi(ST_Intersection(ST_MakeValid(p.geometry), b.geometry))
        FROM simplified_landcover_polygons_3575 p, bbox_tiles_3575 b
        WHERE p.geometry && b.geometry
          AND ST_Intersects(p.geometry, b.geometry)
          AND p.tolerance=:tolerance
          AND p.min_area=:min_area
          AND b.zoom=:grid
          AND ST_GeometryType(ST_Multi(ST_Intersection(ST_MakeValid(p.geometry), b.geometry))) = 'ST_MultiPolygon'
          AND :tolerance!=0
          AND b.x=:x
          AND b.y=:y
          AND NOT EXISTS (SELECT * FROM split_landcover_polygons_3575 s WHERE s.zoom = :zoom AND s.x = :x AND s.y = :y)
          AND EXISTS (SELECT * FROM split_land_polygons_3575 t WHERE t.zoom = :grid AND t.x = :x AND t.y = :y);
