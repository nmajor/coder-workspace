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

# Provide a default zsh configuration for the 'coder' user
COPY --chown=coder:coder .zshrc /home/coder/.zshrc
COPY --chown=coder:coder starship.toml /home/coder/.config/starship.toml

# The rest of the Dockerfile should run as the 'coder' user
USER coder
ENV HOME=/home/coder
ENV APP_DIR=$HOME/app
ENV ASDF_DIR=$HOME/.asdf
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"
ENV KERL_BUILD_DOCS=no
ENV KERL_CONFIGURE_OPTIONS="--without-wx"
WORKDIR $HOME

# Make a directory for the app $HOME/app
RUN mkdir -p $APP_DIR

# Install asdf v0.16+ (Go) pinned binary release (simple & deterministic)
ENV ASDF_VERSION=v0.18.0
ENV ASDF_EXT=tar.gz
RUN ARCH=$(dpkg --print-architecture); \
  case "$ARCH" in \
    amd64) GOARCH=amd64 ;; \
    arm64) GOARCH=arm64 ;; \
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
  esac; \
  mkdir -p "$ASDF_DIR" && \
  curl -fsSL -o /tmp/asdf.tgz "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-${GOARCH}.${ASDF_EXT}" && \
  tar -xaf /tmp/asdf.tgz -C "$ASDF_DIR" && \
  mkdir -p "$ASDF_DIR/bin" && \
  if [ -x "$ASDF_DIR/asdf" ]; then install -m 0755 "$ASDF_DIR/asdf" "$ASDF_DIR/bin/asdf"; \
  elif [ -x "$ASDF_DIR/bin/asdf" ]; then true; \
  else BIN_PATH=$(find "$ASDF_DIR" -maxdepth 2 -type f -name asdf | head -n1); test -n "$BIN_PATH" && install -m 0755 "$BIN_PATH" "$ASDF_DIR/bin/asdf"; fi && \
  rm -f /tmp/asdf.tgz

# Bash completion for asdf (v0.16+)
RUN echo 'if command -v asdf >/dev/null 2>&1; then' >> $HOME/.bashrc
RUN echo '  source <(asdf completion bash)' >> $HOME/.bashrc
RUN echo 'fi' >> $HOME/.bashrc

# Install languages
ENV NODEJS_VERSION=20.11
ENV PYTHON_VERSION=3.12
ENV ELIXIR_VERSION=1.18
ENV ERLANG_VERSION=28.1

RUN asdf plugin add nodejs
RUN asdf plugin add python
RUN asdf plugin add elixir
RUN asdf plugin add erlang

ENV TOOL_VERSIONS_FILE=$HOME/.tool-versions

RUN echo "nodejs 20.11.0" > "$TOOL_VERSIONS_FILE"
RUN echo "python 3.12.2" >> "$TOOL_VERSIONS_FILE"
RUN echo "elixir 1.18" >> "$TOOL_VERSIONS_FILE"
RUN echo "erlang 28.1" >> "$TOOL_VERSIONS_FILE"

RUN asdf install

# ----------------------
# Python stuff

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ----------------------
# Javascript stuff

RUN npm install -g bun
RUN npm install -g @anthropic-ai/claude-code

# ----------------------

COPY --chown=coder:coder .mcp.json $APP_DIR/.mcp.json
