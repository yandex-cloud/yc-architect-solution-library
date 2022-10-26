FROM alpine:3.15

WORKDIR /app/

ENV PYTHONUNBUFFERED 1
ENV UWSGI_HTTP :8000
ENV UWSGI_UID app
ENV UWSGI_GID app
ENV UWSGI_WSGI_FILE main.py

RUN set -x \
    && addgroup -S app \
    && adduser -S -h /app -G app app \
    && apk add --no-cache python3 py3-pip \
    && apk add --no-cache --virtual .build-deps build-base gcc musl-dev git \
       python3-dev linux-headers make \
    && pip3 install --no-cache-dir uwsgi \
    && rm -rf /root/.cache \
    && apk del .build-deps \
    && :

USER app
COPY ./src/ /app/

EXPOSE 8000

CMD ["/usr/bin/uwsgi"]
