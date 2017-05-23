var pixel_ratio = window.devicePixelRatio || 1;

var max_zoom = 16;
var tile_size = 512;

var map = L.map('map').setView([0, 0], 1);

L.tileLayer('https://tile.gbif.org/3857/omt/{z}/{x}/{y}@'+pixel_ratio+'x.png?style=gbif-classic', {
  minZoom: 1,
	maxZoom: max_zoom + 1,
  zoomOffset: -1,
	tileSize: tile_size
}).addTo(map);
