var layers = [];

layers['OSM'] = new ol.layer.Tile({
	source: new ol.source.OSM({
		wrapX: false
	}),
	visible: false,
	opacity: 1.0/6,
});

layers['Grid'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:3857').getExtent(),
	source: new ol.source.TileDebug({
		projection: 'EPSG:3857',
 		tileGrid: ol.tilegrid.createXYZ({
			maxZoom: 16,
			tileSize: [512, 512]
		}),
		tilePixelRatio: 8,
		wrapX: false
	})
});

layers['EPSG:3857'] = new ol.layer.VectorTile({
  source: new ol.source.VectorTile({
		projection: 'EPSG:3857',
		format: new ol.format.MVT(),
 		tileGrid: ol.tilegrid.createXYZ({
			maxZoom: 14,
			tileSize: [512, 512]
		}),
		tilePixelRatio: 8,
		url: '/3857/omt/{z}/{x}/{y}.pbf',
		wrapX: false
  }),
  style: createStyle(),
});

var raster_style = 'gbif-classic';
layers['EPSG:3857-R'] = new ol.layer.Tile({
	source: new ol.source.TileImage({
		projection: 'EPSG:3857',
 		tileGrid: ol.tilegrid.createXYZ({
			maxZoom: 16,
			tileSize: 512
		}),
		tilePixelRatio: 1,
		url: '/3857/omt/{z}/{x}/{y}@1x.png?style='+raster_style,
		wrapX: false
	}),
	visible: true,
});

layers['OccurrenceDensity:3857'] = new ol.layer.VectorTile({
	renderMode: 'image',
  source: new ol.source.VectorTile({
		projection: 'EPSG:3857',
		format: new ol.format.MVT(),
		tilePixelRatio: 1,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}.mvt?srs=EPSG:3857'
  }),
  style: createDensityStyle()
});

layers['OccurrenceDensityRaster:3857'] = new ol.layer.Tile({
  source: new ol.source.TileImage({
		projection: 'EPSG:3857',
 		tileGrid: ol.tilegrid.createXYZ({
			maxZoom: 16,
			tileSize: 512
		}),
		tilePixelRatio: 1,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png?srs=EPSG:3857'
  }),
	visible: false
});

var map = new ol.Map({
	layers: [
		layers['OSM'],
		layers['EPSG:3857'],
		layers['EPSG:3857-R'],
		layers['OccurrenceDensityRaster:3857'],
		layers['Grid']
	],
	target: 'map',
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
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:3857']);

var progress = new Progress(document.getElementById('progress'));

var source = layers['EPSG:3857'].getSource();

source.on('tileloadstart', function(e) {
  progress.addLoading(e);
});
source.on('tileloadend', function() {
  progress.addLoaded();
});
source.on('tileloaderror', function() {
  progress.addLoaded();
});

var styleSelect = document.getElementById('EPSG3857_style');
styleSelect.onchange = (function(e) {
	switch (styleSelect.value) {
	case 'debug':
		layers['EPSG:3857'].setStyle(createStyle());
		break;

	case 'mapboxgl':
		fetch('https://openmaptiles.github.io/klokantech-basic-gl-style/style-cdn.json').then(function(response) {
			response.json().then(function(glStyle) {
				olms.applyStyle(layers['EPSG:3857'], glStyle, 'openmaptiles');
			});
		});
		break;
	}
});

var styleSelectR = document.getElementById('EPSG3857-R_style');
styleSelectR.onchange = (function(e) {
	layers['EPSG:3857-R'].getSource().setUrl('/3857/omt/{z}/{x}/{y}@4x.png?style='+styleSelectR.value);
	layers['EPSG:3857-R'].getSource().refresh();
});
