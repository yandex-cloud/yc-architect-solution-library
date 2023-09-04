FROM alpine:3.17 as prepare

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONPATH /opt/lib/python3.10/site-packages
ENV PATH "${PATH}:/opt/bin"

WORKDIR /opt/app/

RUN set -x \
    && apk add --no-cache python3 \
    && :

FROM prepare as build

COPY . .

RUN set -x \
    && apk add --no-cache python3 \
    && apk add --no-cache --virtual .build-deps py3-pip build-base gcc musl-dev git \
       python3-dev linux-headers make \
    && pip3 install --prefix /opt pipenv gunicorn tzdata \
    && :

RUN set -x \
    && pipenv install --system --deploy --extra-pip-args "--prefix /opt" \
    && :

RUN set -x \
    && pip3 uninstall -y pipenv \
    && rm -rf /root/.cache /opt/app/Pipfile*  \
    && apk del .build-deps \
    && :

FROM prepare 

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV WORKERS 4
ENV GUNICORN_CMD_ARGS "-b 0.0.0.0:8000 -w $WORKERS"

WORKDIR /opt/app/

COPY --from=build /opt/ /opt/

USER 1001
EXPOSE 8000

CMD ["/opt/bin/gunicorn", "backend.wsgi:application"]
