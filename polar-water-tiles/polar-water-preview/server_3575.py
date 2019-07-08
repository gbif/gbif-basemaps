import tornado.ioloop
import tornado.web
import tornado.httpserver
import io
import os

from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy import create_engine
from sqlalchemy import inspect
from sqlalchemy import text
from sqlalchemy.orm import sessionmaker

import mercantile
import pyproj
import yaml
import sys
import itertools
import re

def GetTM2Source(file):
    with open(file,'r') as stream:
        tm2source = yaml.load(stream)
    return tm2source

def GeneratePrepared():

  # We have land polygons, but want water (ocean/sea) polygons.

  # Creating a diff against the northern hemisphere segfaults Postgres, perhaps because of awkward mathematics around the north pole?

  # Instead, diff against a tile crop.

  # 1. ST_Intersection(geometry, !bbox_nobuffer!) — the multiple bits of land in this tile (null if we're in the ocean)
  # 2. ST_Union(...)                              — all joined together into a multipolygon (null in the ocean)
  # 3. ST_Difference(...)                         — the negative (*null* in the ocean)
  # 4. COALESCE(..., !bbox_nobuffer!)             — if null from the ocean, return the original bounding box

  # This test is hardcoded to north_osm_land_polygons_gen7 for speed.

  tile_geom_query = "SELECT ST_AsMVTGeom(geometry,!bbox_nobuffer!,4096,0,true) AS mvtgeometry FROM (" + \
                    "    SELECT COALESCE(ST_Difference(!bbox_nobuffer!, ST_Union(ST_Intersection(geometry, !bbox_nobuffer!))), !bbox_nobuffer!) AS geometry FROM north_osm_land_polygons_gen7 WHERE geometry && !bbox_nobuffer! " + \
                    ") AS x WHERE geometry IS NOT NULL AND NOT ST_IsEmpty(geometry) AND ST_AsMVTGeom(geometry,!bbox_nobuffer!,4096,0,true) IS NOT NULL"

  base_query = "SELECT ST_ASMVT('water', 4096, 'mvtgeometry', tile) FROM ("+tile_geom_query+") AS tile WHERE tile.mvtgeometry IS NOT NULL"

  # Ocean:
  # 5.0 7.0 26.0 EXECUTE gettile(  ST_SetSRID(ST_MakeBox2D(ST_Point(-5068105.193371859, -6194350.79189894), ST_Point(-4504982.39410832, -5631227.992635399)), 3575)  , 3928032.9189700056, 512, 512);
  # → Null.

  # Coast:
  # 5.0 9.0 28.0 EXECUTE gettile(  ST_SetSRID(ST_MakeBox2D(ST_Point(-3941859.59484478, -7320596.390426019), ST_Point(-3378736.7955812397, -6757473.5911624795)), 3575)  , 3928032.9189700056, 512, 512);
  # → Data

  # Land:
  # 5.0 12.0 29.0 EXECUTE gettile( ST_SetSRID(ST_MakeBox2D(ST_Point(-2252491.19705416, -7883719.18968956), ST_Point(-1689368.3977906199, -7320596.390426019)), 3575)  , 3928032.9189700056, 512, 512);
  # → SRID=3575;GEOMETRYCOLLECTION EMPTY

  query = base_query.replace("!bbox_nobuffer!","$1").replace("!scale_denominator!","$2").replace("!pixel_width!","$3").replace("!pixel_height!","$4")
  print (base_query)

  prepared = "PREPARE gettile(geometry, numeric, numeric, numeric) AS " + query + ";"
  print(prepared)
  return(prepared)

print("Starting up")
prepared = GeneratePrepared()
connection_string = 'postgresql://'+os.getenv('POSTGRES_USER','openmaptiles')+':'+os.getenv('POSTGRES_PASSWORD','openmaptiles')+'@'+os.getenv('POSTGRES_HOST','postgres')+':'+os.getenv('POSTGRES_PORT','5432')+'/'+os.getenv('POSTGRES_DB','openmaptiles')
engine = create_engine(connection_string)
inspector = inspect(engine)
DBSession = sessionmaker(bind=engine)
session = DBSession()
print("Running prepare statement")
session.execute(prepared)

