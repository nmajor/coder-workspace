FROM codercom/enterprise-base:ubuntu

# Ensure package installs run as root and non-interactively
USER root
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for asdf and common languages
# git and curl are needed for asdf itself.
# Other packages are build dependencies for Python, Node, Elixir, etc.
RUN apt-get update && apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  jq \
  pkg-config \
  zlib1g-dev \
  libssl-dev \
  libreadline-dev \
  libncurses5-dev \
  wget \
  unzip \
  zsh \
  && rm -rf /var/lib/apt/lists/*

# Install Starship prompt (official script)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# Install latest GitHub CLI (official apt repo)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt-get update
RUN apt-get install -y gh
RUN rm -rf /var/lib/apt/lists/*

# Make zsh the default shell for the 'coder' user (non-interactive)
RUN usermod -s /usr/bin/zsh coder

# System-wide asdf configuration (no $HOME dependency)
ENV ASDF_DIR=/usr/local/asdf
ENV ASDF_DATA_DIR=/var/lib/asdf
ENV PATH="$ASDF_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"
ENV KERL_BUILD_DOCS=no
ENV KERL_CONFIGURE_OPTIONS="--without-wx"

# Install asdf v0.16+ (Go) pinned binary release (simple & deterministic)
ENV ASDF_VERSION=v0.18.0
ENV ASDF_EXT=tar.gz
RUN ARCH=$(dpkg --print-architecture); \
  case "$ARCH" in \
    amd64) GOARCH=amd64 ;; \
    arm64) GOARCH=arm64 ;; \
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
  esac; \
  mkdir -p "$ASDF_DIR/bin" "$ASDF_DATA_DIR" /etc/profile.d && \
  curl -fsSL -o /tmp/asdf.tgz "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-${GOARCH}.${ASDF_EXT}" && \
  tar -xaf /tmp/asdf.tgz -C "$ASDF_DIR" && \
  if [ -x "$ASDF_DIR/asdf" ]; then install -m 0755 "$ASDF_DIR/asdf" "$ASDF_DIR/bin/asdf"; \
  elif [ -x "$ASDF_DIR/bin/asdf" ]; then true; \
  else BIN_PATH=$(find "$ASDF_DIR" -maxdepth 2 -type f -name asdf | head -n1); test -n "$BIN_PATH" && install -m 0755 "$BIN_PATH" "$ASDF_DIR/bin/asdf"; fi && \
  rm -f /tmp/asdf.tgz

# Make asdf available for all shells via profile.d
RUN printf '%s\n' \
  'export ASDF_DIR=/usr/local/asdf' \
  'export ASDF_DATA_DIR=/var/lib/asdf' \
  'export PATH="$ASDF_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"' \
  '. "$ASDF_DIR/asdf.sh" 2>/dev/null || true' \
  > /etc/profile.d/asdf.sh

# Install languages (system-wide into ASDF_DATA_DIR)
ENV NODEJS_VERSION=24.8.0
ENV PYTHON_VERSION=3.13.0
ENV ELIXIR_VERSION=1.18.4
ENV ERLANG_VERSION=28.1

RUN . /etc/profile.d/asdf.sh && \
    asdf plugin add nodejs || true && \
    asdf plugin add python || true && \
    asdf plugin add elixir || true && \
    asdf plugin add erlang || true && \
    asdf install nodejs "$NODEJS_VERSION" && \
    asdf install python "$PYTHON_VERSION" && \
    asdf install elixir "$ELIXIR_VERSION" && \
    asdf install erlang "$ERLANG_VERSION" && \
    asdf reshim

# System-wide default versions via environment (no $HOME, no shell init needed)
ENV ASDF_NODEJS_VERSION=$NODEJS_VERSION
ENV ASDF_PYTHON_VERSION=$PYTHON_VERSION
ENV ASDF_ELIXIR_VERSION=$ELIXIR_VERSION
ENV ASDF_ERLANG_VERSION=$ERLANG_VERSION

USER coder

