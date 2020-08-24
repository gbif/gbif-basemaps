// ---------------------------------------------------------------------
// Fonts

// All fontsets should have a good fallback that covers as many glyphs
// as possible.
@fallback: 'KlokanTech Noto Sans Regular';
@fallback_cjk: 'KlokanTech Noto Sans CJK Regular';
@sans: 'Roboto Regular', @fallback, @fallback_cjk;
@sans_bold: 'Roboto Medium', @fallback, @fallback_cjk;
@sans_md: 'Roboto Medium', @fallback, @fallback_cjk;
@sans_bd: 'Roboto Bold', 'KlokanTech Noto Sans Bold', 'KlokanTech Noto Sans CJK Bold', @fallback;
@sans_it: 'Roboto Italic', @fallback, @fallback_cjk;
@sans_lt_italic: 'Roboto Light Italic', @fallback, @fallback_cjk;
@sans_lt: 'Roboto Light', @fallback, @fallback_cjk;


Map {
  background-color: transparent;
}

#world_extent {
  line-width: 1.5;
  line-color: #aaa;
  polygon-fill: @land;
}

// #graticules {
//   line-color: @politicalBoundaries;
//   line-width: 1;
//   line-dasharray: 5,3;
// }

// Political boundaries //
#boundary[admin_level=2] {
  line-join: round;
  line-color: @politicalBoundaries;
  line-width: 0;
  [zoom>=2] { line-width: 0.5; }
  [zoom>=6] { line-width: 1; }
  [zoom>=8] { line-width: 1; }
  [zoom>=10] { line-width: 1; }
  [disputed=1] { line-dasharray: 4,4; }
  [maritime=1] { line-width: 0; }
}

#boundary[admin_level>2][admin_level<=4] {
  line-join: round;
  line-color: @adminLineColor;
  line-width: 0;
  [zoom>=15] { line-width: 1; }
}

#landuse[class='hospital'],
#landuse[class='industrial'],
#landuse[class='school'] {
  polygon-fill: mix(@land,@fill1,95);
}
#landcover {
  //[class='ice'] { polygon-fill: @ice; }
  ::overlay {
    // Landuse classes look better as a transparent overlay.
    opacity: 0.8;
    [class='ice'] { polygon-fill: @ice; polygon-gamma: 0.5; }
  }
}
#landcover {
  [class='grass'] { polygon-fill: @grass; }
  ::overlay {
    // Landuse classes look better as a transparent overlay.
    opacity: 0.5;
    [class='wood'] { polygon-fill: @wood; polygon-gamma: 0.5; }
  }
}

#building {
  polygon-fill: @buildingColor_faded;
  [zoom>=16]{ polygon-fill: @buildingColor;}
}

#aeroway {
  ['mapnik::geometry_type'=3][class!='apron'] {
    polygon-fill: mix(@fill2,@land,25);
    [zoom>=16]{ polygon-fill: mix(@fill2,@land,50);}
  }
  ['mapnik::geometry_type'=2] {
    line-color: mix(@fill2,@land,25);
    line-width: 1;
    [zoom>=13][class='runway'] { line-width: 4; }
    [zoom>=16] {
      [class='runway'] { line-width: 6; }
      line-width: 3;
      line-color: mix(@fill2,@land,50);
    }
  }
}

// Water Features //
#water {
  ::shadow {
    polygon-fill: mix(@land,@water,75);
  }
  ::fill {
    polygon-fill: @water;
  }
}


#waterway {
  [class='river'],
  [class='canal'] {
    line-color: @water;
    line-width: 0.5;
    [zoom>=12] { line-width: 1; }
    [zoom>=14] { line-width: 2; }
    [zoom>=16] { line-width: 3; }
  }
  [class='stream'] {
    line-color: @water;
    line-width: 0.5;
    [zoom>=14] { line-width: 1; }
    [zoom>=16] { line-width: 2; }
    [zoom>=18] { line-width: 3; }
  }
}


#contour {
  line-color: #ff0000;
  line-cap: round;
  line-width: 0.5;
  [class='river'] {
    [zoom>=12] { line-width: 1; }
    [zoom>=14] { line-width: 2; }
    [zoom>=16] { line-width: 3; }
  }
}

#bathymetry {
  line-color: #000080;
  line-cap: round;
  // polygon-fill: #000080;
  line-width: 0.5;
  // [depth=25]   { polygon-fill: #DEEDCF; opacity: 0.5; }
  // [depth=50]   { polygon-fill: #C7E4B8; opacity: 0.5; }
  // [depth=100]  { polygon-fill: #ADDAA1; opacity: 0.5; }
  // [depth=250]  { polygon-fill: #8FD08A; opacity: 0.5; }
  // [depth=500]  { polygon-fill: #74C67A; opacity: 0.5; }
  // [depth=1000] { polygon-fill: #5EBC72; opacity: 0.5; }
  // [depth=1250] { polygon-fill: #48B16D; opacity: 0.5; }
  // [depth=1500] { polygon-fill: #32A66B; opacity: 0.5; }
  // [depth=1750] { polygon-fill: #1D9A6C; opacity: 0.5; }
  // [depth=2000] { polygon-fill: #1A9073; opacity: 0.5; }
  // [depth=2500] { polygon-fill: #178678; opacity: 0.5; }
  // [depth=3000] { polygon-fill: #147C7C; opacity: 0.5; }
  // [depth=3500] { polygon-fill: #116672; opacity: 0.5; }
  // [depth=4000] { polygon-fill: #0F5267; opacity: 0.5; }
  // [depth=4500] { polygon-fill: #0C3F5C; opacity: 0.5; }
  // [depth=5000] { polygon-fill: #0A2F51; opacity: 0.5; }
}
