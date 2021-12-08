var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var tile_size = 512;
var max_zoom = 20;

var tile_grid_3857 = new ol.tilegrid.createXYZ({
  minZoom: 0,
  maxZoom: 18,
  tileSize: tile_size,
});

// 3875 source vectors
var m_vectors = new ol.layer.VectorTile({
  renderMode: 'image',
  source: new ol.source.VectorTile({
    format: new ol.format.MVT(),
    url: 'https://tile.gbif.org/3857/omt/{z}/{x}/{y}.pbf',
    tileGrid: tile_grid_3857,
    tilePixelRatio: 8
  }),
  style: createStyle(),
  visible: true,
});

var layers = [
  'osm-bright',
  'gbif-classic',
  'gbif-light',
  'gbif-dark',

  'gbif-natural',
  'gbif-violet',
  'gbif-geyser',
  'gbif-tuatara',

  'gbif-middle',
].map((style) => (
  new ol.layer.Tile({
    name: style,
    source: new ol.source.TileImage({
      tileGrid: tile_grid_3857,
      tilePixelRatio: pixel_ratio,
      url: '/3857/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style='+style,
      wrapX: true
    })
  })
));

// View setup
var view3857 = new ol.View({
  center: [0, 0],
  projection: 'EPSG:3857',
  zoom: 4
});

// Map definitions
var mapV = new ol.Map({
  layers: [m_vectors],
  target: 'mapV',
  view: view3857
});

var map1 = new ol.Map({layers: [layers[0]], target: 'map1', view: view3857});
var map2 = new ol.Map({layers: [layers[1]], target: 'map2', view: view3857});
var map3 = new ol.Map({layers: [layers[2]], target: 'map3', view: view3857});
var map4 = new ol.Map({layers: [layers[3]], target: 'map4', view: view3857});
var map5 = new ol.Map({layers: [layers[4]], target: 'map5', view: view3857});
var map6 = new ol.Map({layers: [layers[5]], target: 'map6', view: view3857});
var map7 = new ol.Map({layers: [layers[6]], target: 'map7', view: view3857});
var map8 = new ol.Map({layers: [layers[7]], target: 'map8', view: view3857});
var map9 = new ol.Map({layers: [layers[8]], target: 'map9', view: view3857});

// Permalink URL anchors, 99% based on https://openlayers.org/en/latest/examples/permalink.html

// default zoom, center and rotation
var zoom3857 = 3;
var center3857 = [0, 0];
var rotation3857 = 0;

if (window.location.hash !== '') {
  // try to restore center, zoom-level and rotation from the URL
  var hash = window.location.hash;
  var hash3857 = hash.replace('#map3857=', '');
  var parts3857 = hash3857.split('/');
  if (parts3857.length === 4) {
    zoom3857 = parseInt(parts3857[0], 10);
    center3857 = [
      parseFloat(parts3857[1]),
      parseFloat(parts3857[2])
    ];
    rotation3857 = parseFloat(parts3857[3]);
  }
}

view3857.setCenter(center3857);
view3857.setZoom(zoom3857);
view3857.setRotation(rotation3857);

var shouldUpdate = true;
var updatePermalink = function() {
  if (!shouldUpdate) {
    // do not update the URL when the view was changed in the 'popstate' handler
    shouldUpdate = true;
    return;
  }

  var center3857 = view3857.getCenter();
  var hash3857 = 'map3857=' +
      view3857.getZoom() + '/' +
      Math.round(center3857[0] * 100) / 100 + '/' +
      Math.round(center3857[1] * 100) / 100 + '/' +
      view3857.getRotation();
  var state = {
    zoom3857: view3857.getZoom(),
    center3857: view3857.getCenter(),
    rotation3857: view3857.getRotation()
  };
  window.history.replaceState(state, 'map', '#'+hash3857);
};

mapV.on('moveend', updatePermalink);

// restore the view state when navigating through the history, see
// https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
window.addEventListener('popstate', function(event) {
  if (event.state === null) {
    return;
  }
  view3857.setCenter(event.state.center3857);
  view3857.setZoom(event.state.zoom3857);
  view3857.setRotation(event.state.rotation3857);
  shouldUpdate = false;
});
