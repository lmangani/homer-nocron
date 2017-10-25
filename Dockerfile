FROM sipcapture/homer-webapp
MAINTAINER L. Mangani <lorenzo.mangani@gmail.com>
ENV BUILD_DATE 2017-05-18

RUN apt-get update -qq && apt-get install mysql-client -y && rm -rf /var/lib/apt/lists/*

COPY rotation.ini /opt/rotation.ini

COPY run.sh /run.sh
RUN chmod a+rx /run.sh

ENTRYPOINT ["/run.sh"]
