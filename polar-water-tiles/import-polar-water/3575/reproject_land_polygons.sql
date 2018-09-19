-- ======================================================================
--
-- Reproject land polygons
--
-- ======================================================================

CREATE TABLE osm_land_polygons_3575 AS
    SELECT fid, ST_Area(geometry), geometry
        FROM (SELECT fid, (ST_Dump(ST_Transform(ST_Intersection(ST_GeomFromEWKT('SRID=4326;POLYGON((-180 0,-180 90,180 90,180 0,179 0,178 0,177 0,176 0,175 0,174 0,173 0,172 0,171 0,170 0,169 0,168 0,167 0,166 0,165 0,164 0,163 0,162 0,161 0,160 0,159 0,158 0,157 0,156 0,155 0,154 0,153 0,152 0,151 0,150 0,149 0,148 0,147 0,146 0,145 0,144 0,143 0,142 0,141 0,140 0,139 0,138 0,137 0,136 0,135 0,134 0,133 0,132 0,131 0,130 0,129 0,128 0,127 0,126 0,125 0,124 0,123 0,122 0,121 0,120 0,119 0,118 0,117 0,116 0,115 0,114 0,113 0,112 0,111 0,110 0,109 0,108 0,107 0,106 0,105 0,104 0,103 0,102 0,101 0,100 0,99 0,98 0,97 0,96 0,95 0,94 0,93 0,92 0,91 0,90 0,89 0,88 0,87 0,86 0,85 0,84 0,83 0,82 0,81 0,80 0,79 0,78 0,77 0,76 0,75 0,74 0,73 0,72 0,71 0,70 0,69 0,68 0,67 0,66 0,65 0,64 0,63 0,62 0,61 0,60 0,59 0,58 0,57 0,56 0,55 0,54 0,53 0,52 0,51 0,50 0,49 0,48 0,47 0,46 0,45 0,44 0,43 0,42 0,41 0,40 0,39 0,38 0,37 0,36 0,35 0,34 0,33 0,32 0,31 0,30 0,29 0,28 0,27 0,26 0,25 0,24 0,23 0,22 0,21 0,20 0,19 0,18 0,17 0,16 0,15 0,14 0,13 0,12 0,11 0,10 0,9 0,8 0,7 0,6 0,5 0,4 0,3 0,2 0,1 0,0 0,-1 0,-2 0,-3 0,-4 0,-5 0,-6 0,-7 0,-8 0,-9 0,-10 0,-11 0,-12 0,-13 0,-14 0,-15 0,-16 0,-17 0,-18 0,-19 0,-20 0,-21 0,-22 0,-23 0,-24 0,-25 0,-26 0,-27 0,-28 0,-29 0,-30 0,-31 0,-32 0,-33 0,-34 0,-35 0,-36 0,-37 0,-38 0,-39 0,-40 0,-41 0,-42 0,-43 0,-44 0,-45 0,-46 0,-47 0,-48 0,-49 0,-50 0,-51 0,-52 0,-53 0,-54 0,-55 0,-56 0,-57 0,-58 0,-59 0,-60 0,-61 0,-62 0,-63 0,-64 0,-65 0,-66 0,-67 0,-68 0,-69 0,-70 0,-71 0,-72 0,-73 0,-74 0,-75 0,-76 0,-77 0,-78 0,-79 0,-80 0,-81 0,-82 0,-83 0,-84 0,-85 0,-86 0,-87 0,-88 0,-89 0,-90 0,-91 0,-92 0,-93 0,-94 0,-95 0,-96 0,-97 0,-98 0,-99 0,-100 0,-101 0,-102 0,-103 0,-104 0,-105 0,-106 0,-107 0,-108 0,-109 0,-110 0,-111 0,-112 0,-113 0,-114 0,-115 0,-116 0,-117 0,-118 0,-119 0,-120 0,-121 0,-122 0,-123 0,-124 0,-125 0,-126 0,-127 0,-128 0,-129 0,-130 0,-131 0,-132 0,-133 0,-134 0,-135 0,-136 0,-137 0,-138 0,-139 0,-140 0,-141 0,-142 0,-143 0,-144 0,-145 0,-146 0,-147 0,-148 0,-149 0,-150 0,-151 0,-152 0,-153 0,-154 0,-155 0,-156 0,-157 0,-158 0,-159 0,-160 0,-161 0,-162 0,-163 0,-164 0,-165 0,-166 0,-167 0,-168 0,-169 0,-170 0,-171 0,-172 0,-173 0,-174 0,-175 0,-176 0,-177 0,-178 0,-179 0,-180 0))'), geometry), 3575))).geom AS geometry FROM osm_land_polygons_4326) AS x;

CREATE INDEX
    ON osm_land_polygons_3575
    USING GIST (geometry);