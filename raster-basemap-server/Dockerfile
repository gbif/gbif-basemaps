FROM node:8 AS builder

RUN mkdir -p /usr/local/gbif/klokantech-gl-fonts/ && cd /usr/local/gbif/klokantech-gl-fonts/ && \
    curl -SsL --fail --output ttf.zip https://github.com/klokantech/klokantech-gl-fonts/releases/download/v1.0.0/ttf.zip && \
    unzip ttf.zip && rm -f ttf.zip

COPY src/main/node /usr/src/raster-basemap-server
WORKDIR /usr/src/raster-basemap-server
RUN npm install --registry https://repository.gbif.org/content/repositories/npmjs/

FROM node:8
LABEL maintainers="Matthew Blissett <mblissett@gbif.org>"

COPY --from=builder /usr/local/gbif/ /usr/local/gbif/

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y mapnik-utils fonts-noto-unhinted

COPY --from=builder /usr/src/raster-basemap-server /usr/local/gbif/raster-basemap-server
RUN mkdir /usr/local/gbif/conf
VOLUME /usr/local/gbif/conf
COPY conf/server.yml /usr/local/gbif/conf

EXPOSE 8080
WORKDIR /usr/local/gbif/raster-basemap-server
CMD ["/usr/local/bin/node", "server.js", "/usr/local/gbif/conf/server.yml", "8080", "raster-basemap-server"]
