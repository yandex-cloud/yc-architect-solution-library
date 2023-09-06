ARG NODE_IMAGE=node:12.18.0

FROM ${NODE_IMAGE} as frontend_builder

WORKDIR /code

ADD package.json .
ADD yarn.lock .

RUN yarn install

ADD . .

RUN ls -lah
RUN yarn build

FROM nginx:alpine

COPY --from=frontend_builder /code/build/ /usr/share/nginx/html
ADD nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80 80
