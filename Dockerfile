FROM codercom/enterprise-base:ubuntu

# Install dependencies for asdf and common languages
# git and curl are needed for asdf itself.
# Other packages are build dependencies for Python, Node, Elixir, etc.
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  curl \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  wget \
  llvm \
  libncurses5-dev \
  m4 \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev \
  unzip \
  autoconf \
  wx-common \
  'libwxgtk3.2-dev | libwxgtk3.0-gtk3-dev' \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libpng-dev \
  libssh-dev \
  unixodbc-dev \
  libsctp-dev \
  libxslt1-dev \
  xsltproc \
  fop \
  libxml2-utils \
  zsh \
  && rm -rf /var/lib/apt/lists/*

# Install Starship prompt (official script)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# Install latest GitHub CLI (official apt repo)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Make zsh the default shell for the 'coder' user (non-interactive)
RUN usermod -s /usr/bin/zsh coder

# Provide a default zsh configuration for the 'coder' user
COPY --chown=coder:coder .zshrc /home/coder/.zshrc
COPY --chown=coder:coder starship.toml /home/coder/.config/starship.toml

# The rest of the Dockerfile should run as the 'coder' user
USER coder
ENV HOME=/home/coder
ENV ASDF_DIR=$HOME/.asdf
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"
WORKDIR $HOME

# Make a directory for the app $HOME/app
RUN mkdir -p $HOME/app

# Install asdf
RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.18.0
RUN echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc
RUN echo '. $HOME/.asdf/completions/asdf.bash' >> $HOME/.bashrc