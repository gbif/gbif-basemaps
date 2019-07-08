FROM python:3.6
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      emacs-nox

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends jq

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3-msgpack

VOLUME /output

COPY . /usr/src/app/

# CMD ["python", "-u","/usr/src/app/server.py"]
