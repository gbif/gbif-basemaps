// ---------------------------------------------------------------------
// Common Colors

@land: #02393D;
@water: #7173AB;

@state_text:        #765;
@state_halo:        @place_halo;

@name: '[name]';

@fallback: 'Open Sans Regular';
@sans: 'Open Sans Regular', @fallback;
@sans_lt: 'Open Sans Regular', @fallback;

Map {
  background-color: @land;
}

// ---------------------------------------------------------------------
// Political boundaries

// #boundary {
//  opacity: 0.5;
//  line-join: round;
//  line-color: #ff0;
//  // Countries
//  [admin_level=2] {
//    line-width: 0.8;
//    line-cap: round;
//    [zoom>=4] { line-width: 1.2; }
//    [zoom>=6] { line-width: 2; }
//    [zoom>=8] { line-width: 4; }
//    [disputed=1] { line-dasharray: 4,4; }
//  }
// }

// States / Provices / Subregions
// #place {
//  text-name: @name;
//  text-face-name: @sans_lt;
//  text-placement: point;
//  text-fill: @state_text;
//  text-halo-fill: fadeout(lighten(@land,5%),50%);
//  text-halo-radius: 1;
//  text-halo-rasterizer: fast;
//  text-size: 9;
//  [zoom>=5][zoom<=6] {
//    text-size: 12;
//    text-wrap-width: 40;
//  }
//  [zoom>=7][zoom<=8] {
//    text-size: 14;
//    text-wrap-width: 60;
//  }
//  [zoom>=9][zoom<=10] {
//    text-halo-radius: 2;
//    text-size: 16;
//    text-character-spacing: 2;
//    text-wrap-width: 100;
//  }
// }

// ---------------------------------------------------------------------
// Water Features

#water {
  polygon-fill: @water; // - #111;
  // Map tiles are 256 pixels by 256 pixels wide, so the height
  // and width of tiling pattern images must be factors of 256.
//  polygon-pattern-file: url(pattern/wave.png);
  [zoom<=5] {
    // Below zoom level 5 we use Natural Earth data for water,
    // which has more obvious seams that need to be hidden.
    polygon-gamma: 0.4;
  }
//  ::blur {
//    // This attachment creates a shadow effect by creating a
//    // light overlay that is offset slightly south. It also
//    // create a slight highlight of the land along the
//    // southern edge of any water body.
//    polygon-fill: #f0f0ff;
//    comp-op: soft-light;
//    image-filters: agg-stack-blur(1,1);
//    image-filters-inflate: true;
//    polygon-geometry-transform: translate(0,1);
//    polygon-clip: false;
//  }
}

#waterway {
  line-color: @water; // * 0.9;
  line-cap: round;
  line-width: 0.5;
  [class='river'] {
    [zoom>=12] { line-width: 1; }
    [zoom>=14] { line-width: 2; }
    [zoom>=16] { line-width: 3; }
  }
  [class='stream'],
  [class='stream_intermittent'],
  [class='canal'] {
    [zoom>=14] { line-width: 1; }
    [zoom>=16] { line-width: 2; }
    [zoom>=18] { line-width: 3; }
  }
  [class='stream_intermittent'] { line-dasharray: 6,2,2,2; }
}

// ---------------------------------------------------------------------
// Landuse areas

#landcover {
  //[class='ice'] { polygon-fill: #00565C; }
  ::overlay {
    // Landuse classes look better as a transparent overlay.
    opacity: 0.8;
    [class='ice'] { polygon-fill: #004347; polygon-gamma: 0.5; }
  }
}

//#landuse {
  // Land-use and land-cover are not well-separated concepts in
  // OpenStreetMap, so this layer includes both. The 'class' field
  // is a highly opinionated simplification of the myriad LULC
  // tag combinations into a limited set of general classes.
//  [class='cemetery'] { polygon-fill: mix(#d8e8c8, #ddd, 25%); }
//  [class='hospital'] { polygon-fill: #fde; }
//  [class='school'] { polygon-fill: #f0e8f8; }
//}

// ---------------------------------------------------------------------
// Buildings

//#building [zoom<=17]{
  // At zoom level 13, only large buildings are included in the
  // vector tiles. At zoom level 14+, all buildings are included.
//  polygon-fill: darken(@land, 50%);
//  opacity: 0.1;
//}
// Seperate attachments are used to draw buildings with depth
// to make them more prominent at high zoom levels
//#building [zoom>=18]{
//::wall { polygon-fill:mix(@land, #000, 85); }
//::roof {
//  polygon-fill: darken(@land, 5%);
//  polygon-geometry-transform:translate(-1,-1.5);
//  polygon-clip:false;
//  line-width: 0.5;
//  line-color: mix(@land, #000, 85);
//  line-geometry-transform:translate(-1,-1.5);
//  line-clip:false;
// }
//}

// ---------------------------------------------------------------------
// Aeroways

//#aeroway [zoom>=12] {
//  ['mapnik::geometry_type'=2] {
//    line-color: @land * 0.96;
//    [class='runway'] { line-width: 5; }
//    [class='taxiway'] {
//      line-width: 1;
//      [zoom>=15] { line-width: 2; }
//    }
//  }
//  ['mapnik::geometry_type'=3] {
//    polygon-fill: @land * 0.96;
//    [class='apron'] {
//      polygon-fill: @land * 0.98;
//    }
//  }
//}
