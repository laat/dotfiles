FROM mcr.microsoft.com/devcontainers/javascript-node:22

ARG NODE_VERSION=24
ARG PNPM_VERSION=10.33.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    direnv \
    neovim \
    ripgrep \
    fd-find \
    fzf \
    jq \
    curl \
    unzip \
    stow \
    python3 \
    apt-transport-https \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    > /usr/share/keyrings/cloud.google.asc \
    && apt-get update && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

USER vscode
RUN bash -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION}"
USER root

RUN npm install -g pnpm@${PNPM_VERSION} @anthropic-ai/claude-code

COPY setup.sh /usr/local/bin/devpod-setup.sh
RUN chmod +x /usr/local/bin/devpod-setup.sh
