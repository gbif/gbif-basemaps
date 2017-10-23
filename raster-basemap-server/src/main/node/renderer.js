"use strict";

const async = require('async')
    , mapnik = require('mapnik')
    , styles = require('./styles');

const proj4 = '+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over';

function renderTile(parameters, vectorTile, callback) {
  var size = 512 * parameters.density;

  if (!vectorTile || vectorTile.length == 0) {
    console.log("Empty tile");
    var image = new mapnik.Image(size, size, {premultiplied: true});
    callback(null, image);
    return;
  }

  var map = new mapnik.Map(size, size, proj4);
  map.fromStringSync(styles.getStyle(parameters.style));

  // Pretend it's tile 0, 0, since Mapnik validates the address according to the standard Google schema,
  // and we aren't using it for WGS84.
  var vt = new mapnik.VectorTile(parameters.zOut, 0, 0);
  // Change bytes to set MVT version to 1, to avoid validation done when it's set to 2.
  for (var i = 0; i < vectorTile.length; i++) {
    if (vectorTile[i] == 0x20) {
      if (vectorTile[i+1] == 0x78) {
        if (vectorTile[i+2] == 0x02) {
          vectorTile[i+2] = 0x01;
        }
      }
    }
  }
  vt.addDataSync(vectorTile);

  var options = { "buffer_size": 128, "scale": parameters.density };
  if (parameters.z > 13) {
    options.z = parameters.z;
    options.x = parameters.xOffset;
    options.y = parameters.yOffset;
  }

  vt.render(map, new mapnik.Image(size, size), options, function (err, image) {
    //console.timeEnd("Render");

    if (err) {
      console.log("ERROR", err);
      callback(err, null);
    }
    else {
      callback(err, image);
    }
  });
}

function render(parameters, vectorTile, res) {
  async.map([vectorTile],
    function(tile, callback) {renderTile(parameters, tile, callback)},
    function(err, results) {
      if (err) console.log('One rendered', results, err);

      res.end(results[0].encodeSync('png'));
    });
}

module.exports = function(parameters, vectorTile, res) {
  render(parameters, vectorTile, res);
}
