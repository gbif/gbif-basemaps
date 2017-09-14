var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var max_zoom = 16;
var tile_size = 512;

var map = L.map('map').setView([0, 0], 1);

L.tileLayer('https://tile.gbif.org/3857/omt/{z}/{x}/{y}@{r}x.png?style=gbif-classic'.replace('{r}', pixel_ratio), {
  minZoom: 1,
	maxZoom: max_zoom + 1,
  zoomOffset: -1,
	tileSize: tile_size
}).addTo(map);

L.tileLayer('https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@{r}x.png?style=classic.point&srs=EPSG%3A3857'.replace('{r}', pixel_ratio), {
  minZoom: 1,
	maxZoom: max_zoom + 1,
  zoomOffset: -1,
	tileSize: tile_size
}).addTo(map);
