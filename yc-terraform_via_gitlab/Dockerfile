FROM alpine:latest

RUN apk add --no-cache \
  curl \
  gcompat \
  git \
  idn2-utils \
  jq \
  openssh

COPY ./terraform /usr/local/bin/terraform

RUN terraform --version

COPY ./gitlab-terraform.sh /usr/bin/gitlab-terraform

RUN chmod +x /usr/bin/gitlab-terraform

COPY ./.terraformrc /root/.terraformrc

ENTRYPOINT []
