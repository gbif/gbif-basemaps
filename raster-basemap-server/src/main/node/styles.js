"use strict";

const fs = require('fs')
    , mapnik = require('mapnik')
    , parser = require('./cartoParser');

/**
 * Compile the CartoCSS into Mapnik stylesheets into a lookup dictionary
 */
var namedStyles = {};
namedStyles["osm-bright"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-local.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-ar"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-ar.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-zh"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-zh.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-en"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-en.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-fr"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-fr.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-ru"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-ru.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-es"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-es.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-ja"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-ja.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-de"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-de.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-da"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-da.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["osm-bright-pt"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-pt.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["gbif-classic"] = compileStylesheetSync(["./cartocss/gbif-classic.mss"]);
namedStyles["gbif-dark"] = compileStylesheetSync(["./cartocss/gbif-dark.mss"]);
namedStyles["gbif-middle"] = compileStylesheetSync(["./cartocss/gbif-middle.mss"]);
namedStyles["gbif-light"] = compileStylesheetSync(["./cartocss/gbif-light.mss"]);

var defaultStyle = "osm-bright";

mapnik.register_default_input_plugins();

// Fonts
// Register default fonts.
mapnik.register_fonts('./node_modules/mapbox-studio-default-fonts/', { recurse: true });
mapnik.register_fonts('/usr/local/gbif/klokantech-gl-fonts/', { recurse: true });
//mapnik.register_default_fonts();
//mapnik.register_system_fonts();
console.log("Fonts", mapnik.fonts());

function compileStylesheetSync(filename) {
  // snippet simulating a TileJSON response from Tilelive, required only to give the layers for the CartoParser
  var tilejson = {
    data: {
      "vector_layers": [
        // This defines the order of the layers, so road labels appear over roads, for example.
        {"id": "water" },
        {"id": "landcover" },
        {"id": "landuse" },
        {"id": "waterway" },
        {"id": "park" },
        {"id": "contour" },
        {"id": "boundary" },
        {"id": "transportation" },
        {"id": "aeroway" },
        {"id": "building" },
        {"id": "water_name" },
        {"id": "place" },
        {"id": "poi" },
        {"id": "transportation_name" },
        {"id": "housenumber" }
      ]
    }
  };
  var cartocss = filename.map( (f) => fs.readFileSync(f, "utf8") );
  return parser.parseToXML(cartocss, tilejson);
}

function Styles() {}

Styles.prototype.getStyleName = function(style) {
  return (style in namedStyles) ? style : defaultStyle;
}

Styles.prototype.getStyle = function(style) {
  return (style in namedStyles) ? namedStyles[style] : namedStyles[defaultStyle];
}

module.exports = new Styles();
