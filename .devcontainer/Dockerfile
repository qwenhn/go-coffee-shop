FROM mcr.microsoft.com/devcontainers/go:2-1.26-trixie

# ---------------------------------------------------------------------------
# Tool versions
# ---------------------------------------------------------------------------

ARG BUF_VERSION=1.72.0
ARG MIGRATE_VERSION=4.20.1

ARG TERRAFORM_VERSION=1.16.3
ARG NOMAD_VERSION=2.0.6
ARG CONSUL_VERSION=2.0.4
ARG VAULT_VERSION=2.1.1

ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install Buf
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/buf; \
    chmod +x /usr/local/bin/buf; \
    buf --version

# ---------------------------------------------------------------------------
# Install golang-migrate
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://github.com/golang-migrate/migrate/releases/download/v${MIGRATE_VERSION}/migrate.${TARGETOS}-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin migrate; \
    chmod +x /usr/local/bin/migrate; \
    migrate -version

# ---------------------------------------------------------------------------
# Install Terraform
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
    -o /tmp/terraform.zip; \
    unzip -q -o /tmp/terraform.zip terraform; \
    install -m 0755 terraform /usr/local/bin/terraform; \
    rm -f terraform /tmp/terraform.zip; \
    terraform version

# ---------------------------------------------------------------------------
# Install Nomad
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
    -o /tmp/nomad.zip; \
    unzip -q /tmp/nomad.zip nomad; \
    install -m 0755 nomad /usr/local/bin/nomad; \
    rm -f nomad /tmp/nomad.zip; \
    nomad version

# ---------------------------------------------------------------------------
# Install Consul
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
    -o /tmp/consul.zip; \
    unzip -q /tmp/consul.zip consul; \
    install -m 0755 consul /usr/local/bin/consul; \
    rm -f consul /tmp/consul.zip; \
    consul version

# ---------------------------------------------------------------------------
# Install Vault
# ---------------------------------------------------------------------------

RUN set -eux; \
    curl -fsSL \
    "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
    -o /tmp/vault.zip; \
    unzip -q /tmp/vault.zip vault; \
    install -m 0755 vault /usr/local/bin/vault; \
    rm -f vault /tmp/vault.zip; \
    vault version

# ---------------------------------------------------------------------------
# Verify Go installation
# ---------------------------------------------------------------------------

RUN go version
