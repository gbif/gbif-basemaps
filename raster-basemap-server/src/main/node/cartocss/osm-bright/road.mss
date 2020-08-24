// Basic color palette, from which variations will be derived.
@motorway:          #fc8;
@main:              #fea;
@street:            #fff;
@street_limited:    #f3f3f3;

// ---------------------------------------------------------------------

// Roads are split across 3 layers: #road, #bridge, and #tunnel. Each
// road segment will only exist in one of the three layers. The
// #bridge layer makes use of Mapnik's group-by rendering mode;
// attachments in this layer will be grouped by layer for appropriate
// rendering of multi-level overpasses.

// The main road style is for all 3 road layers and divided into 2 main
// attachments. The 'case' attachment is

#transportation {
  // casing/outlines & single lines
  ::case[zoom>=4]['mapnik::geometry_type'=2] {
    [class='motorway'] {
      line-join:round;
      line-color: mix(@motorway, #800, 75);
      #road { line-cap: round; }
      #tunnel { line-dasharray:3,2; }
      [zoom>=6]  { line-width:0.4; }
      [zoom>=7]  { line-width:0.6; }
      [zoom>=8] { line-width:1.5; }
      [zoom>=10]  { line-width:3; }
      [zoom>=13] { line-width:3.5;  }
      [zoom>=14] { line-width:5; }
      [zoom>=15] { line-width:7; }
      [zoom>=16] { line-width:9; }
    }
    [class='motorway'][ramp=1][zoom>=13] {
      line-join:round;
      line-color: mix(@motorway, #800, 75);
      #road { line-cap: round; }
      #tunnel { line-dasharray:3,2; }
      [zoom>=13] { line-width:1; }
      [zoom>=14] { line-width:3; }
      [zoom>=15] { line-width:5; }
      [zoom>=16] { line-width:6.5; }
    }
    [class='primary'],[class='secondary'],[class='tertiary'],[class='trunk'] {
      line-join:round;
      line-cap: round;
      line-color: mix(@main, #800, 75);
      [brunnel='tunnel'] { line-dasharray:3,2; }
      [zoom>=6] { line-width:0.2; }
      [zoom>=7] { line-width:0.4; }
      [zoom>=8] { line-width:1.5; }
      [zoom>=10] { line-width:2.4; }
      [zoom>=13] { line-width:2.5; }
      [zoom>=14] { line-width:4; }
      [zoom>=15] { line-width:5; }
      [zoom>=16] { line-width:8; }
    }
    [class='minor'][zoom>=12] {
      line-join:round;
      line-cap: round;
      [brunnel='tunnel'] { line-dasharray:3,2; }
      line-color: @land * 0.8;
      [zoom>=12] { line-width:0.5; }
      [zoom>=14] { line-width:1; }
      [zoom>=15] { line-width:4; }
      [zoom>=16] { line-width:6.5; }
    }
    [class='service'][zoom>=13] {
      line-join:round;
      line-cap: round;
      [brunnel='tunnel'] { line-dasharray:3,2; }
      line-color: @land * 0.9;
      [zoom>=13] { line-width:0.2; }
      [zoom>=14] { line-width:0.4; }
      [zoom>=15] { line-width:1; }
      [zoom>=16] { line-width:4; }
    }
    [class='path'][zoom>=14],
    [class='track'][zoom>=14] {
      line-color: #cba;
      line-dasharray: 2,1;
      [zoom>=14] { line-width: 1.0; }
      [zoom>=16] { line-width: 1.2; }
      [zoom>=17] { line-width: 1.5; }
    }
    [class='rail'] {
      line-join:round;
      line-cap: round;
      line-color: #666;
      [brunnel='tunnel'] { line-dasharray:3,2; }
      [zoom>=13] { line-width:1.25; }
      [zoom>=14] { line-width:2; h/line-width: 1; h/line-color: #ddd; h/line-dasharray: 8,8; }
      [zoom>=15] { line-width:2.5; h/line-width: 1.5; h/line-color: #ddd; h/line-dasharray: 8,8; }
      [zoom>=16] { line-width:4; h/line-width: 3; h/line-color: #ddd; h/line-dasharray: 8,8; }
    }
  }

  // fill/inlines
  ::fill[zoom>=4]['mapnik::geometry_type'=2] {
    [class='motorway'][zoom>=8] {
      line-join:round;
      line-cap:round;
      line-color:@motorway;
      [brunnel='tunnel'] { line-color:lighten(@motorway,4); }
      [zoom>=8] { line-width:0.5; }
      [zoom>=10] { line-width:1; }
      [zoom>=13] { line-width:2; }
      [zoom>=14] { line-width:3.5; }
      [zoom>=15] { line-width:5; }
      [zoom>=16] { line-width:7; }
    }
    [class='motorway'][ramp=1][zoom>=14] {
      line-join:round;
      line-cap: round;
      line-color:@motorway;
      [brunnel='tunnel'] {  line-color:lighten(@motorway,4); }
      [zoom>=14] { line-width:1.5; }
      [zoom>=15] { line-width:3; }
      [zoom>=16] { line-width:4.5; }
    }
    [class=~'primary|secondary|tertiary|trunk'][zoom>=8] {
      line-join:round;
      #road, #bridge { line-cap: round; }
      line-color:@main;
      [brunnel='tunnel'] { line-color:lighten(@main,4); }
      [zoom>=8] { line-width:0.5; }
      [zoom>=10] { line-width:1; }
      [zoom>=13] { line-width:1.5; }
      [zoom>=14] { line-width:2.5; }
      [zoom>=15] { line-width:3.5; }
      [zoom>=16] { line-width:6; }
    }
    [class='minor'][zoom>=15], {
      line-join:round;
      line-cap: round;
      [zoom>=15] { line-width:2.5; line-color:#fff; }
      [zoom>=16] { line-width:4; }
    }
    [class='service'][zoom>=16], {
      line-join:round;
      line-cap: round;
      [zoom>=16] { line-width:2; line-color:#fff; }
    }
    [class='major_rail'] {
      line-width: 0.4;
      line-color: #bbb;
      [zoom>=16] {
        line-width: 0.75;
      	// Hatching
      	h/line-width: 3;
      	h/line-color: #bbb;
      	h/line-dasharray: 1,31;
      }
    }
  }
}
