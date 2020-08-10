#!/usr/bin/env bash

# ensure_eksctl installs the eksctl binary if it isn't present on the system.
# and uses `sudo mv` to place the downloaded binary into your PATH.
ensure_eksctl() {
    if ! is_installed eksctl ; then
			curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
			sudo mv /tmp/eksctl /usr/local/bin
    fi
}
