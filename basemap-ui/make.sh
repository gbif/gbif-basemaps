#!/bin/zsh -e

rm -Rf build/

for i in dev uat prod; do
  mkdir -p build/$i
  cp -pr src/* build/$i/
  cat src/GBIF-tile-schemas.js src/GBIF-layers.js >! build/$i/GBIF-both.js
done

perl -pi -e "s/tile.gbif.org/tile.gbif-dev.org/g" build/dev/**/*.js build/dev/**/*.html
perl -pi -e "s/tile.gbif.org/tile.gbif-uat.org/g" build/uat/**/*.js build/uat/**/*.html

#rsync -av --delete build/dev/ devtile-vh.gbif.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif-dev.org/' -H 'X-Ban-URL: ui'
rsync -av --delete build/uat/ uattile-vh.gbif.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif-uat.org/' -H 'X-Ban-URL: ui'
#rsync -av --delete build/prod/ tile-vh.gbif.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif.org/' -H 'X-Ban-URL: ui'
