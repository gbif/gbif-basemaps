proj4.defs("EPSG:3575", "+proj=laea +lat_0=90 +lon_0=10 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs");

var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var halfWidth = Math.sqrt(2) * 6371007.2;
var extent = [-halfWidth, -halfWidth, halfWidth, halfWidth];
ol.proj.get("EPSG:3575").setExtent(extent);
var tile_size = 512;
var max_zoom = 20;
var resolutions = Array.from(new Array(max_zoom+1), (x,i) => (halfWidth/(tile_size*Math.pow(2,i-1))));

var tile_grid_3575 = new ol.tilegrid.TileGrid({
  extent: extent,
  origin: [-halfWidth,halfWidth],
  minZoom: 0,
  maxZoom: max_zoom,
  resolutions: resolutions,
  tileSize: tile_size,
});

// 3875 source vectors
var m_vectors = new ol.layer.VectorTile({
  renderMode: 'image',
  source: new ol.source.VectorTile({
    projection: 'EPSG:3575',
    format: new ol.format.MVT(),
    url: 'https://tile.gbif.org/3575/omt/{z}/{x}/{y}.pbf',
    tileGrid: tile_grid_3575,
    tilePixelRatio: 8
  }),
  style: createStyle(),
  visible: true,
});

var layers = [
  'osm-bright',
  'gbif-classic',
  'gbif-dark',
  'gbif-light',

  'gbif-natural',
  'gbif-violet',
  'gbif-tuatara',
  'gbif-geyser',

  'gbif-middle',
].map((style) => (
  new ol.layer.Tile({
    name: style,
    source: new ol.source.TileImage({
      projection: 'EPSG:3575',
      tileGrid: tile_grid_3575,
      tilePixelRatio: pixel_ratio,
      url: '/3575/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+style,
      wrapX: true
    })
  })
));

// View setup
var view3575 = new ol.View({
  center: [0, 0],
  projection: 'EPSG:3575',
  zoom: 1
});

// Map definitions
var mapV = new ol.Map({
  layers: [m_vectors],
  target: 'mapV',
  view: view3575
});

var map1 = new ol.Map({layers: [layers[0]], target: 'map1', view: view3575});
var map2 = new ol.Map({layers: [layers[1]], target: 'map2', view: view3575});
var map3 = new ol.Map({layers: [layers[2]], target: 'map3', view: view3575});
var map4 = new ol.Map({layers: [layers[3]], target: 'map4', view: view3575});
var map5 = new ol.Map({layers: [layers[4]], target: 'map5', view: view3575});
var map6 = new ol.Map({layers: [layers[5]], target: 'map6', view: view3575});
var map7 = new ol.Map({layers: [layers[6]], target: 'map7', view: view3575});
var map8 = new ol.Map({layers: [layers[7]], target: 'map8', view: view3575});
var map9 = new ol.Map({layers: [layers[8]], target: 'map9', view: view3575});

// Permalink URL anchors, 99% based on https://openlayers.org/en/latest/examples/permalink.html

// default zoom, center and rotation
var zoom3575 = 3;
var center3575 = [0, 0];
var rotation3575 = 0;

if (window.location.hash !== '') {
  // try to restore center, zoom-level and rotation from the URL
  var hash = window.location.hash;
  var hash3575 = hash.replace('#map3575=', '');
  var parts3575 = hash3575.split('/');
  if (parts3575.length === 4) {
    zoom3575 = parseInt(parts3575[0], 10);
    center3575 = [
      parseFloat(parts3575[1]),
      parseFloat(parts3575[2])
    ];
    rotation3575 = parseFloat(parts3575[3]);
  }
  console.log(center3575, zoom3575, rotation3575);
}


view3575.setCenter(center3575);
view3575.setZoom(zoom3575);
view3575.setRotation(rotation3575);

var shouldUpdate = true;
var updatePermalink = function() {
  if (!shouldUpdate) {
    // do not update the URL when the view was changed in the 'popstate' handler
    shouldUpdate = true;
    return;
  }

  var center3575 = view3575.getCenter();
  var hash3575 = 'map3575=' +
      view3575.getZoom() + '/' +
      Math.round(center3575[0] * 100) / 100 + '/' +
      Math.round(center3575[1] * 100) / 100 + '/' +
      view3575.getRotation();
  var state = {
    zoom3575: view3575.getZoom(),
    center3575: view3575.getCenter(),
    rotation3575: view3575.getRotation()
  };
  window.history.pushState(state, 'map', '#'+hash3575);
};

mapV.on('moveend', updatePermalink);

// restore the view state when navigating through the history, see
// https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
window.addEventListener('popstate', function(event) {
  if (event.state === null) {
    return;
  }
  view3575.setCenter(event.state.center3575);
  view3575.setZoom(event.state.zoom3575);
  view3575.setRotation(event.state.rotation3575);
  shouldUpdate = false;
});
