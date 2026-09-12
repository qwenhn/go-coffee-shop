FROM mcr.microsoft.com/devcontainers/go:2-1.26-trixie

# ---------------------------------------------------------------------------
# Tool versions
# ---------------------------------------------------------------------------

ARG BUF_VERSION=1.72.0
ARG MIGRATE_VERSION=4.20.1

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

ARG TARGETOS
ARG TARGETARCH

RUN set -eux; \
    curl -fsSL \
    "https://github.com/golang-migrate/migrate/releases/download/v${MIGRATE_VERSION}/migrate.${TARGETOS}-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin migrate; \
    chmod +x /usr/local/bin/migrate; \
    migrate -version

# ---------------------------------------------------------------------------
# Verify Go installation
# ---------------------------------------------------------------------------

RUN go version
