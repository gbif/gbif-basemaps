// ---------------------------------------------------------------------
// Common Colors

// You don't need to set up @variables for every color, but it's a good
// idea for colors you might be using in multiple places or as a base
// color for a variety of tints.
// Eg. @water is used in the #water and #waterway layers directly, but
// also in the #water_label and #waterway_label layers inside a color
// manipulation function to get a darker shade of the same hue.
@land: #f8f4f0;
@water: #a0c8f0;

@wetland: #57945C;
@trees: #8DB580;
@grass: #B7D0A0;
@farm: #D9E5BD;
@park: #F0F2D5;
@sand: #f7f1d3;
@ice: white;

@state_text:        #765;
@state_halo:        @place_halo;

Map {
  background-color:#e5e9cd;
}

#graticules {
  line-color: #aaa;
  line-width: 1;
  line-dasharray: 5,3;
}

// ---------------------------------------------------------------------
// Political boundaries

#boundary {
  opacity: 0.5;
  line-join: round;
  line-color: #446;
  // Countries
  [admin_level=2] {
    line-width: 0.8;
    line-cap: round;
    [zoom>=4] { line-width: 1.2; }
    [zoom>=6] { line-width: 2; }
    [zoom>=8] { line-width: 4; }
    [disputed=1] { line-dasharray: 4,4; }
  }
}
// States / Provices / Subregions
#place[class='state'][zoom>=4][zoom<=10] {
  text-name: @name;
  text-face-name: @sans_lt;
  text-placement: point;
  text-fill: @state_text;
  text-halo-fill: fadeout(lighten(@land,5%),50%);
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 9;
  [zoom>=5][zoom<=6] {
    text-size: 12;
    text-wrap-width: 40;
  }
  [zoom>=7][zoom<=8] {
    text-size: 14;
    text-wrap-width: 60;
  }
  [zoom>=9][zoom<=10] {
    text-halo-radius: 2;
    text-size: 16;
    text-character-spacing: 2;
    text-wrap-width: 100;
  }
}

// ---------------------------------------------------------------------
// Water Features

#water {
  polygon-fill: @water - #111;
  // Map tiles are 256 pixels by 256 pixels wide, so the height
  // and width of tiling pattern images must be factors of 256.
  polygon-pattern-file: url(cartocss/osm-bright/pattern/wave.png);
  [zoom<=5] {
    // Below zoom level 5 we use Natural Earth data for water,
    // which has more obvious seams that need to be hidden.
    polygon-gamma: 0.4;
  }
  ::blur {
    // This attachment creates a shadow effect by creating a
    // light overlay that is offset slightly south. It also
    // create a slight highlight of the land along the
    // southern edge of any water body.
    polygon-fill: #f0f0ff;
    comp-op: soft-light;
    image-filters: agg-stack-blur(1,1);
    image-filters-inflate: true;
    polygon-geometry-transform: translate(0,1);
    polygon-clip: false;
  }
}

#waterway {
  line-color: @water * 0.9;
  line-cap: round;
  line-width: 1.0;
  [class='river'] {
    [zoom>=12] { line-width: 1.5; }
    [zoom>=14] { line-width: 2.5; }
    [zoom>=16] { line-width: 3.5; }
  }
  [class='stream'],
  [class='stream_intermittent'],
  [class='canal'] {
    [zoom>=14] { line-width: 1.5; }
    [zoom>=16] { line-width: 2.5; }
    [zoom>=18] { line-width: 3.5; }
  }
  [class='stream_intermittent'] { line-dasharray: 6,2,2,2; }
}

// ---------------------------------------------------------------------
// Landuse areas

#landcover {
  opacity: 0.5;
  [class='farmland'] { polygon-fill: @farm; }
  [class='wetland'] {
    polygon-fill: @wetland;
    polygon-pattern-file: url(cartocss/gbif-natural/pattern/wetland.png);
  }
  [class='ice'] { polygon-fill: white; }
  [class='grass'] {
    polygon-fill: @grass;
    polygon-pattern-file: url(cartocss/gbif-natural/pattern/grass.png);
  }
  [class='wood'] {
    polygon-fill: @trees;
    polygon-gamma: 0.5;
    polygon-pattern-file: url(cartocss/gbif-natural/pattern/forest.png);
  }
  [class='sand'] {
    polygon-fill: @sand;
    polygon-gamma: 0.5;
    polygon-pattern-file: url(cartocss/gbif-natural/pattern/sand.png);
  }
  [class='village_green'],
  [class='recreation_ground'],
  [class='park'] { polygon-fill: @park; }
}

#landuse {
  [class='bus_station'],
  [class='railway'] { polygon-fill: #bbb; }

  [class='military'] {
    opacity: 0.666;
    polygon-fill: #dfbbdf;
    line-color: #dfbbdf;
    line-width: 2.0;
  }

  [class='dam'],
  [class='construction'],
  [class='industrial'],
  [class='retail'],
  [class='restaurant'],
  [class='commercial'] { polygon-fill: #c7c7c7; }

  [class='suburb'],
  [class='neighbourhood'],
  [class='residential'] { polygon-fill: #e9e9e9; }

  [class='cemetery'] { polygon-fill: mix(#d8e8c8, #ddd, 25%); }

  [class='hospital'] { polygon-fill: #fde; }

  [class='pitch'],
  [class='playground'],
  [class='stadium'],
  [class='track'],
  [class='theme_park'],
  [class='zoo'],
  [class='kindergarten'],
  [class='library'],
  [class='college'],
  [class='university'],
  [class='school'] { polygon-fill: #f0e8f8; }
}

#park {
  ::overlay {
    opacity: 0.25;
    polygon-fill: orange;
    [class='nature_reserve'] { polygon-fill: #9ab78b; }
    [class='national_park'] { polygon-fill: #8cb78b; }
  }
}

// ---------------------------------------------------------------------
// Buildings

#building [zoom<=17]{
  // At zoom level 13, only large buildings are included in the
  // vector tiles. At zoom level 14+, all buildings are included.
  polygon-fill: darken(@land, 50%);
  opacity: 0.1;
}
// Seperate attachments are used to draw buildings with depth
// to make them more prominent at high zoom levels
#building [zoom>=18]{
::wall { polygon-fill:darken(@land, 20%); }
::roof {
  polygon-fill: darken(@land, 5%);
  polygon-geometry-transform:translate(-1,-1.5);
  polygon-clip:false;
  line-width: 0.5;
  line-color: mix(@land, #000, 85);
  line-geometry-transform:translate(-1,-1.5);
  line-clip:false;
 }
}

// ---------------------------------------------------------------------
// Aeroways

#aeroway [zoom<13] {
  ['mapnik::geometry_type'=2] {
    line-color: #aeaeae;
    [class='runway'] { line-width: 5; }
    [class='taxiway'] {
      line-width: 1;
      [zoom>=15] { line-width: 2; }
    }
  }
}

#aeroway [zoom>=13] {
  ['mapnik::geometry_type'=2] {
    line-color: #484848;
    [class='runway'] { line-width: 5; }
    [class='taxiway'] {
      line-width: 1;
      [zoom>=15] { line-width: 2; }
    }
  }
  ['mapnik::geometry_type'=3] {
    ::overlay {
      opacity: 0.75;
      polygon-fill: #d1d1d1;
      // [class='apron'] {
      //   polygon-fill: #dadada;
      // }
    }
  }
}
