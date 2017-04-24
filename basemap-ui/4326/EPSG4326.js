proj4.defs('EPSG:4326', "+proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees");

// Configure the WGS84 Plate Careé projection object with an extent,
// and a world extent. These are required for the Graticule.
var wgs84Projection = new ol.proj.Projection({
    code: 'EPSG:4326',
    extent: [-180.0, -90.0, 180.0, 90.0],
    worldExtent: [-180.0, -90.0, 180.0, 90.0]
});

var resolutions = [];
var extent = 180.0;
var tile_size = 512;
var resolutions = Array(17).fill().map((_, i) => ( extent / tile_size / Math.pow(2, i) ));

var layers = [];

layers['ESRI'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileImage({
		projection: 'EPSG:4326',
		// Or https://services.arcgisonline.com/arcgis/rest/services/ESRI_Imagery_World_2D/MapServer/tile/0/0/1
		url: 'http://server.arcgisonline.com/arcgis/rest/services/ESRI_StreetMap_World_2D/MapServer/tile/{z}/{y}/{x}',
		// From http://server.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 16,
			resolutions: resolutions,
			tileSize: [512, 512],
    }),
		wrapX: false
	}),
	visible: false,
	opacity: 1.0/6,
});

layers['Grid'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileDebug({
		projection: 'EPSG:4326',
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 16,
			resolutions: resolutions,
			tileSize: [512, 512],
			origin: [-180, -90]
    }),
		wrapX: false
	})
});

layers['EPSG:4326'] = new ol.layer.VectorTile({
  source: new ol.source.VectorTile({
		projection: 'EPSG:4326',
		format: new ol.format.MVT(),
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 14,
			resolutions: resolutions,
			tileSize: [512, 512],
    }),
		tilePixelRatio: 8,
		url: '/4326/omt/{z}/{x}/{y}.pbf'
  }),
  style: createStyle(),
});

var raster_style = 'gbif-classic';
layers['EPSG:4326-R'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
	source: new ol.source.TileImage({
		projection: 'EPSG:4326',
		url: '/4326/omt/{z}/{x}/{y}@1x.png?style='+raster_style,
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 16,
			resolutions: resolutions,
			tileSize: [512, 512],
    }),
		tilePixelRatio: 1,
		wrapX: false
	}),
	visible: false,
});

layers['OccurrenceDensity:4326'] = new ol.layer.VectorTile({
	renderMode: 'image',
  source: new ol.source.VectorTile({
		projection: 'EPSG:4326',
		format: new ol.format.MVT(),
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 8,
			resolutions: resolutions,
			tileSize: [512, 512],
    }),
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}.mvt?srs=EPSG:4326'
  }),
  style: createDensityStyle()
});

layers['OccurrenceDensityRaster:4326'] = new ol.layer.Tile({
	extent: ol.proj.get('EPSG:4326').getExtent(),
  source: new ol.source.TileImage({
		projection: 'EPSG:4326',
	  tileGrid: new ol.tilegrid.TileGrid({
			extent: ol.proj.get('EPSG:4326').getExtent(),
			minZoom: 0,
			maxZoom: 16,
			resolutions: resolutions,
			tileSize: [512, 512],
    }),
		tilePixelRatio: 1,
		url: 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png?srs=EPSG:4326',
  }),
	visible: true
});

var map = new ol.Map({
	layers: [
		layers['ESRI'],
		layers['EPSG:4326'],
		layers['EPSG:4326-R'],
		layers['OccurrenceDensityRaster:4326'],
		layers['Grid']
	],
	target: 'map',
	view: new ol.View({
		center: [0, 0],
		projection: wgs84Projection,
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
bindInputs('OccurrenceDensityRaster', layers['OccurrenceDensityRaster:4326']);

var progress = new Progress(document.getElementById('progress'));

var source = layers['EPSG:4326'].getSource();

source.on('tileloadstart', function(e) {
  progress.addLoading(e);
});
source.on('tileloadend', function() {
  progress.addLoaded();
});
source.on('tileloaderror', function() {
  progress.addLoaded();
});

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
	layers['EPSG:4326-R'].getSource().setUrl('/4326/omt/{z}/{x}/{y}@4x.png?style='+styleSelectR.value);
	layers['EPSG:4326-R'].getSource().refresh();
});
