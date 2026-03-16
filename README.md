# keech-dev-container

A multi-container VS Code Dev Container for AI-assisted .NET development with a network-level firewall sandbox. Ships with Claude Code, GSD, PostgreSQL 17, and Grafana 11.5 in an isolated environment where only whitelisted services are reachable.

## Features

- **Network firewall sandbox** — default-DROP iptables policy with a curated whitelist of allowed services
- **AI tools pre-installed** — Claude Code and GSD (Get Shit Done)
- **UTF-8 locale** configured (`en_US.UTF-8`)
- **.NET 10 SDK** base image (Ubuntu 24.04)
- **Docker-in-Docker** support via the devcontainers feature
- **Zsh with Powerlevel10k** theme out of the box
- **Persistent volumes** for shell history and Claude config across rebuilds
- **Git Delta** for enhanced diffs
- **Node.js via Volta** toolchain manager
- **GitHub CLI** (`gh`) pre-installed
- **PostgreSQL 17** with `psql` client in the dev container
- **Grafana 11.5** for dashboards and monitoring

## Services

The devcontainer uses Docker Compose with three services on a shared bridge network:

| Service | Image | Purpose | Forwarded Port |
|---|---|---|---|
| **app** | Built from `Dockerfile` (.NET 10 SDK) | Main dev container with all tools | — |
| **postgres** | `postgres:17` | PostgreSQL database (`devdb`) | `5432` |
| **grafana** | `grafana/grafana:11.5` | Dashboards and monitoring | `3000` |

**Default credentials:**

| Service | Username | Password |
|---|---|---|
| PostgreSQL | `postgres` | `postgres` |
| Grafana | `admin` | `admin` |

The app container waits for PostgreSQL to be healthy before starting. PG connection variables (`PGHOST`, `PGUSER`, etc.) are pre-configured so `psql` works with no arguments.

## Prerequisites

- Docker (or a compatible container runtime)
- VS Code with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension (or any devcontainer-compatible tool)

## Getting Started

```bash
git clone <repo-url> && cd keech-dev-container
```

Open the folder in VS Code, then run **Dev Containers: Reopen in Container** from the command palette (`Ctrl+Shift+P`).

The container will build, install all tools, and run the firewall setup automatically. The `postStartCommand` blocks until the firewall is verified, so the terminal is ready to use as soon as it appears.

## Network Sandbox

The firewall (`init-firewall.sh`) runs at every container start and enforces a strict whitelist:

**Policy:** INPUT, FORWARD, and OUTPUT chains are all set to DROP by default.

**Whitelisted services:**

| Service | Domains |
|---|---|
| GitHub | Dynamic IPs fetched from `api.github.com/meta` (web, api, git ranges) |
| npm | `registry.npmjs.org` |
| Anthropic (Claude) | `api.anthropic.com`, `claude.ai` |
| NuGet | `api.nuget.org` |
| VS Code Marketplace | `marketplace.visualstudio.com`, `vscode.blob.core.windows.net`, `update.code.visualstudio.com` |
| Volta / Node.js | `volta.sh`, `get.volta.sh`, `nodejs.org` |
| Google Fonts | `fonts.googleapis.com`, `fonts.gstatic.com` |
| Telemetry | `sentry.io`, `statsig.anthropic.com`, `statsig.com` |

**Additionally:**
- DNS (UDP port 53) is always allowed
- SSH (TCP port 22) outbound is allowed
- Docker's internal DNS resolver (`127.0.0.11`) is preserved
- All local/container network interfaces (host network, docker-compose bridge, docker0) are auto-detected and allowed
- Established/related connections are tracked with conntrack

**Built-in verification** — the script confirms that `example.com` is blocked and `api.github.com` is reachable before completing.

## Included Tools

| Tool | Install method |
|---|---|
| Claude Code | Native installer (`claude.ai/install.sh`) |
| GSD | npx (`get-shit-done-cc@latest --claude --global`) |
| update-ai-agents.sh | Shell script (`update-agents` alias) |
| Git Delta | `.deb` package (v0.18.2) |
| GitHub CLI | apt (`gh`) |
| Volta | Official installer (`get.volta.sh`) |
| Node.js | Volta-managed |
| fzf | apt |
| psql | apt (`postgresql-client`) |

## VS Code Extensions

The following extensions are automatically installed in the container:

- **C# Dev Kit** (`ms-dotnettools.csdevkit`)
- **Claude Code** (`anthropic.claude-code`)
- **Docker** (`ms-azuretools.vscode-containers`)
- **Markdown All in One** (`yzhang.markdown-all-in-one`)

## Configuration

### Build Arguments

| Argument | Default | Description |
|---|---|---|
| `TZ` | `America/New_York` (from `$TZ` on host) | Container timezone |
| `GIT_DELTA_VERSION` | `0.18.2` | Git Delta release version |
| `ZSH_IN_DOCKER_VERSION` | `1.2.0` | zsh-in-docker installer version |

### Environment Variables

| Variable | Value |
|---|---|
| `CLAUDE_CONFIG_DIR` | `/home/vscode/.claude` |
| `DOTNET_CLI_TELEMETRY_OPTOUT` | `1` |
| `DOTNET_NOLOGO` | `1` |
| `LANG` | `en_US.UTF-8` |
| `LC_ALL` | `en_US.UTF-8` |
| `POWERLEVEL9K_DISABLE_GITSTATUS` | `true` |
| `PGHOST` | `postgres` |
| `PGPORT` | `5432` |
| `PGUSER` | `postgres` |
| `PGPASSWORD` | `postgres` |
| `PGDATABASE` | `devdb` |

### Volumes

| Volume | Container Path | Purpose |
|---|---|---|
| `claude-code-home` | `/home/vscode` | Persistent home directory (shell history, Claude config) |
| `postgres-data` | `/var/lib/postgresql/data` | PostgreSQL data |
| `grafana-data` | `/var/lib/grafana` | Grafana dashboards and config |

## Customization

### Adding domains to the firewall whitelist

Edit `.devcontainer/init-firewall.sh` and add entries to the `for domain in` loop:

```bash
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    ...
    "your-new-domain.example.com"; do
```

Rebuild or restart the container for changes to take effect.

### Changing the timezone

Set the `TZ` environment variable on your host before building, or edit the build arg in `docker-compose.yml`:

```yaml
build:
  args:
    TZ: "Europe/London"
```

### Adding VS Code extensions

Add extension IDs to the `customizations.vscode.extensions` array in `.devcontainer/devcontainer.json`.
