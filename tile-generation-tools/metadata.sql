BEGIN TRANSACTION;
delete from metadata;
insert into metadata ("name", "value") values ('name', 'osm2vectortiles');
insert into metadata ("name", "value") values ('type', 'baselayer');
insert into metadata ("name", "value") values ('version', '2.0');
insert into metadata ("name", "value") values ('description', 'descr');
insert into metadata ("name", "value") values ('format', 'pbf');
insert into metadata ("name", "value") values ('json', '{}');
insert into metadata ("name", "value") values ('id', 'osm2vectortiles');
insert into metadata ("name", "value") values ('mtime', '1463000999999');
insert into metadata ("name", "value") values ('scheme', 'tms');
insert into metadata ("name", "value") values ('maskLevel', '8');
insert into metadata ("name", "value") values ('minZoom', '0');
insert into metadata ("name", "value") values ('maxZoom', '5');
insert into metadata ("name", "value") values ('bounds', '-180,-85.0511,180,85.0511');
insert into metadata ("name", "value") values ('attribution', 'attrib');
insert into metadata ("name", "value") values ('filesize', '12341234');
insert into metadata ("name", "value") values ('basename', 'admin.mbtiles');
insert into metadata ("name", "value") values ('center', '0.0,0.0,2');
COMMIT;
