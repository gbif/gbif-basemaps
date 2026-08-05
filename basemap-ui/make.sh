#!/bin/zsh -e

rm -Rf build/

for i in dev test prod; do
  mkdir -p build/$i
  cp -pr src/* build/$i/
  cat src/GBIF-tile-schemas.js src/GBIF-layers.js >! build/$i/GBIF-both.js
done

perl -pi -e "s/tile.gbif.org/tile.gbif-dev.org/g" build/dev/**/*.js build/dev/**/*.html
perl -pi -e "s/tile.gbif.org/tile.gbif-test.org/g" build/test/**/*.js build/test/**/*.html

rsync -avO --checksum --delete build/dev/ devtile-vh.gbif-dev.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif-dev.org/' -H 'X-Ban-URL: ui'
rsync -avO --checksum --delete build/test/ testtile-vh.gbif-test.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif-test.org/' -H 'X-Ban-URL: ui'
#rsync -avO --checksum --delete build/prod/ prodtile-vh.gbif.org:/var/www/html/ui/ && curl -i -X BAN 'http://tile.gbif.org/' -H 'X-Ban-URL: ui'
