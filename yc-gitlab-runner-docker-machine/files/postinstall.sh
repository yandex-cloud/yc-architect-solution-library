#!/bin/bash

set -eo pipefail

DOCKER_MACHINE_VER="v0.16.2-gitlab.19"
DM_DRIVER_YANDEX_VER="v0.1.36"
username=gitlab-runner
service_name=$username

jq --version > /dev/null || {
    echo "so install jq..." >&2
    export DEBIAN_FRONTEND=noninteractive
    apt-get -yqq update
    apt-get -yqq install jq
}

if [ ! -x /usr/local/bin/docker-machine ]; then
    OS_ARCH="$(uname -s)-$(uname -m)"
    url="https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/releases/$DOCKER_MACHINE_VER/downloads/docker-machine-$OS_ARCH"
    curl -sfL "$url" -o /usr/local/bin/docker-machine
    chmod +x /usr/local/bin/docker-machine
fi

if [ ! -x /usr/local/bin/docker-machine-driver-yandex ]; then
    PKG_ARCH="$(uname -s | tr A-Z a-z )_$(uname -m | sed -e s/aarch64/arm64/ -e s/x86_64/amd64/ -e s/x86/386/)"
    url="https://github.com/yandex-cloud/docker-machine-driver-yandex/releases/download/$DM_DRIVER_YANDEX_VER"
    url="$url/docker-machine-driver-yandex_${DM_DRIVER_YANDEX_VER:1}_$PKG_ARCH.tar.gz"
    curl -sfL "$url" | tar xz -C /usr/local/bin docker-machine-driver-yandex
    chown root:root /usr/local/bin/docker-machine-driver-yandex
    chmod +x /usr/local/bin/docker-machine-driver-yandex
fi

if [ ! -x /usr/local/bin/gitlab-runner ]; then
    PKG_ARCH="$(uname -s | tr A-Z a-z )-$(uname -m | sed -e s/aarch64/arm64/ -e s/x86_64/amd64/ -e s/x86/386/)"
    url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-$PKG_ARCH"
    curl -sfL "$url" -o /usr/local/bin/gitlab-runner
    chmod +x /usr/local/bin/gitlab-runner
    useradd $username -m -s /bin/bash
fi

if [ ! -f /etc/gitlab-runner/config.toml ]; then
    mkdir -p /etc/gitlab-runner /etc/systemd/system/$service_name.service.d
    gitlab-runner install -u $username -c /etc/gitlab-runner/config.toml -d $(getent passwd $username | cut -d: -f6) -n $service_name
    cat "$(dirname $0)/secret_id" > /etc/gitlab-runner/secret_id
    cat "$(dirname $0)/gitlab-runner-config.toml" > /etc/gitlab-runner/gitlab-runner-config.toml

    cat <<-'EOF' > /usr/local/sbin/setup-gitlab-runner.sh
	#!/bin/bash
	
	set -e
	
	case "$1" in
	    [Ss][Tt][Aa][Rr][Tt])
	        secret_id=$(cat /etc/gitlab-runner/secret_id)
	        authz=$(curl -sf -H Metadata-Flavor:Google 169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token \
	            | jq -r '"\(.token_type) \(.access_token)"')
	        read CI_SERVER_URL REGISTRATION_TOKEN RUNNER_TAG_LIST <<<$(curl -sf -H "Authorization: $authz" \
	            "https://payload.lockbox.api.cloud.yandex.net/lockbox/v1/secrets/$secret_id/payload" \
	            | jq -r '.entries | map( { (.key|tostring): .textValue } ) | add | "\(.gitlab_url) \(.gitlab_token) \(.gitlab_runner_tags)"')
	
	        export CI_SERVER_URL REGISTRATION_TOKEN
	        test "$RUNNER_TAG_LIST" == "-" || export RUNNER_TAG_LIST

	        gitlab-runner register --template-config /etc/gitlab-runner/gitlab-runner-config.toml \
	            --config /etc/gitlab-runner/config.toml \
	            --non-interactive 

	        sed -i -r -e '/^ *concurrent *= */ s/[0-9]+$/1000/' /etc/gitlab-runner/config.toml
	        ;;
	    [Ss][Tt][Oo][Pp])
	        gitlab-runner unregister --config /etc/gitlab-runner/config.toml --all-runners
	        export HOME=/root
	        machines=$(cd $HOME/.docker/machine/machines/ && echo *)
	        if [ -n "$machines" ]; then 
	            docker-machine rm -f $machines || true
	            sleep 3
	        fi
	        ;;
	    *)
	        echo "Usage: $0 (stop|start)" >&2
	        exit 1
	        ;;
	esac
	EOF

    cat <<-EOF > /etc/systemd/system/$service_name.service.d/setup-gitlab-runner.conf
	[Service]
	TimeoutStopSec=20
	ExecStartPre=/usr/local/sbin/setup-gitlab-runner.sh start
	ExecStopPost=/usr/local/sbin/setup-gitlab-runner.sh stop
	EOF

    chmod 0750 /usr/local/sbin/setup-gitlab-runner.sh
    systemctl enable gitlab-runner --now
fi
