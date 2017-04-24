proj4.defs("EPSG:3575", "+proj=laea +lat_0=90 +lon_0=10 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs");

var halfWidth = Math.sqrt(2) * 6371007.2;
var extent = [-halfWidth, -halfWidth, halfWidth, halfWidth];
ol.proj.get("EPSG:3575").setExtent(extent);

// The resolution is the size of 1 pixel in map units
var resolutions = Array.from(new Array(17), (x,i) => (halfWidth/(512*Math.pow(2,i-1))));

var tileGrid = new ol.tilegrid.TileGrid({
  extent: extent,
  origin: [-halfWidth,halfWidth],
  minZoom: 0,
  maxZoom: 16,
  resolutions: resolutions,
  tileSize: 512,
});

var layers = [];

var amHalfWidth = 12742014.4;
layers['AlaskaMapped'] = new ol.layer.Tile({
  source: new ol.source.TileImage({
    projection: 'EPSG:3575',
    tileGrid: new ol.tilegrid.TileGrid({
			extent: [-amHalfWidth, -amHalfWidth, amHalfWidth, amHalfWidth],
			origin: [0,0],
			minZoom: 0,
			maxZoom: 8,
			resolutions: Array.from(new Array(9), (x,i) => (amHalfWidth/(512*Math.pow(2,i-1)))),
			tileSize: [512, 512]
		}),
		tileUrlFunction: function (tileCoord, pixelRatio, projection) {
      if (tileCoord === null) return undefined;
      z = tileCoord[0];
      x = tileCoord[1];
      y = tileCoord[2];
      return '//download.gbif.org/MapDataMirror/AlaskaMapped/ac-3575/' + z + '/' + x + '/' + y + '@2x.png';
    },
    tilePixelRatio: 1,
  }),
	visible: false,
  opacity: 1.0/6
});

layers['Grid'] = new ol.layer.Tile({
  extent: extent,
  source: new ol.source.TileDebug({
    projection: 'EPSG:3575',
    tileGrid: tileGrid,
  }),
	visible: true,
});

layers['EPSG:3575'] = new ol.layer.VectorTile({
	extent: extent,
  source: new ol.source.VectorTile({
    projection: 'EPSG:3575',
    format: new ol.format.MVT(),
    tileGrid: tileGrid,
		url: '/3575/omt/{z}/{x}/{y}.pbf',
    tilePixelRatio: 8,
  }),
  style: createStyle()
});

var raster_style = 'gbif-classic';
layers['EPSG:3575-R'] = new ol.layer.Tile({
	extent: extent,
	source: new ol.source.TileImage({
		projection: 'EPSG:3575',
	  tileGrid: tileGrid,
		url: '/3575/omt/{z}/{x}/{y}@2x.png?style='+raster_style,
		tilePixelRatio: 1,
	}),
	visible: false,
});

layers['OccurrenceDensityRaster:3575'] = new ol.layer.Tile({
	extent: extent,
  source: new ol.source.TileImage({
		projection: 'EPSG:3575',
		tileGrid: tileGrid,
		tilePixelRatio: 1,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png?srs=EPSG:3575',
  }),
	opacity: 0.5,
	visible: true
});

var map = new ol.Map({
	layers: [
		layers['AlaskaMapped'],
		layers['EPSG:3575'],
		layers['EPSG:3575-R'],
		layers['OccurrenceDensityRaster:3575'],
		layers['Grid']
	],
	target: 'map',
  view: new ol.View({
		center: ol.proj.fromLonLat([-1.049565, 51.441297], 'EPSG:3575'),
    projection: ol.proj.get('EPSG:3575'),
    zoom: 1,
		maxResolution: halfWidth / 512 * 2,
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

bindInputs('AlaskaMapped', layers['AlaskaMapped']);
bindInputs('Grid', layers['Grid']);
bindInputs('EPSG3575', layers['EPSG:3575']);
bindInputs('EPSG3575-R', layers['EPSG:3575-R']);
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:3575']);

var progress = new Progress(document.getElementById('progress'));

var source = layers['EPSG:3575'].getSource();

source.on('tileloadstart', function(e) {
  progress.addLoading(e);
});
source.on('tileloadend', function() {
  progress.addLoaded();
});
source.on('tileloaderror', function() {
  progress.addLoaded();
});

var styleSelect = document.getElementById('EPSG3575_style');
styleSelect.onchange = (function(e) {
	switch (styleSelect.value) {
	case 'debug':
		layers['EPSG:3575'].setStyle(createStyle());
		break;

	case 'mapboxgl':
		fetch('https://openmaptiles.github.io/klokantech-basic-gl-style/style-cdn.json').then(function(response) {
			response.json().then(function(glStyle) {
				olms.applyStyle(layers['EPSG:3575'], glStyle, 'openmaptiles');
			});
		});
		break;
	}
});

var styleSelectR = document.getElementById('EPSG3575-R_style');
styleSelectR.onchange = (function(e) {
	layers['EPSG:3575-R'].getSource().setUrl('/3575/omt/{z}/{x}/{y}@2x.png?style='+styleSelectR.value);
	layers['EPSG:3575-R'].getSource().refresh();
});

var source = layers['EPSG:3575-R'].getSource();
var tileUrlFunction = source.getTileUrlFunction();

map.on('click', function (evt) {
	var coord = evt.coordinate;
	console.log('coord', coord);
	var resolution = this.getView().getResolution()
	console.log('resolution', resolution);
	var tileCoord = tileGrid.getTileCoordForCoordAndResolution(coord, resolution);
	console.log('tileCoord', tileCoord);

	console.log('CLICKED ON', tileUrlFunction(tileCoord, 1, ol.proj.get('EPSG:3575')));
	console.log('→', 'http://tile.gbif.org'+tileUrlFunction(tileCoord, 1, ol.proj.get('EPSG:3575')));
});