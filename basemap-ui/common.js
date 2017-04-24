String.prototype.hashCode = function() {
	var hash = 5381;
	for (var i = 0; i < this.length; i++) {
		hash = ((hash << 5) + hash) + this.charCodeAt(i); /* hash * 33 + c */
	}
	return hash;
};

function layerColour(name, transparency) {
	switch(name) {
	case 'aeroway':
		return "rgba(234,234,234,0,"+transparency+")";
	case 'boundary':
		return "rgba(192,192,192,"+transparency+")";
	case 'building':
		return "rgba(128,128,0,"+transparency+")";
	case 'contour':
		return "rgba(222,184,135,"+transparency+")";
	case 'housenumber':
		return "rgba(64,64,0,"+transparency+")";
	case 'landcover':
		return "rgba(0,256,0,"+transparency+")";
	case 'landuse':
		return "rgba(128,256,0,"+transparency+")";
	case 'park':
		return "rgba(0,256,128,"+transparency+")";
	case 'place':
		return "rgba(256,0,0,"+transparency+")";
	case 'poi':
		return "rgba(256,0,128,"+transparency+")";
	case 'transportation':
		return "rgba(64,64,64,"+transparency+")";
	case 'transportation_name':
		return "rgba(32,32,32,"+transparency+")";
	case 'water':
		return "rgba(32,32,256,"+transparency+")";
	case 'water_name':
		return "rgba(0,0,64,0,"+transparency+")";
	case 'waterway':
		return "rgba(0,0,256,"+transparency+")";
	default:
		console.log("Unknown layer", name);
		return "rgba(0,0,0,"+transparency+")";
	}
}

var colours = ['red', 'blue', 'green', 'orange'];

var i = 0;

function createStyle() {
	var point = new ol.style.Style({
		image: new ol.style.Circle({
			fill: new ol.style.Fill({color: '#22bbff'}),
			radius: 5
		}),
		fill: new ol.style.Fill({color: '#22bbff'})
	});

	var fill = new ol.style.Fill({color: ''});
	var stroke = new ol.style.Stroke({color: '', width: 1});
	var polygon = new ol.style.Style({fill: fill});
	var strokedPolygon = new ol.style.Style({fill: fill, stroke: stroke});
	var line = new ol.style.Style({stroke: stroke});
	var text = new ol.style.Style({text: new ol.style.Text({
		text: '', fill: fill, stroke: stroke, font: '16px "Open Sans", "Arial Unicode MS"'
	})});

	var styles = [];
	return function(feature, resolution) {
		var length = 0;
		var geom = feature.getGeometry()
		var type = feature.getType();
		var layer = feature.get('layer');
		if (type == 'Point') {
			text.getText().setText(feature.get('name'));
			fill.setColor(layerColour(layer, '0.5'));
			stroke.setColor(layerColour(layer, '0.8'));
			stroke.setWidth(1);

			styles[length++] = text;
		}
		else if (type == 'LineString' || type == 'MultiLineString') {
			fill.setColor(layerColour(layer, '0.5'));
			stroke.setColor(layerColour(layer, '0.8'));
			stroke.setWidth(1);
			styles[length++] = line;
		}
		else if (type == 'Polygon') {
			fill.setColor(layerColour(layer, '0.5'));
			stroke.setColor(layerColour(layer, '0.8'));
			stroke.setWidth(0.5);
			styles[length++] = strokedPolygon;
		}
		styles.length = length;
		return styles;
	};
}

densityColours = ["#FFFF00", "#FFCC00", "#FF9900", "#FF6600", "#FF3300", "#FF0000"];

function createDensityStyle() {
	var point = new ol.style.Style({
		image: new ol.style.Circle({
			fill: new ol.style.Fill({color: '#FF0000'}),
			radius: 1
		}),
		fill: new ol.style.Fill({color: '#FF0000'})
	});

	var styles = [];
	return function(feature, resolution) {
		var length = 0;
		//console.log(feature);
		var magnitude = Math.trunc(Math.min(5, Math.floor(Math.log(feature.get('total'))))) - 1;
		//console.log("Colour ", magnitude, densityColours[magnitude]);
		styles[length++] = point;
		// styles[length++] = new ol.style.Style({
		// 	image: new ol.style.Circle({
		// 		fill: new ol.style.Fill({color: densityColours[magnitude]}),
		// 		radius: 1
		// 	}),
		// 	fill: new ol.style.Fill({color: densityColours[magnitude]})
		// });
		styles.length = length;
		return styles;
	};
}

/**
 * Renders a progress bar.
 * @param {Element} el The target element.
 * @constructor
 */
function Progress(el) {
        this.el = el;
        this.loading = 0;
        this.loaded = 0;
}

var recentTiles = [];

/**
 * Increment the count of loading tiles.
 */
Progress.prototype.addLoading = function(e) {
	recentTiles.push(e.tile.url_);
	while (recentTiles.length > 10) { recentTiles.shift(); }
	document.getElementById('recentTiles').innerHTML = recentTiles.join('\n');
        if (this.loading === 0) {
		this.show();
        }
        ++this.loading;
        this.update();
};

/**
 * Increment the count of loaded tiles.
 */
Progress.prototype.addLoaded = function() {
        var this_ = this;
        setTimeout(function() {
		++this_.loaded;
		this_.update();
        }, 100);
};

/**
 * Update the progress bar.
 */
Progress.prototype.update = function() {
        var width = (this.loaded / this.loading * 100).toFixed(1) + '%';
        this.el.style.width = width;
        if (this.loading === this.loaded) {
		this.loading = 0;
		this.loaded = 0;
		var this_ = this;
		//setTimeout(function() {
		//	this_.hide();
		//}, 500);
        }
};

/**
 * Show the progress bar.
 */
Progress.prototype.show = function() {
        this.el.style.visibility = 'visible';
};

/**
 * Hide the progress bar.
 */
Progress.prototype.hide = function() {
        if (this.loading === this.loaded) {
		this.el.style.visibility = 'hidden';
		this.el.style.width = 0;
        }
};