-- ======================================================================
--
-- Simplify landcover polygons
--
-- Parameters:
--   tolerance: Tolerance for simplification algorithm, higher values
--              mean more simplification
--   min_area:  Polygons with smaller area than this will not appear
--              in the output
--
-- Call like this:
-- psql -d $DB -v tolerance=$TOLERANCE -v min_area=$MIN_AREA -f simplify_landcover_polygons.sql
--
-- for instance:
-- psql -d coastlines -v tolerance=300 -v min_area=300000 -f simplify_landcover_polygons.sql
--
-- ======================================================================

INSERT INTO simplified_landcover_polygons_3575 (id, osm_id, landuse, leisure, "natural", wetland, tolerance, min_area, geometry)
    SELECT id, osm_id, landuse, leisure, "natural", wetland, :tolerance, :min_area, ST_Multi(ST_SimplifyPreserveTopology(geometry, :tolerance))
        FROM osm_landcover_polygons_3575
        WHERE ST_Area(geometry) > :min_area;

CREATE INDEX
    ON simplified_landcover_polygons_3575
    USING GIST (geometry)
    WHERE tolerance=:tolerance AND min_area=:min_area;
