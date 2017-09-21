FROM python:3.6
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# VOLUME /mapping

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /usr/src/app/

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      emacs-nox

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      jq

# CMD ["python", "-u","/usr/src/app/server.py"]
