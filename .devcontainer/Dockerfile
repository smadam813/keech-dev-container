FROM mcr.microsoft.com/dotnet/sdk:10.0

ARG TZ
ENV TZ="$TZ"

# Install basic development tools and iptables/ipset
# Note: .NET 10 SDK image is Ubuntu 24.04 (Noble) based
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  curl \
  wget \
  ca-certificates \
  locales \
  postgresql-client \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
  && locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create the vscode user (devcontainer convention)
# The .NET 10 SDK image (Ubuntu 24.04) may already have a user/group at UID/GID 1000,
# so we handle that gracefully: reuse the existing group or create a new one.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN if getent group $USER_GID >/dev/null 2>&1; then \
      EXISTING_GROUP=$(getent group $USER_GID | cut -d: -f1); \
      echo "GID $USER_GID already exists as '$EXISTING_GROUP', reusing it"; \
    else \
      groupadd --gid $USER_GID $USERNAME; \
    fi \
  && if id -u $USER_UID >/dev/null 2>&1; then \
      EXISTING_USER=$(id -nu $USER_UID); \
      echo "UID $USER_UID already exists as '$EXISTING_USER', renaming to $USERNAME"; \
      usermod -l $USERNAME -d /home/$USERNAME -m $EXISTING_USER; \
      groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1) 2>/dev/null || true; \
    else \
      useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh; \
    fi \
  && chsh -s /bin/zsh $USERNAME \
  && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
# Note: only pre-creating directories needed for volume mounts and tool installs.
# GSD and other CLI tools will create their own config dirs at install/runtime.
RUN mkdir -p /workspace /home/$USERNAME/.claude /home/$USERNAME/.local/bin /home/$USERNAME/.volta && \
  chown -R $USERNAME:$USERNAME /workspace /home/$USERNAME/.claude /home/$USERNAME/.local /home/$USERNAME/.volta

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Switch to non-root user for remaining installs
USER $USERNAME

# Set PATH for local binaries, Volta, and dotnet tools
ENV VOLTA_HOME="/home/$USERNAME/.volta"
ENV PATH="/home/$USERNAME/.local/bin:$VOLTA_HOME/bin:$PATH"

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p dotnet \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=~/.zsh_history" \
  -a 'export VOLTA_HOME="$HOME/.volta"' \
  -a 'export PATH="$VOLTA_HOME/bin:$PATH"' \
  -a 'alias update-agents="update-ai-agents.sh"' \
  -x

# Install Volta (JavaScript toolchain manager)
# Note: Volta supports Linux ARM64 (aarch64) as of recent releases.
# If building on Apple Silicon and you encounter issues, you can
# force x86_64 emulation with: --platform linux/amd64 in docker build.
RUN curl https://get.volta.sh | bash -s -- --skip-setup

# Install Node.js via Volta (provides npm for global tool installs)
RUN volta install node

# Install Claude Code using the native installer (npm method is deprecated)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install GSD (Get Shit Done) for Claude Code
RUN CLAUDE_CONFIG_DIR="/home/$USERNAME/.claude" npx get-shit-done-cc@latest --claude --global

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN sed -i 's/\r$//' /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/init-firewall.sh && \
  echo "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/$USERNAME-firewall && \
  chmod 0440 /etc/sudoers.d/$USERNAME-firewall
COPY update-ai-agents.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/update-ai-agents.sh && \
  chmod +x /usr/local/bin/update-ai-agents.sh
USER $USERNAME