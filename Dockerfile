FROM debian:bullseye-20220622-slim
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	apt-utils \
	bash \
	ca-certificates \
	curl \
	git \
	git-lfs \
	gnupg \
	groff \
	jq \
	less \
	libcap2 \
	openssh-client \
	openssl \
	python3 \
	python3-pip \
	python3-pycryptodome \
	python3-requests \
	python3-yaml \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

ENV TENV_LATEST_VERSION=v4.2.4
RUN ARCH=$(dpkg --print-architecture) && \
    curl -O -L "https://github.com/tofuutils/tenv/releases/download/${TENV_LATEST_VERSION}/tenv_${TENV_LATEST_VERSION}_${ARCH}.deb" && \
    dpkg -i "tenv_${TENV_LATEST_VERSION}_${ARCH}.deb" && \
    tenv tofu install 1.6.3 && \
    sleep 5 && \
    tenv tofu install 1.9.1 && \
    sleep 5 && \
    tenv terraform install 1.5.7

ENV INFRACOST_VERSION v0.10.29
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/g' | sed 's/aarch64/arm64/g') && \
    curl -fsSL -o /tmp/infracost-linux-${ARCH}.tar.gz "https://github.com/infracost/infracost/releases/download/${INFRACOST_VERSION}/infracost-linux-${ARCH}.tar.gz" && \
    tar -C /tmp -xzf /tmp/infracost-linux-${ARCH}.tar.gz && \
    mv /tmp/infracost-linux-${ARCH} /usr/local/bin/infracost && \
    rm -f /tmp/infracost-linux-${ARCH}.tar.gz

ENV CONFTEST_VERSION 0.58.0
RUN ARCH=$(uname -m | sed 's/aarch64/arm64/g') && \
    mkdir /tmp/conftest && \
    curl -fsSL -o /tmp/conftest/conftest.tar.gz "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_${ARCH}.tar.gz" && \
    tar -C /tmp/conftest -xzf /tmp/conftest/conftest.tar.gz && \
    mv /tmp/conftest/conftest /usr/local/bin/conftest && \
    rm -rf /tmp/conftest

ENV AWSCLI_VERSION 2.13.26
RUN ARCH=$(uname -m) && \
    mkdir /tmp/awscli && \
    curl -fsSL -o /tmp/awscli/awscli.zip "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" && \
    unzip -q /tmp/awscli/awscli.zip -d /tmp/awscli/ && \
    /tmp/awscli/aws/install > /dev/null && \
    rm -rf /tmp/awscli

ENV CHECKOV_VERSION=2.5.10
RUN pip3 install checkov==${CHECKOV_VERSION}

ENV RESOURCELY_VERSION=1.0.45

COPY ./bin/ /usr/local/bin
COPY proxy/bin /usr/local/proxy/bin
COPY conftest-wrapper /usr/local/bin/conftest-wrapper
COPY checkov-wrapper /usr/local/bin/checkov-wrapper
COPY cdktf-setup.sh /cdktf-setup.sh
COPY gcloud-cli-setup.sh /gcloud-cli-setup.sh
COPY azure-cli-setup.sh /azure-cli-setup.sh
COPY kubectl-cli-setup.sh /kubectl-cli-setup.sh

# 2025-02-03 HCP removed its public key file from the internet for a few hours,
# which broke runs.  So we include the key file to protect against HCP outages.
RUN mkdir /usr/local/share/keys
COPY keys/hashicorp-pgp-key.txt /usr/local/share/keys
ENV TFENV_HASHICORP_PGP_KEY=/usr/local/share/keys/hashicorp-pgp-key.txt

RUN curl --output /usr/local/share/keys/opentofu.asc https://get.opentofu.org/opentofu.asc
ENV TOFUENV_OPENTOFU_PGP_KEY /usr/local/share/keys/opentofu.asc

COPY entrypoint.sh /entrypoint.sh
COPY entrypoint_gitlab.sh /entrypoint_gitlab.sh
COPY terrat_runner /terrat_runner

COPY proxy/bin /usr/local/proxy/bin

ENTRYPOINT ["/entrypoint.sh"]
