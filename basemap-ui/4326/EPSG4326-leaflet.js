var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var max_zoom = 16;
var tile_size = 512;

var extent = 180.0;
var resolutions = Array(max_zoom + 1).fill().map((_, i) => ( extent / tile_size / Math.pow(2, i) ));

var crs = new L.Proj.CRS(
	'EPSG:4326',
	'+proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees',
	{
		origin: [-180.0, 90.0],
		bounds: L.bounds([-180, 90], [180, -90]),
		resolutions: resolutions
	}
);

var map = L.map('map', {
	crs: crs
}).setView([0, 0], 1);

L.tileLayer('https://tile.gbif.org/4326/omt/{z}/{x}/{y}@{r}x.png?style=gbif-classic'.replace('{r}', pixel_ratio), {
	tileSize: tile_size
}).addTo(map);

L.tileLayer('https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@{r}x.png?style=classic.point&srs=EPSG%3A4326'.replace('{r}', pixel_ratio), {
	tileSize: tile_size
}).addTo(map);
