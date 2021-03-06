var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var max_zoom = 16;
var tile_size = 512;

var extent = 12367396.2185; // To the Equator
var resolutions = Array(max_zoom + 1).fill().map((_, i) => ( extent / tile_size / Math.pow(2, i-1) ));

var crs = new L.Proj.CRS(
	'EPSG:3031',
	"+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
	{
		origin: [-extent, extent],
		projectedBounds: L.bounds(L.point(-extent, extent), L.point(extent, -extent)),
		resolutions: resolutions
	}
);

var map = L.map('map', {
	crs: crs,
}).setView([-77.85, 166.666667], 6);

L.tileLayer('https://tile.gbif.org/3031/omt/{z}/{x}/{y}@{r}x.png?style=gbif-classic'.replace('{r}', pixel_ratio), {
	tileSize: 512
}).addTo(map);

L.tileLayer('https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@{r}x.png?style=classic.point&srs=EPSG%3A3031'.replace('{r}', pixel_ratio), {
	tileSize: tile_size
}).addTo(map);
