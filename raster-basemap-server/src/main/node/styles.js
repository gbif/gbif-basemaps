"use strict";

const fs = require('fs')
    , mapnik = require('mapnik')
    , parser = require('./cartoParser');

/**
 * Compile the CartoCSS into Mapnik stylesheets into a lookup dictionary
 */
var languages = ["ar", "da", "de", "en", "es", "fr", "ja", "pt", "ru", "uk", "zh"];
var namedStyles = {};

namedStyles["osm-bright"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-local.mss', './cartocss/osm-bright/labels.mss']);
for (var lang of languages) {
  namedStyles["osm-bright-"+lang] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels-'+lang+'.mss', './cartocss/osm-bright/labels.mss']);
}
namedStyles["gbif-classic"] = compileStylesheetSync(["./cartocss/gbif-classic.mss"]);
namedStyles["gbif-dark"] = compileStylesheetSync(["./cartocss/gbif-dark.mss"]);
namedStyles["gbif-middle"] = compileStylesheetSync(["./cartocss/gbif-middle.mss"]);
namedStyles["gbif-light"] = compileStylesheetSync(["./cartocss/gbif-light.mss"]);

//attempts of a combination between the flat "mono color" versions and OSM
//names based on a rough average color and name that color website http://chir.ag/projects/name-that-color
namedStyles["gbif-geyser"] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_light.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-local.mss', "./cartocss/gbif-monocolor/labels.mss"]);
namedStyles["gbif-tuatara"] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_dark.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-local.mss', "./cartocss/gbif-monocolor/labels.mss"]);
namedStyles["gbif-violet"] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_magenta.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-local.mss', "./cartocss/gbif-monocolor/labels.mss"]);
for (var lang of languages) {
  namedStyles["gbif-geyser-"+lang] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_light.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-'+lang+'.mss', "./cartocss/gbif-monocolor/labels.mss"]);
  namedStyles["gbif-tuatara-"+lang] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_dark.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-'+lang+'.mss', "./cartocss/gbif-monocolor/labels.mss"]);
  namedStyles["gbif-violet-"+lang] = compileStylesheetSync(["./cartocss/gbif-monocolor/variables_magenta.mss", "./cartocss/gbif-monocolor/style.mss", "./cartocss/gbif-monocolor/roads.mss", './cartocss/osm-bright/labels-'+lang+'.mss', "./cartocss/gbif-monocolor/labels.mss"]);
}

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
        {"id": "bathymetry" },
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
