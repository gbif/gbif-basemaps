-- ======================================================================
-- Setup tables
-- ======================================================================

CREATE TABLE simplified_land_polygons_3575 (
    id        SERIAL,
    fid       INT,
    tolerance INT,
    min_area  INT
);

SELECT AddGeometryColumn('simplified_land_polygons_3575', 'geom', 3575, 'POLYGON', 2);


CREATE TABLE split_land_polygons_3575 (
    id        SERIAL,
    fid       INT,
    tolerance INT,
    min_area  INT,
    zoom      INT,
    x         INT,
    y         INT
);

-- splitting can make multipolygons out of polygons, so geometry type is different
SELECT AddGeometryColumn('split_land_polygons_3575', 'geom', 3575, 'MULTIPOLYGON', 2);


CREATE TABLE split_water_polygons_3575 (
    id        SERIAL,
    tolerance INT,
    min_area  INT,
    zoom      INT,
    x         INT,
    y         INT
);

SELECT AddGeometryColumn('split_water_polygons_3575', 'geom', 3575, 'MULTIPOLYGON', 2);


CREATE TABLE bbox_tiles_3575 (
    id        SERIAL,
    zoom      INT,
    x         INT,
    y         INT
);

SELECT AddGeometryColumn('bbox_tiles_3575', 'geom', 3575, 'POLYGON', 2);

CREATE INDEX idx_bbox_files_geom_3575 ON bbox_tiles_3575 USING GIST (geom);