def bounds(zoom,x,y,buff):
    print('Tile',zoom,x,y,'with buffer',buff)

    map_width_in_metres = 2 * 2**0.5*6371007.2

    tiles_down = 2**(zoom)
    tiles_across = 2**(zoom)

    x = x - 2**(zoom-1)
    y = -(y - 2**(zoom-1)) - 1

    tile_width_in_metres = (map_width_in_metres / tiles_across)
    tile_height_in_metres = (map_width_in_metres / tiles_down)
    ws = ((x - buff)*tile_width_in_metres,  (y - buff)*tile_width_in_metres)
    en = ((x+1+buff)*tile_height_in_metres, (y+1+buff)*tile_height_in_metres)

    print("Zoom, buffer", zoom, buff)
    print("West:  ", ws[0])
    print("South: ", ws[1])
    print("East:  ", en[0])
    print("North: ", en[1])

    return {'w':ws[0],'s':ws[1],'e':en[0],'n':en[1]}

def zoom_to_scale_denom(zoom):						# For !scale_denominator!
    # From https://github.com/openstreetmap/mapnik-stylesheets/blob/master/zoom-to-scale.txt
    map_width_in_metres = 2 * 2**0.5*6371007.2 # Arctic
    tile_width_in_pixels = 512.0 # This asks for a zoom level higher, since the tiles are doubled.
    standardized_pixel_size = 0.00028
    map_width_in_pixels = tile_width_in_pixels*(2.0**zoom)
    return str(map_width_in_metres/(map_width_in_pixels * standardized_pixel_size))

def replace_tokens(query,tilebounds,scale_denom,z):
    s,w,n,e = str(tilebounds['s']),str(tilebounds['w']),str(tilebounds['n']),str(tilebounds['e'])

    start = query.replace("!bbox!","ST_SetSRID(ST_MakeBox2D(ST_Point("+w+", "+s+"), ST_Point("+e+", "+n+")), 3575)").replace("!scale_denominator!",scale_denom).replace("!pixel_width!","512").replace("!pixel_height!","512")

    return start

def get_mvt(zoom,x,y):
    try:								# Sanitize the inputs
        sani_zoom,sani_x,sani_y = float(zoom),float(x),float(y)
        del zoom,x,y
    except:
        print('suspicious')
        return 1

    scale_denom = zoom_to_scale_denom(sani_zoom)
    tilebounds = bounds(sani_zoom,sani_x,sani_y,0)

    final_query = "EXECUTE gettile(!bbox!, !scale_denominator!, !pixel_width!, !pixel_height!);"
    sent_query = replace_tokens(final_query,tilebounds,scale_denom,sani_zoom)
    print(sani_zoom, sani_x, sani_y, sent_query)
    response = list(session.execute(sent_query))
    layers = filter(None,list(itertools.chain.from_iterable(response)))
    final_tile = b''
    for layer in layers:
        final_tile = final_tile + io.BytesIO(layer).getvalue()
    return final_tile

class GetTile(tornado.web.RequestHandler):

    def get(self, zoom,x,y):
        self.set_header("Content-Type", "application/x-protobuf")
        self.set_header("Content-Disposition", "attachment")
        self.set_header("Access-Control-Allow-Origin", "*")
        response = get_mvt(zoom,x,y)
        self.write(response)

def m():
    if __name__ == "__main__":
        # Make this prepared statement from the tm2source
        application = tornado.web.Application([
            (r"/tiles/([0-9]+)[/_]([0-9]+)[/_]([0-9]+).pbf", GetTile),
            (r"/([^/]*)", tornado.web.StaticFileHandler, {"path": "./static", "default_filename": "index_3575.html"})
        ])

        server = tornado.httpserver.HTTPServer(application)
        server.bind(8080)
        server.start(1)
        print("Postserve started..")
        #application.listen(8080)

        tornado.ioloop.IOLoop.instance().start()

m()
