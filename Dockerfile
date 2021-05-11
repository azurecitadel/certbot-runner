FROM bitnami/minideb:stretch

RUN set -x \
    && addgroup --system --gid 101 certbot \
    && adduser --system --disabled-login --ingroup certbot --no-create-home --home /usr/src/certbot/ --gecos "certbot user" --shell /bin/false --uid 101 certbot \
    && mkdir -p /usr/src/certbot/logs /usr/src/certbot/conf /usr/src/certbot/work \
    && chown -R certbot:certbot /usr/src/certbot

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y apt-transport-https curl gnupg2 lsb-release \
    && apt-get -y install --no-install-recommends certbot jq \
    && apt-get autoremove -y --purge && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/*

# Don't run as root
USER certbot

COPY ./cli.ini /usr/src/certbot/
COPY ./*.sh /usr/src/certbot/

CMD ["/bin/sh", "/usr/src/certbot/run.sh"]
