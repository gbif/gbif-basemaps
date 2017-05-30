var pixel_ratio = parseInt(window.devicePixelRatio) || 1;

var max_zoom = 16;
var tile_size = 512;

var extent = Math.sqrt(2) * 6371007.2;
var resolutions = Array(max_zoom + 1).fill().map((_, i) => ( extent / tile_size / Math.pow(2, i-1) ));

var crs = new L.Proj.CRS(
	'EPSG:3575',
	'+proj=laea +lat_0=90 +lon_0=10 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs',
	{
		origin: [-extent, extent],
		projectedBounds: L.bounds(L.point(-extent, extent), L.point(extent, -extent)),
		resolutions: resolutions
	}
);

var map = L.map('map', {
	crs: crs,
}).setView([51.6, -2.8], 6);

// This gets round a bug, when Leaflet tries to find the coordinates for pixels outside the projection (e.g. top left corner of top left tile).
// https://github.com/kartena/Proj4Leaflet/issues/82
// Restricting the view is probably necessary to avoid the problem properly.  Or fixing the problem properly.
try {
	//L.tileLayer('../512.png?{z} {x} {y}', {
	L.tileLayer('https://tile.gbif.org/3575/omt/{z}/{x}/{y}@{r}x.png?style=gbif-classic'.replace('{r}', pixel_ratio), {
		tileSize: tile_size,
		minZoom: 1,
		maxZoom: 16
	}).addTo(map);

  L.tileLayer('https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@{r}x.png?style=classic.point&srs=EPSG%3A3575'.replace('{r}', pixel_ratio), {
	  tileSize: tile_size,
    minZoom: 1,
    maxZoom: 16
  }).addTo(map);
}
catch (err) {
	console.error(err);
}
