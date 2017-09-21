#!/bin/zsh -e

srs=4326
z=20
x=1186553
y=303311

srs=3857
z=20
x=835116
y=492871

srs=3575
z=20
x=545861
y=656465

srs=3031
z=20
x=419924
y=460056

start="/$srs/omt"
end='@2x.png?style=osm-bright'

(while [[ $z -ge 0 ]]; do
  echo "<li><p>Zoom $z</p><div class='fullsize'><img src='$start/$z/$x/$y$end'/></div></li>"
  z=$(( $z - 1 ))
  x=$(( $x / 2 ))
  y=$(( $y / 2 ))
done) | tac
