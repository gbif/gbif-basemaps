FROM openmaptiles/postgis:2.9
ENV IMPORT_DATA_DIR=/import

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    unzip \
    wget \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY . /usr/src/app
CMD ["./import-polar-water.sh"]
