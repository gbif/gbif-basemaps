var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var tile_size = 512;

var tile_grid_14 = ol.tilegrid.createXYZ({
	minZoom: 0,
	maxZoom: 14,
	tileSize: tile_size,
});

var tile_grid_16 = ol.tilegrid.createXYZ({
	minZoom: 0,
	maxZoom: 16,
	tileSize: tile_size,
});

var layers = [];

layers['OSM'] = new ol.layer.Tile({
	source: new ol.source.OSM({
		attributions: ol.source.OSM.ATTRIBUTION,
		wrapX: false
	}),
	visible: false,
});

layers['Grid'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:3857').getExtent(),
	source: new ol.source.TileDebug({
		projection: 'EPSG:3857',
		tileGrid: tile_grid_16,
		tilePixelRatio: 8,
		wrapX: false
	}),
	visible: false,
});

layers['EPSG:3857'] = new ol.layer.VectorTile({
	source: new ol.source.VectorTile({
		projection: 'EPSG:3857',
		format: new ol.format.MVT(),
		tileGrid: tile_grid_14,
		tilePixelRatio: 8,
		url: 'https://tile.gbif.org/3857/omt/{z}/{x}/{y}.pbf',
		attributions: [
			'© <a href="https://www.openmaptiles.org/copyright">OpenMapTiles</a>.',
			ol.source.OSM.ATTRIBUTION,
		],
		wrapX: false
	}),
	style: createStyle(),
	visible: false,
});

var raster_style = 'gbif-middle';
layers['EPSG:3857-R'] = new ol.layer.Tile({
	source: new ol.source.TileImage({
		projection: 'EPSG:3857',
		tileGrid: tile_grid_16,
		tilePixelRatio: pixel_ratio,
		url: 'https://tile.gbif.org/3857/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+raster_style,
		attributions: [
			'© <a href="https://www.openmaptiles.org/copyright">OpenMapTiles</a>.',
			ol.source.OSM.ATTRIBUTION,
		],
		wrapX: true
	}),
	visible: true,
});


layers['OccurrenceDensity:3857'] = new ol.layer.VectorTile({
	renderMode: 'image',
	source: new ol.source.VectorTile({
		projection: 'EPSG:3857',
		format: new ol.format.MVT(),
		tileGrid: tile_grid_16,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}.mvt?srs=EPSG:3857&bin=hex&taxonKey=2481433',
		tilePixelRatio: 8,
		attributions: '<a href="https://www.gbif.org/citation-guidelines">GBIF</a>.',
	}),
	style: createDensityStyle(),
	visible: true,
});

layers['OccurrenceDensityRaster:3857'] = new ol.layer.Tile({
	source: new ol.source.TileImage({
		projection: 'EPSG:3857',
		tileGrid: tile_grid_16,
		tilePixelRatio: pixel_ratio,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@'+pixel_ratio+'x.png?srs=EPSG:3857',
		attributions: '<a href="https://www.gbif.org/citation-guidelines">GBIF</a>.',
	}),
	visible: false
});

var map = new ol.Map({
	layers: [
		layers['OSM'],
		layers['EPSG:3857'],
		layers['EPSG:3857-R'],
		layers['OccurrenceDensity:3857'],
		layers['OccurrenceDensityRaster:3857'],
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
		zoom: 1
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

bindInputs('OSM', layers['OSM']);
bindInputs('Grid', layers['Grid']);
bindInputs('EPSG3857', layers['EPSG:3857']);
bindInputs('EPSG3857-R', layers['EPSG:3857-R']);
bindInputs('OccurrenceDensity', layers['OccurrenceDensity:3857']);
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:3857']);

var styleSelect = document.getElementById('EPSG3857_style');
styleSelect.onchange = (function(e) {
	switch (styleSelect.value) {
	case 'debug':
		layers['EPSG:3857'].setStyle(createStyle());
		break;

	case 'mapboxgl':
		fetch('https://labs.gbif.org/klokantech-basic-gl-style/style-cdn.json').then(function(response) {
			response.json().then(function(glStyle) {
				olms.applyStyle(layers['EPSG:3857'], glStyle, 'openmaptiles');
			});
		});
		break;
	}
});

var styleSelectR = document.getElementById('EPSG3857-R_style');
styleSelectR.onchange = (function(e) {
	layers['EPSG:3857-R'].getSource().setUrl('https://tile.gbif.org/3857/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+styleSelectR.value);
	layers['EPSG:3857-R'].getSource().refresh();
});
