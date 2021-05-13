FROM bitnami/minideb:unstable

RUN set -x \
    && addgroup --system --gid 101 certbot \
    && adduser --system --disabled-login --ingroup certbot --no-create-home --home /usr/src/certbot/ --gecos "certbot user" --shell /bin/false --uid 101 certbot \
    && mkdir -p /usr/src/certbot/logs /usr/src/certbot/conf /usr/src/certbot/work \
    && chown -R certbot:certbot /usr/src/certbot

RUN install_packages certbot jq curl

# Don't run as root
USER certbot

COPY ./cli.ini /usr/src/certbot/
COPY ./*.sh /usr/src/certbot/

CMD ["/bin/sh", "/usr/src/certbot/run.sh"]
