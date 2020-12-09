// =====================================================================
// LABELS

// General notes:
// - `text-halo-rasterizer: fast;` gives a noticeable performance
//    boost to render times and is recommended for *all* halos.

// ---------------------------------------------------------------------
// Languages

// This is imported first, from labels-XX.mss


// ---------------------------------------------------------------------
// Fonts

// All fontsets should have a good fallback that covers as many glyphs
// as possible.
@fallback: 'KlokanTech Noto Sans Regular';
@fallback_cjk: 'KlokanTech Noto Sans CJK Regular';
@sans: 'Open Sans Regular', @fallback, @fallback_cjk, 'Roboto', 'Hiragino';
@sans_md: 'Open Sans Semibold', @fallback, @fallback_cjk, 'Roboto', 'Hiragino';
@sans_bd: 'Open Sans Bold', 'KlokanTech Noto Sans Bold', 'KlokanTech Noto Sans CJK Bold', @fallback, 'Roboto', 'Hiragino';
@sans_it: 'Open Sans Italic', @fallback, @fallback_cjk, 'Roboto', 'Hiragino';
@sans_lt_italic: 'Open Sans Light Italic', @fallback, @fallback_cjk, 'Roboto', 'Hiragino';
@sans_lt: 'Open Sans Light', @fallback, @fallback_cjk, 'Roboto', 'Hiragino';


// ---------------------------------------------------------------------
// Countries

// The country labels in MapBox Streets vector tiles are placed by hand,
// optimizing the arrangement to fit as many as possible in densely-
// labeled areas.
// Country labels //
#place[class='country'][zoom>=3][zoom<=10] {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  [name_en='Abkhazia'] { text-name: "''" }
  [name_en='Falkland Islands'] { text-name: @name_falklands_malvinas }
  [name_en='Macedonia'] { text-name: @name_north_macedonia }
  [name_en='Nagorno-Karabakh Republic'] { text-name: "''" }
  [name_en='South Ossetia'] { text-name: "''" }
  [name_en='Swaziland'] { text-name: @name_eswatini }
  [name_en='Transnistria'] { text-name: "''" }
  [name_en='Turkish Republic Of Northern Cyprus'] { text-name: "''" }
  text-face-name: @sans_bd;
  text-placement: point;
  text-size: 10;
  text-fill: @country_text;
  text-halo-fill: @country_halo;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-wrap-width: 20;
  text-wrap-before: true;
  text-line-spacing: -3;
  [rank=1] {
    [zoom=3]  { text-size: 12; text-wrap-width: 60; }
    [zoom=4]  { text-size: 14; text-wrap-width: 90; }
    [zoom=5]  { text-size: 20; text-wrap-width: 120; }
    [zoom>=6] { text-size: 20; text-wrap-width: 120; }
  }
  [rank=2] {
    [zoom=2]  { text-name: [code]; }
    [zoom=3]  { text-size: 11; }
    [zoom=4]  { text-size: 13; }
    [zoom=5]  { text-size: 17; }
    [zoom>=6] { text-size: 20; }
  }
  [rank=3] {
    [zoom=3]  { text-name: [code]; }
    [zoom=4]  { text-size: 11; }
    [zoom=5]  { text-size: 15; }
    [zoom=6]  { text-size: 17; }
    [zoom=7]  { text-size: 18; text-wrap-width: 60; }
    [zoom>=8] { text-size: 20; text-wrap-width: 120; }
  }
  [rank=4] {
    [zoom=5] { text-size: 13; }
    [zoom=6] { text-size: 15; text-wrap-width: 60  }
    [zoom=7] { text-size: 16; text-wrap-width: 90; }
    [zoom=8] { text-size: 18; text-wrap-width: 120; }
    [zoom>=9] { text-size: 20; text-wrap-width: 120; }
  }
  [rank=5] {
    [zoom=5] { text-size: 11; }
    [zoom=6] { text-size: 13; }
    [zoom=7] { text-size: 14; text-wrap-width: 60; }
    [zoom=8] { text-size: 16; text-wrap-width: 90; }
    [zoom>=9] { text-size: 18; text-wrap-width: 120; }
  }
  [rank>=6] {
    [zoom=7] { text-size: 12; }
    [zoom=8] { text-size: 14; }
    [zoom>=9] { text-size: 16; }
  }
}

