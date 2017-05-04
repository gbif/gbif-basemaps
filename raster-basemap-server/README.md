# Mapnik Server for Base Map Tiles

A very simple PNG writer of vector tiles that renders using Mapnik.

Stylesheets and layers will be for [GBIF basemaps](https://tile.gbif.org/ui/).

<p align="center"><img src="https://tile.gbif.org/3857/omt/0/0/0@1x.png?style=gbif-classic" width="384" /></p>

<p align="center"><img src="https://tile.gbif.org/4326/omt/0/0/0@1x.png?style=gbif-dark" width="384" /><img src="https://tile.gbif.org/4326/omt/0/1/0@1x.png?style=gbif-dark" width="384" /></p>

<p align="center"><img src="https://tile.gbif.org/3575/omt/0/0/0@1x.png?style=osm-bright" width="384" /> <img src="https://tile.gbif.org/3031/0/0/0@1x.png?style=gbif-middle" width="384" /></p>

## Building and running

For continuous integration with the Java modules, this project can be built using Maven:

```
mvn clean install
cd src/main/node
export PATH="$PWD/node/":$PATH
node server.js ../../../server.conf 3000
```

`npm`, `nvm` and `npm` tool can be used instead, if preferred.

## Flushing the cache server

After deployment, you may wish to flush the cache in Varnish — perhaps for a single style, or all raster tiles.

```
curl -i -X BAN 'http://tile.gbif.org/' -H 'X-Ban-URL: gbif-classic'
curl -i -X BAN 'http://tile.gbif.org/' -H 'X-Ban-URL: png'
```
