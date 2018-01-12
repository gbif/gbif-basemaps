FROM openmaptiles/postgis:2.9
ENV IMPORT_DATA_DIR=/import

WORKDIR /usr/src/app
COPY . /usr/src/app
CMD ["./import-polar-water.sh"]