// State labels //
#place[class='state'][zoom>=4][zoom<=10] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @state_text;
  text-halo-fill: @state_halo;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 10;

  [zoom>=5][zoom<=6] {
    [area>10000] { text-size: 12; }
    [area>50000] { text-size: 14; }
    text-wrap-width: 40;
  }
  [zoom>=7][zoom<=8] {
    text-size: 14;
    [area>50000] { text-size: 16; text-character-spacing: 1; }
    [area>100000] { text-size: 18; text-character-spacing: 3; }
    text-wrap-width: 60;
  }
  [zoom>=9][zoom<=10] {
    text-halo-radius: 2;
    text-size: 16;
    text-character-spacing: 2;
    [area>50000] { text-size: 18; text-character-spacing: 2; }
    text-wrap-width: 100;
  }
}

// City labels with dots for low zoom levels.
// The separate attachment keeps the size of the XML down.
#place::citydots[class='city'][zoom>=4][zoom<=7] {
  // explicitly defining all the `ldir` values wer'e going
  // to use shaves a bit off the final project.xml size
    shield-file: url("cartocss/osm-bright/shield/dot.svg");
    shield-unlock-image: true;
    shield-name: @name;
    [@name=~'^$'] { shield-name: @name_fallback }
    shield-size: 12;
    [zoom=7] { shield-size: 14; }
    shield-face-name: @sans;
    shield-placement: point;
    shield-fill: @text;
    shield-halo-fill: @text_halo_fill;
    shield-halo-radius: 1;
    shield-halo-rasterizer: fast;
}

#place[zoom>=8] {
  text-name: @name;
  text-face-name: @sans;
  text-wrap-width: 120;
  text-wrap-before: true;
  text-fill: @text;
  text-halo-fill: @text_halo_fill;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 10;
  [class='city'] {
  	text-face-name: @sans_md;
    text-size: 16;
    [zoom>=10] {
      text-size: 18;
      text-wrap-width: 140;
    }
    [zoom>=12] {
      text-size: 24;
      text-wrap-width: 180;
    }
    // Hide at largest scales:
    [zoom>=16] { text-name: "''"; }
  }
  [class='town'] {
    text-size: 14;
    [zoom>=12] { text-size: 16; }
    [zoom>=14] { text-size: 20; }
    [zoom>=16] { text-size: 24; }
    // Hide at largest scales:
    [zoom>=18] { text-name: "''"; }
  }
  [class='village'] {
    text-size: 12;
    [zoom>=12] { text-size: 14; }
    [zoom>=14] { text-size: 18; }
    [zoom>=16] { text-size: 22; }
  }
  [class='hamlet'],
  [class='suburb'],
  [class='neighbourhood'] {
    text-fill: @text;
    text-face-name: @sans_bd;
    text-transform: uppercase;
    text-character-spacing: 0.5;
    [zoom>=14] { text-size: 11; }
    [zoom>=15] { text-size: 12; text-character-spacing: 1; }
    [zoom>=16] { text-size: 14; text-character-spacing: 2; }
  }
}

// Place labels
#poi[class='park'][rank<=2],
#poi[class='airport'][rank<=2],
#poi[class='airfield'][rank<=2],
#poi[class='rail'][rank<=2],
#poi[class='school'][rank<=2],
#poi[class='hospital'][rank<=2] {
  text-face-name: @sans_bold;
  text-allow-overlap: false;
  text-name: @name;
  text-size: 11;
  text-line-spacing: -2;
  text-min-distance: 50;
  text-wrap-width: 60;
  text-halo-fill: @land;
  text-halo-radius: 1;
  text-fill: @text;
}


// ---------------------------------------------------------------------
// Roads

#transportation_name {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  text-placement: line;  // text follows line path
  text-face-name: @sans;
  text-fill: @text;
  text-halo-fill: @text_halo_fill;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 12;
  text-avoid-edges: true;  // prevents clipped labels at tile edges
  [zoom>=15] { text-size: 13; }
}

#water_name[zoom>=3] {
  text-face-name: @sans_bold;
  text-allow-overlap: false;
  text-name: @name;
  text-size: 13;
  text-line-spacing: -2;
  text-min-distance: 50;
  text-wrap-width: 60;
  text-halo-fill: @land;
  text-halo-radius: 1;
  text-fill: @text;
}

// #graticules {
//   text-name: @name;
//   [@name=~'^$'] { text-name: @name_fallback }
//   text-placement: line;  // text follows line path
//   text-face-name: @sans;
//   text-fill: @text;
//   text-halo-fill: @text_halo_fill;
//   text-halo-radius: 1;
//   text-halo-rasterizer: fast;
//   text-size: 10;
//   text-avoid-edges: true;  // prevents clipped labels at tile edges
// }

#contour {
  text-name: '[elevation]';
  text-placement: line;
  text-face-name: @sans;
  text-fill: #800000;
  text-size: 10;
}

#bathymetry {
  text-name: '[depth]';
  text-placement: line;
  text-face-name: @sans;
  text-fill: #000080;
  text-size: 10;
}
