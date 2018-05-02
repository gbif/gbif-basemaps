proj4.defs('EPSG:4326', "+proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees");

var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var extent = 180.0;
var tile_size = 512;
var max_zoom = 16;
var resolutions = Array(max_zoom+1).fill().map((_, i) => ( extent / tile_size / Math.pow(2, i) ));

var tile_grid_14 = new ol.tilegrid.TileGrid({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	minZoom: 0,
	maxZoom: 14,
	resolutions: resolutions,
	tileSize: tile_size,
});

var tile_grid_16 = new ol.tilegrid.TileGrid({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	minZoom: 0,
	maxZoom: 16,
	resolutions: resolutions,
	tileSize: tile_size,
});

var layers = [];

// From http://server.arcgisonline.com/ArcGIS/rest/services/
layers['ESRI'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileImage({
		projection: 'EPSG:4326',
		url: 'https://services.arcgisonline.com/arcgis/rest/services/ESRI_Imagery_World_2D/MapServer/tile/{z}/{y}/{x}',
		// url: 'http://server.arcgisonline.com/arcgis/rest/services/ESRI_StreetMap_World_2D/MapServer/tile/{z}/{y}/{x}',
		tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: max_zoom,
			resolutions: resolutions,
			tileSize: tile_size,
		}),
		attributions: '© 2013 ESRI, i-cubed, GeoEye',
	}),
	visible: false,
});

layers['Grid'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileDebug({
		projection: 'EPSG:4326',
		tileGrid: tile_grid_16,
		wrapX: false
	}),
	visible: false,
});

layers['EPSG:4326'] = new ol.layer.VectorTile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.VectorTile({
		format: new ol.format.MVT(),
		projection: 'EPSG:4326',
		url: 'https://tile.gbif.org/4326/omt/{z}/{x}/{y}.pbf',
		tileGrid: tile_grid_14,
		tilePixelRatio: 8,
		attributions: [
			'© <a href="https://www.openmaptiles.org/copyright">OpenMapTiles</a>.',
			ol.source.OSM.ATTRIBUTION,
		],
		wrapX: false
	}),
	style: createStyle(),
	visible: false,
});

var raster_style = 'gbif-classic';
if (window.location.hash) {
	console.log(window.location.hash);
	raster_style = window.location.hash.replace('#', '');
}
layers['EPSG:4326-R'] = new ol.layer.Tile({
	source: new ol.source.TileImage({
		projection: 'EPSG:4326',
		url: 'https://tile.gbif.org/4326/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+raster_style,
		tileGrid: tile_grid_16,
		tilePixelRatio: pixel_ratio,
		attributions: [
			'© <a href="https://www.openmaptiles.org/copyright">OpenMapTiles</a>.',
			ol.source.OSM.ATTRIBUTION,
		],
		wrapX: true
	}),
	visible: true,
});

layers['OccurrenceDensity:4326'] = new ol.layer.VectorTile({
	renderMode: 'image',
	source: new ol.source.VectorTile({
		projection: 'EPSG:4326',
		format: new ol.format.MVT(),
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}.mvt?srs=EPSG:4326&bin=hex&taxonKey=2481433',
		tileGrid: tile_grid_14,
		tilePixelRatio: 8,
		attributions: '<a href="https://www.gbif.org/citation-guidelines">GBIF</a>.',
	}),
	style: createDensityStyle(),
	visible: true,
});

layers['OccurrenceDensityRaster:4326'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileImage({
		projection: 'EPSG:4326',
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@'+pixel_ratio+'x.png?srs=EPSG:4326',
		tileGrid: tile_grid_16,
		tilePixelRatio: pixel_ratio,
		attributions: '<a href="https://www.gbif.org/citation-guidelines">GBIF</a>.',
	}),
	visible: false
});

var map = new ol.Map({
	layers: [
		layers['ESRI'],
		layers['EPSG:4326'],
		layers['EPSG:4326-R'],
		layers['OccurrenceDensity:4326'],
		layers['OccurrenceDensityRaster:4326'],
		layers['Grid']
	],
	target: 'map',
	controls: ol.control.defaults({
		attributionOptions: {
			collapsible: false
		}
	}),
	view: new ol.View({
		center: [0, 0],
		projection: 'EPSG:4326',
		zoom: 2
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

bindInputs('ESRI', layers['ESRI']);
bindInputs('Grid', layers['Grid']);
bindInputs('EPSG4326', layers['EPSG:4326']);
bindInputs('EPSG4326-R', layers['EPSG:4326-R']);
bindInputs('OccurrenceDensity', layers['OccurrenceDensity:4326']);
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:4326']);

var styleSelect = document.getElementById('EPSG4326_style');
styleSelect.onchange = (function(e) {
	switch (styleSelect.value) {
	case 'debug':
		layers['EPSG:4326'].setStyle(createStyle());
		break;

	case 'mapboxgl':
		fetch('https://openmaptiles.github.io/klokantech-basic-gl-style/style-cdn.json').then(function(response) {
			response.json().then(function(glStyle) {
				olms.applyStyle(layers['EPSG:4326'], glStyle, 'openmaptiles');
			});
		});
		break;
	}
});

var styleSelectR = document.getElementById('EPSG4326-R_style');
styleSelectR.onchange = (function(e) {
	layers['EPSG:4326-R'].getSource().setUrl('https://tile.gbif.org/4326/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+styleSelectR.value);
	layers['EPSG:4326-R'].getSource().refresh();
});
styleSelectR.value = raster_style;
