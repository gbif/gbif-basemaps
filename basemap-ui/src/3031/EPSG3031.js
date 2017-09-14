proj4.defs("EPSG:3031", "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs");

var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var halfWidth = 12367396.2185; // To the Equator
var extent = [-halfWidth, -halfWidth, halfWidth, halfWidth];
ol.proj.get("EPSG:3031").setExtent(extent);
var tile_size = 512;
var max_zoom = 16;
var resolutions = Array.from(new Array(max_zoom+1), (x,i) => (halfWidth/(tile_size*Math.pow(2,i-1))));

var tile_grid_14 = new ol.tilegrid.TileGrid({
	extent: extent,
	origin: [-halfWidth, halfWidth],
	minZoom: 0,
	maxZoom: 14,
	resolutions: resolutions,
	tileSize: tile_size,
});

var tile_grid_16 = new ol.tilegrid.TileGrid({
	extent: extent,
	origin: [-halfWidth, halfWidth],
	minZoom: 0,
	maxZoom: 16,
	resolutions: resolutions,
	tileSize: tile_size,
});

var layers = [];

// And try http://www.pgc.umn.edu/imagery/satellite for imagery.
layers['PolarView'] = new ol.layer.Tile({
	extent: extent,
	source: new ol.source.TileWMS({
		url: 'http://geos.polarview.aq/geoserver/wms',
		params: {'LAYERS': 'polarview:MODIS_Terra_Antarctica', 'TILED': true},
		serverType: 'geoserver',
		tileGrid: tile_grid_16,
	}),
	visible: false,
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
		tileGrid: tile_grid_16,
	}),
	visible: false,
});

layers['EPSG:3031'] = new ol.layer.VectorTile({
	source: new ol.source.VectorTile({
		projection: 'EPSG:3031',
		format: new ol.format.MVT(),
		tileGrid: tile_grid_14,
		url: 'https://tile.gbif.org/3031/omt/{z}/{x}/{y}.pbf',
		tilePixelRatio: 8,
	}),
	style: createStyle(),
	visible: false,
});

var raster_style = 'gbif-middle';
layers['EPSG:3031-R'] = new ol.layer.Tile({
	extent: extent,
	source: new ol.source.TileImage({
		projection: 'EPSG:3031',
		tileGrid: tile_grid_16,
		url: 'https://tile.gbif.org/3031/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+raster_style,
		tilePixelRatio: pixel_ratio,
	}),
	visible: true,
});

layers['OccurrenceDensity:3031'] = new ol.layer.VectorTile({
	renderMode: 'image',
	source: new ol.source.VectorTile({
		projection: 'EPSG:3031',
		format: new ol.format.MVT(),
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}.mvt?srs=EPSG:3031&bin=hex&taxonKey=459',
		tileGrid: tile_grid_14,
		tilePixelRatio: 8,
	}),
	style: createDensityStyle(),
	visible: true,
});

layers['OccurrenceDensityRaster:3031'] = new ol.layer.Tile({
	extent: extent,
	source: new ol.source.TileImage({
		projection: 'EPSG:3031',
		tileGrid: tile_grid_16,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@'+pixel_ratio+'x.png?srs=EPSG:3031',
		tilePixelRatio: pixel_ratio,
	}),
	visible: false
});

var map = new ol.Map({
	layers: [
		layers['NASA'],
		// layers['PolarView'],
		layers['EPSG:3031'],
		layers['EPSG:3031-R'],
		layers['OccurrenceDensityRaster:3031'],
		layers['OccurrenceDensity:3031'],
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
bindInputs('OccurrenceDensity', layers['OccurrenceDensity:3031']);
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:3031']);

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
	layers['EPSG:3031-R'].getSource().setUrl('https://tile.gbif.org/3031/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+styleSelectR.value);
	layers['EPSG:3031-R'].getSource().refresh();
});
