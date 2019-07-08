OB-- ======================================================================
-- Setup tables
-- ======================================================================

CREATE TABLE simplified_landcover_polygons_3575 (
    id        SERIAL,
    osm_id    BIGINT,
    landuse   varchar(32),
    leisure   varchar(32),
    "natural" varchar(32),
    wetland   varchar(32),
    area      DOUBLE PRECISION,
    tolerance INT,
    min_area  INT
);

SELECT AddGeometryColumn('simplified_landcover_polygons_3575', 'geometry', 3575, 'MULTIPOLYGON', 2);


CREATE TABLE split_landcover_polygons_3575 (
    id        SERIAL,
    osm_id    BIGINT,
    landuse   varchar(32),
    leisure   varchar(32),
    "natural" varchar(32),
    wetland   varchar(32),
    area      DOUBLE PRECISION,
    tolerance INT,
    min_area  INT,
    zoom      INT,
    x         INT,
    y         INT
);

-- splitting can make multipolygons out of polygons, so geometry type is different
SELECT AddGeometryColumn('split_landcover_polygons_3575', 'geometry', 3575, 'MULTIPOLYGON', 2);


-- CREATE TABLE bbox_tiles_3575 (
--     id        SERIAL,
--     zoom      INT,
--     x         INT,
--     y         INT
-- );

-- SELECT AddGeometryColumn('bbox_tiles_3575', 'geometry', 3575, 'POLYGON', 2);

-- CREATE INDEX idx_bbox_files_geom_3575 ON bbox_tiles_3575 USING GIST (geometry);
