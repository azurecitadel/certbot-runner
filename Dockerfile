FROM mcr.microsoft.com/azure-cli
RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq
RUN pip3 install pip --upgrade
RUN pip3 install certbot

RUN addgroup -S certbot && adduser -S certbot -G certbot
RUN mkdir -p /usr/src/certbot/logs /usr/src/certbot/conf /usr/src/certbot/work
RUN chown -R certbot:certbot /usr/src/certbot

# Don't run as root
USER certbot

# Create the default directory for certbot config
RUN mkdir -p /home/certbot/.config/letsencrypt/

COPY ./cli.ini /home/certbot/.config/letsencrypt/
COPY ./*.sh /usr/src/certbot/

CMD ["/bin/sh", "/usr/src/certbot/run.sh"]