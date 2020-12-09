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
@sans: 'Open Sans Regular', @fallback, @fallback_cjk;
@sans_md: 'Open Sans Semibold', @fallback, @fallback_cjk;
@sans_bd: 'Open Sans Bold', 'KlokanTech Noto Sans Bold', 'KlokanTech Noto Sans CJK Bold', @fallback;
@sans_it: 'Open Sans Italic', @fallback, @fallback_cjk;
@sans_lt_italic: 'Open Sans Light Italic', @fallback, @fallback_cjk;
@sans_lt: 'Open Sans Light', @fallback, @fallback_cjk;

@place_halo:        #fff;
@country_text:      @land * 0.2;
@country_halo:      @place_halo;


// ---------------------------------------------------------------------
// Countries

// The country labels in MapBox Streets vector tiles are placed by hand,
// optimizing the arrangement to fit as many as possible in densely-
// labeled areas.
#place[class='country'][zoom>=2][zoom<=10] {
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
  [zoom=2] { text-face-name: @sans; }
  text-placement: point;
  text-size: 9;
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


// ---------------------------------------------------------------------
// Cities, towns, villages, etc

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
    shield-fill: #333;
    shield-halo-fill: fadeout(#fff, 50%);
    shield-halo-radius: 1;
    shield-halo-rasterizer: fast;
}

#place[zoom>=8] {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  [name_en='Abkhazia'] { text-name: "''" }
  [name_en='Falkland Islands'] { text-name: @name_falklands_malvinas }
  [name_en='Nagorno-Karabakh Republic'] { text-name: "''" }
  [name_en='South Ossetia'] { text-name: "''" }
  [name_en='Transnistria'] { text-name: "''" }
  [name_en='Turkish Republic Of Northern Cyprus'] { text-name: "''" }
  text-face-name: @sans;
  text-wrap-width: 120;
  text-wrap-before: true;
  text-fill: #333;
  text-halo-fill: fadeout(#fff, 50%);
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
    text-fill: #633;
    text-face-name:	@sans_bd;
    text-transform: uppercase;
    text-character-spacing: 0.5;
    [zoom>=14] { text-size: 11; }
    [zoom>=15] { text-size: 12; text-character-spacing: 1; }
    [zoom>=16] { text-size: 14; text-character-spacing: 2; }
  }
}


// ---------------------------------------------------------------------
// Points of interest

#poi[subclass='station'],
#poi[zoom=14][rank<=1],
#poi[zoom=15][rank<=2],
#poi[zoom=16][rank<=3],
#poi[zoom=17][rank<=4],
#poi[zoom>=18] {
  // Separate icon and label attachments are created to ensure that
  // all icon placement happens first, then labels are placed only
  // if there is still room.
  ::icon[class!=null] {
    // The [maki] field values match a subset of Maki icon names, so we
    // can use that in our url expression.
    // Not all POIs have a Maki icon assigned, so we limit this section
    // to those that do. See also <https://www.mapbox.com/maki/>
    marker-fill:#666;
    marker-file:url('cartocss/osm-bright/icon/[class]-12.svg');
    marker-width: 10;
    marker-height: 10;
  }
  ::label {
    text-name: @name;
    [@name=~'^$'] { text-name: @name_fallback }
    text-face-name: @sans_md;
    text-size: 12;
    text-fill: #666;
    text-halo-fill: fadeout(#fff, 50%);
    text-halo-radius: 1;
    text-halo-rasterizer: fast;
    text-wrap-width: 70;
    text-line-spacing:	-1;
    //text-transform: uppercase;
    //text-character-spacing:	0.25;
    // POI labels with an icon need to be offset:
    [class!=null] { text-dy: 8; }
  }
}


// ---------------------------------------------------------------------
// Roads

#transportation_name::shield-pt[class='motorway'][zoom>=7][zoom<=10][ref_length<=6],
#transportation_name::shield-pt[class='motorway'][zoom>=9][zoom<=10][ref_length<=6],
#transportation_name::shield-ln[zoom>=11][ref_length<=6] {
  shield-name: "[ref].replace('·', '\n')";
  shield-size: 9;
  shield-line-spacing: -4;
  shield-file: url('cartocss/osm-bright/shield/default-[ref_length].svg');
  shield-face-name: @sans;
  shield-fill: #333;
  [zoom>=14] {
    shield-transform: scale(1.25,1.25);
    shield-size: 11;
  }
}
#transportation_name::shield-pt[class='motorway'][zoom>=7][zoom<=10][ref_length<=6],
#transportation_name::shield-pt[class='motorway'][zoom>=9][zoom<=10][ref_length<=6] {
  shield-placement: point;
  shield-avoid-edges: true;
}
#transportation_name::shield-ln[zoom>=11][ref_length<=6] {
  shield-placement: line;
  shield-spacing: 400;
  shield-min-distance: 100;
  shield-avoid-edges: true;
}

#transportation_name {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  text-placement: line;  // text follows line path
  text-face-name: @sans;
  text-fill: #765;
  text-halo-fill: fadeout(#fff, 50%);
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 12;
  text-avoid-edges: true;  // prevents clipped labels at tile edges
  [zoom>=15] { text-size: 13; }
}


// ---------------------------------------------------------------------
// Water

#water_name {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  text-face-name: @sans_it;
  text-fill: darken(@water, 15);
  text-size: 12;
  text-wrap-width: 100;
  text-wrap-before: true;
  text-halo-fill: fadeout(#fff, 75%);
  text-halo-radius: 1.5;
}


// ---------------------------------------------------------------------
// Mountain peaks

#mountain_peak[zoom>=12] {
  text-horizontal-alignment: right;
  text-name: "'▲'";
  [zoom>=14][ele>1500] { text-name: "'▲ '+" + @name; }
  [zoom>=16] { text-name: "'▲ '+" + @name; }
  [zoom>=16][ele>0] { text-name: "'▲ '+" + @name + "+' ('+[ele]+' m)'"; }
  text-face-name: @sans_md;
  text-fill: #262;
  text-size: 10;
  text-halo-fill: fadeout(#fff, 50%);
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  [ele>1500] { text-size: 12; }
}


// ---------------------------------------------------------------------
// House numbers

#housenumber[zoom>=18] {
  text-name: [housenumber];
  text-face-name: @sans_it;
  text-fill: #cba;
  text-size: 8;
  [zoom=19] { text-size: 10; }
  [zoom>=20] { text-size: 12; }
}

// ---------------------------------------------------------------------
// Graticules

#graticules[zoom>=4] {
  text-name: @name;
  [@name=~'^$'] { text-name: @name_fallback }
  text-placement: line;  // text follows line path
  text-face-name: @sans;
  text-fill: @country_text;
  text-halo-fill: @country_halo;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-size: 10;
  text-avoid-edges: true;  // prevents clipped labels at tile edges
}
