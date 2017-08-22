var mapnik = require('mapnik'),
    mercator = require('./sphericalmercator'),
    request = require('request'),
    http = require('http'),
    url = require('url'),
    fs = require('fs'),
    yaml = require('yaml-js'),
    gbifServiceRegistry = require('./gbifServiceRegistry'),
    parser = require('./cartoParser');

/**
 * Compile the CartoCss into Mapnik stylesheets into a lookup dictionary
 */
var namedStyles = {};
namedStyles["osm-bright"] = compileStylesheetSync(['./cartocss/osm-bright/style.mss', './cartocss/osm-bright/road.mss', './cartocss/osm-bright/labels.mss']);
namedStyles["gbif-classic"] = compileStylesheetSync(["./cartocss/gbif-classic.mss"]);
namedStyles["gbif-dark"] = compileStylesheetSync(["./cartocss/gbif-dark.mss"]);
namedStyles["gbif-middle"] = compileStylesheetSync(["./cartocss/gbif-middle.mss"]);
namedStyles["gbif-light"] = compileStylesheetSync(["./cartocss/gbif-light.mss"]);
function compileStylesheetSync(filename) {
  // snippet simulating a tilejson response from tilelive, required only to give the layers for the cartoParser
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
var defaultStyle = "classic.point";

mapnik.register_default_input_plugins();

// Fonts
// Register default fonts.
mapnik.register_fonts('./node_modules/mapbox-studio-default-fonts/', { recurse: true });
//mapnik.register_fonts('/usr/share/fonts/truetype/', { recurse: true });
mapnik.register_fonts('/home/mblissett/Workspace/klokantech-gl-fonts', { recurse: true });
//mapnik.register_default_fonts();
//mapnik.register_system_fonts();
//console.log("Fonts", mapnik.fonts());

var processStartTime = new Date().toUTCString();
console.log("HTTP requests will have Last-Modified set to", processStartTime);

/**
 * The server supports the ability to provide assets which need to be explicitly registered in order to be secure.
 * (e.g. trying to expose files using URL hack such as http://api.gbif.org/v1/map/../../../hosts)
 *
 * Should this become more complex, then express or similar should be consider.
 */
var assetsHTML = [
  '/3857.html',
  '/4326.html'
]

function parseUrl(parsedRequest) {
  if (parsedRequest.pathname.endsWith(".png")) {

	  // extract the x,y,z from the URL which could be /4326/omt/{z}/{x}/{y}@{n}x.png
	  var dirs = parsedRequest.pathname.substring(0, parsedRequest.pathname.length - 7).split("/");
	  var z = parseInt(dirs[dirs.length - 3]);
	  var x = parseInt(dirs[dirs.length - 2]);
	  var y = parseInt(dirs[dirs.length - 1]);

	  var xOut = x;
	  var yOut = y;
	  var zOut = z;
	  var xOffset = 0;
	  var yOffset = 0;
	  if (z == 16) {
	    zOut = 14;
	    xOut = parseInt(x/4);
	    yOut = parseInt(y/4);
	    xOffset = x%4;
	    yOffset = y%4;
	    parsedRequest.pathname = parsedRequest.pathname.replace(z+'/'+x+'/'+y, zOut+'/'+xOut+'/'+yOut);
	    console.log("High zoom", z, x, y, '->', zOut, xOut+'+'+xOffset, yOut+'+'+yOffset, parsedRequest.pathname);
	  } else if (z == 15) {
	    zOut = 14;
	    xOut = parseInt(x/2);
	    yOut = parseInt(y/2);
	    xOffset = x%2;
	    yOffset = y%2;
	    parsedRequest.pathname = parsedRequest.pathname.replace(z+'/'+x+'/'+y, zOut+'/'+xOut+'/'+yOut);
	    console.log("High zoom", z, x, y, '->', zOut, xOut+'+'+xOffset, yOut+'+'+yOffset, parsedRequest.pathname);
	  }

	  // find the compiled stylesheet from the given style parameter, defaulting if omitted or bogus
	  var stylesheet = (parsedRequest.query.style in namedStyles)
	      ? namedStyles[parsedRequest.query.style]
	      : namedStyles[defaultStyle];

	  var density = parseInt(parsedRequest.pathname.substring(parsedRequest.pathname.length - 6, parsedRequest.pathname.length - 5));

	  if (!(isNaN(z) || isNaN(x) || isNaN(y) || isNaN(density))) {
	    return {
		    "z": z,
		    "zOut": zOut,
		    "x": x,
		    "xOffset": xOffset,
		    "y": y,
		    "yOffset": yOffset,
		    "density": density,
		    "stylesheet": stylesheet
	    }
	  }
  }
  throw Error("URL structure is invalid, expected /SRS/tileset/{z}/{x}/{y}@{n}x.png");
}

function vectorRequest(parsedRequest) {
  // reformat the request to the type expected by the VectorTile Server
  parsedRequest.search = undefined;
  parsedRequest.query = undefined;
  parsedRequest.pathname = parsedRequest.pathname.replace("@1x.png", ".pbf");
  parsedRequest.pathname = parsedRequest.pathname.replace("@2x.png", ".pbf");
  parsedRequest.pathname = parsedRequest.pathname.replace("@3x.png", ".pbf");
  parsedRequest.pathname = parsedRequest.pathname.replace("@4x.png", ".pbf");
  parsedRequest.hostname = config.tileServer.host;
  parsedRequest.port = config.tileServer.port;
  parsedRequest.protocol = "http:";
  return url.format(parsedRequest);
}

function createServer(config) {
  return http.createServer(function(req, res) {
    console.log("Request: "+req.url);

    var parsedRequest = url.parse(req.url, true)

    // handle registered assets
	  console.log(parsedRequest.pathname);
    if (assetsHTML.indexOf(parsedRequest.pathname) != -1) {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end(fs.readFileSync('./public' + parsedRequest.pathname));
    } else {

	    // Handle map tiles.
	    try {
	      var parameters = parseUrl(parsedRequest);
	    } catch (e) {
	      res.writeHead(400, { 'Content-Type': 'text/plain' });
	      res.end(e.message);
	      return;
	    }

	    var vectorTileUrl = vectorRequest(parsedRequest);


	    // issue the request to the vector tile server and render the tile as a PNG using Mapnik
	    console.time("getTile");
	    console.log("Fetching vector tile", vectorTileUrl);
	    request.get({url: vectorTileUrl, method: 'GET', encoding: null}, function (error, response, body) {

	      console.log("Vector tile has HTTP status", response.statusCode, "and size", body.length);

        if (!error && response.statusCode == 200 && body.length > 0) {
          console.timeEnd("getTile");

          var size = 512 * parameters.density;

	        try {
		        var map = new mapnik.Map(size, size, mercator.proj4);
		        map.fromStringSync(parameters.stylesheet);
		        // Pretend it's tile 0, 0, since Mapnik validates the address according to the standard Google schema,
		        // and we aren't using it for WGS84.
		        var vt = new mapnik.VectorTile(parameters.zOut, 0, 0);
		        vt.addDataSync(body);

		        var options = {"buffer_size": 128, "scale": parameters.density};
		        if (parameters.z > 14) {
		          options.z = parameters.z;
		          options.x = parameters.xOffset;
		          options.y = parameters.yOffset;
		        }

		        // important to include a buffer, to catch the overlaps
		        //console.time("render");
		        vt.render(map, new mapnik.Image(size, size), options, function (err, image) {
		          if (err) {
			          res.end(err.message);
		          } else {
			          // if response.headers.last-modified is set, and is more recent than processStartTime, use that instead.
			          res.writeHead(200, {
			            'Content-Type': 'image/png',
			            'Access-Control-Allow-Origin': '*',
			            'Cache-Control': 'public, max-age=604800', // 1 week
			            'Last-Modified': processStartTime
			          });
			          //console.timeEnd("render");

			          image.encode('png', function (err, buffer) {
			            if (err) {
				            res.end(err.message);
			            } else {
				            res.end(buffer);
			            }
			          });
		          }
		        });
	        } catch (e) {
		        // something went wrong
		        res.writeHead(500, {'Content-Type': 'image/png'}); // type only for ease of use with e.g. leaflet
		        res.end(e.message);
		        console.log(e);
	        }

        } else if (!error && (
          response.statusCode == 404 ||   // not found
          response.statusCode == 204 ||   // no content
          (response.statusCode == 200 && body.length==0))  // accepted but no content
		              ) {
          // no tile
          res.writeHead((response.statusCode == 200) ? 204 : response.statusCode, // keep same status code
                        {
			                    'Content-Type': 'image/png',
			                    'Access-Control-Allow-Origin': '*',
			                    'Cache-Control': 'public, max-age=604800', // 1 week
			                    'Last-Modified': processStartTime
                        });
          res.end();

        } else {
          // something went wrong
          res.writeHead(503, {'Content-Type': 'image/png'}); // type only for ease of use with e.g. leaflet
          res.end();
        }
	    })
    }
  });
}

/**
 * Shut down cleanly.
 */
function exitHandler() {
  console.log("Completing requests");
  // Until https://github.com/nodejs/node/issues/2642 is fixed, we can't wait for connections to end.
  //server.close(function () {
    process.exit(0);
  //});
}

/**
 * The main entry point.
 * Extract the configuration and start the server.  This expects a config file in YAML format and a port
 * as the only arguments.  No sanitization is performed on the file existance or content.
 */
try {
  process.on('SIGHUP', () => {console.log("Ignoring SIGHUP")});

  // Log if we crash.
  process.on('uncaughtException', function (exception) {
    console.trace(exception);
    exitHandler();
  });
  process.on('unhandledRejection', (reason, p) => {
    console.log("Unhandled Rejection at: Promise ", p, " reason: ", reason);
    exitHandler();
  });

  // Set up server.
  var configFile = process.argv[2];
  var port = parseInt(process.argv[3]);
  console.log("Using config: " + configFile);
  console.log("Using port: " + port);
  var config = yaml.load(fs.readFileSync(configFile, "utf8"));
  server = createServer(config)
  server.listen(port);

  // Set up ZooKeeper.
  gbifServiceRegistry.register(config);

  // Aim to exit cleanly.
  process.on('SIGINT', exitHandler.bind());
  process.on('SIGTERM', exitHandler.bind());
  process.on('exit', exitHandler.bind());
} catch (e) {
  console.error(e);
}
