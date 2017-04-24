proj4.defs("EPSG:3031", "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs");

var halfWidth = 12367396.2185; // To the Equator
var extent = [-halfWidth, -halfWidth, halfWidth, halfWidth];
ol.proj.get("EPSG:3031").setExtent(extent);

// The resolution is the size of 1 pixel in map units
var resolutions = Array.from(new Array(17), (x,i) => (halfWidth/(512*Math.pow(2,i-1))));

var tileGrid = new ol.tilegrid.TileGrid({
  extent: extent,
  origin: [-halfWidth, halfWidth],
  minZoom: 0,
  maxZoom: 16,
  resolutions: resolutions,
  tileSize: [512, 512],
});

var tileUrlFunctionEPSG3031 = function (tileCoord, pixelRatio, projection) {
  if (tileCoord === null) return undefined;
  z = tileCoord[0];
  x = tileCoord[1];
  y = (-tileCoord[2] -1);
  return '/3031/omt/' + z + '/' + x + '/' + y + '.pbf';
};

var layers = [];

// And try http://www.pgc.umn.edu/imagery/satellite for imagery.
layers['PolarView'] = new ol.layer.Tile({
	extent: extent,
  source: new ol.source.TileWMS({
		url: 'http://geos.polarview.aq/geoserver/wms',
		params: {'LAYERS': 'polarview:MODIS_Terra_Antarctica', 'TILED': true},
		serverType: 'geoserver',
		tileGrid: tileGrid,
  })
});

// https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers
var nasaHalfWidth = 4194304*0.8; // Only Antarctic continent
layers['NASA'] = new ol.layer.Tile({
	extent: [-nasaHalfWidth, -nasaHalfWidth, nasaHalfWidth, nasaHalfWidth],
	source: new ol.source.WMTS({
		url: "https://map1{a-c}.vis.earthdata.nasa.gov/wmts-antarctic/wmts.cgi?TIME=2013-12-01",
		layer: "MODIS_Terra_CorrectedReflectance_TrueColor",
		format: "image/jpeg",
		matrixSet: "EPSG3031_250m",

		tileGrid: new ol.tilegrid.WMTS({
			origin: [-4194304, 4194304],
			resolutions: [
				8192.0,
				4096.0,
				2048.0,
				1024.0,
				512.0,
				256.0
			],
			matrixIds: [0, 1, 2, 3, 4, 5],
			tileSize: 512
		})
	}),
	visible: false,
});

layers['Grid'] = new ol.layer.Tile({
  extent: extent,
  source: new ol.source.TileDebug({
    projection: 'EPSG:3031',
    tileGrid: tileGrid
  }),
	visible: true,
});

layers['EPSG:3031'] = new ol.layer.VectorTile({
  source: new ol.source.VectorTile({
    projection: 'EPSG:3031',
    format: new ol.format.MVT(),
    tileGrid: tileGrid,
		url: '/3031/omt/{z}/{x}/{y}.pbf',
    tilePixelRatio: 8,
  }),
  style: createStyle()
});

var raster_style = 'gbif-classic';
layers['EPSG:3031-R'] = new ol.layer.Tile({
	extent: extent,
	source: new ol.source.TileImage({
		projection: 'EPSG:3031',
	  tileGrid: tileGrid,
		url: '/3031/omt/{z}/{x}/{y}@1x.png?style='+raster_style,
		tilePixelRatio: 1,
	}),
	visible: false,
});

layers['OccurrenceDensityRaster:3031'] = new ol.layer.Tile({
	extent: extent,
  source: new ol.source.TileImage({
		projection: 'EPSG:3031',
		tileGrid: tileGrid,
		tilePixelRatio: 1,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png?srs=EPSG:3031',
  }),
	opacity: 0.5,
	visible: true
});

var map = new ol.Map({
	layers: [
		layers['NASA'],
    // layers['PolarView'],
		layers['EPSG:3031'],
		layers['EPSG:3031-R'],
		layers['OccurrenceDensityRaster:3031'],
		layers['Grid'],
	],
	target: 'map',
  view: new ol.View({
    center: [0, 0],
    projection: ol.proj.get("EPSG:3031"),
    zoom: 0,
    extent: extent,
  }),
});

function bindInputs(layerid, layer) {
  var visibilityInput = document.getElementById(layerid + '_visible');
  visibilityInput.onchange = (function() {
		layer.setVisible(this.checked);
  });
  visibilityInput.checked = layer.getVisible() ? 'on' : '';

  var opacityInput = document.getElementById(layerid + '_opacity');
  opacityInput.oninput = (function() {
		layer.setOpacity(parseFloat(this.value));
  });
  opacityInput.value = (String(layer.getOpacity()));
}

bindInputs('NASA', layers['NASA']);
bindInputs('Grid', layers['Grid']);
bindInputs('EPSG3031', layers['EPSG:3031']);
bindInputs('EPSG3031-R', layers['EPSG:3031-R']);
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:3031']);

var progress = new Progress(document.getElementById('progress'));

var source = layers['EPSG:3031'].getSource();

source.on('tileloadstart', function(e) {
  progress.addLoading(e);
});
source.on('tileloadend', function() {
  progress.addLoaded();
});
source.on('tileloaderror', function() {
  progress.addLoaded();
});

var styleSelect = document.getElementById('EPSG3031_style');
styleSelect.onchange = (function(e) {
	switch (styleSelect.value) {
	case 'debug':
		layers['EPSG:3031'].setStyle(createStyle());
		break;

	case 'mapboxgl':
		fetch('https://openmaptiles.github.io/klokantech-basic-gl-style/style-cdn.json').then(function(response) {
			response.json().then(function(glStyle) {
				olms.applyStyle(layers['EPSG:3031'], glStyle, 'openmaptiles');
			});
		});
		break;
	}
});

var styleSelectR = document.getElementById('EPSG3031-R_style');
styleSelectR.onchange = (function(e) {
	layers['EPSG:3031-R'].getSource().setUrl('/3031/omt/{z}/{x}/{y}@4x.png?style='+styleSelectR.value);
	layers['EPSG:3031-R'].getSource().refresh();
});
