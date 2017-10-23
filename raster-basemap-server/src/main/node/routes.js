"use strict";

const fs = require('fs')
    , url = require('url')
    , config = require('./config')
    , styles = require('./styles');

/**
 * The server supports the ability to provide assets which need to be explicitly registered in order to be secure.
 * (e.g. trying to expose files using URL hack such as http://tile.gbif.org/4326/../../../hosts)
 *
 * Should this become more complex, then express or similar should be considered.
 */
var assetsHTML = [
  '/3031.html',
  '/3575.html',
  '/3857.html',
  '/4326.html',
  '/3031-tiles.html',
  '/3575-tiles.html',
  '/3857-tiles.html',
  '/4326-tiles.html',
  '/demo.html',
  '/style.css'
]

function parseUrl(parsedRequest) {
  if (parsedRequest.pathname.endsWith(".png")) {

    // extract the x,y,z from the URL which could be /4326/omt/{z}/{x}/{y}@{n}x.png
    var dirs = parsedRequest.pathname.substring(0, parsedRequest.pathname.length - 7).split("/");
    var z = parseInt(dirs[dirs.length - 3]);
    var x = parseInt(dirs[dirs.length - 2]);
    var y = parseInt(dirs[dirs.length - 1]);

    var highestVectorTile = 14;
    if (parsedRequest.pathname.startsWith("/4326/omt")) {
      highestVectorTile = 13;
    }

    var xOut = x;
    var yOut = y;
    var zOut = z;
    var xOffset = 0;
    var yOffset = 0;
    if (z > highestVectorTile) {
      zOut = highestVectorTile;
      var ratio = Math.pow(2, z - highestVectorTile);
      xOut = parseInt(x/ratio);
      yOut = parseInt(y/ratio);
      xOffset = x%ratio;
      yOffset = y%ratio;
      parsedRequest.pathname = parsedRequest.pathname.replace(z+'/'+x+'/'+y, zOut+'/'+xOut+'/'+yOut);
      console.log("High zoom", z, x, y, '->', zOut, xOut+'+'+xOffset, yOut+'+'+yOffset, parsedRequest.pathname);
    }

    // find the compiled stylesheet from the given style parameter, defaulting if omitted or bogus
    var style = styles.getStyleName(parsedRequest.query.style);

    var sDensity = parsedRequest.pathname.substring(parsedRequest.pathname.length - 6, parsedRequest.pathname.length - 5);
    var density = (sDensity == 'H') ? 0.5 : parseInt(sDensity);

    if (density > 4) density = 4;

    if (!(isNaN(z) || isNaN(x) || isNaN(y) || isNaN(density))) {
      return {
        "z": z,
        "zOut": zOut,
        "x": x,
        "xOffset": xOffset,
        "y": y,
        "yOffset": yOffset,
        "density": density,
        "style": style
      }
    }
  }
  throw Error("URL structure is invalid, expected /SRS/tileset/{z}/{x}/{y}@{n}x.png");
}

function vectorRequest(parsedRequest) {
  // reformat the request to the type expected by the VectorTile Server
  delete parsedRequest.search;
  delete parsedRequest.query;
  parsedRequest.pathname = parsedRequest.pathname.replace(/@.x\.png/, ".pbf");
  parsedRequest.hostname = config.tileServer.host;
  parsedRequest.port = config.tileServer.port;
  parsedRequest.protocol = "http:";
  return url.format(parsedRequest);
}

module.exports = function(req, res) {
  var parsedRequest = url.parse(req.url, true)

  // Handle registered assets
  if (assetsHTML.indexOf(parsedRequest.pathname) != -1) {
    var path = parsedRequest.pathname;

    var type = 'text/html';
    if (path.indexOf('.css') > 0) {
      type = 'text/css';
    } else if (path.indexOf('.js') > 0) {
      type = 'text/javascript';
    } else if (path.indexOf('.js') > 0) {
      type = 'image/png';
    }
    res.writeHead(200, {'Content-Type': type});

    res.end(fs.readFileSync('./public' + path));
    return;
  }

  // Handle map tiles.
  var parameters, vectorTileUrl;

  try {
    parameters = parseUrl(parsedRequest);
    vectorTileUrl = vectorRequest(parsedRequest);
    return {"parameters": parameters, "vectorTileUrl": vectorTileUrl};
  } catch (e) {
    res.writeHead(400, {
      'Content-Type': 'image/png',
      'Access-Control-Allow-Origin': '*',
      'X-Error': "Unable to parse request; see https://tile.gbif.org/ui/ for information.",
      'X-Error-Detail': e.message
    });
    res.end(fs.readFileSync('./public/err/400.png'));
    console.log("Request failed", e.message);
    return;
  }
}
