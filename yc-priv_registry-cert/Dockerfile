FROM alpine:latest

RUN apk update && \
    apk add --no-cache ansible-core openssh-client curl jq bash

COPY worker.sh /worker.sh

RUN chmod +x /worker.sh

RUN echo -e "[defaults]\nhost_key_checking = False\nprivate_key_file = /ssh-key" > /ansible.cfg

ENTRYPOINT ["/bin/bash"]
