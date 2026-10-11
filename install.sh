#!/bin/sh
# Keep the complete program in a function so curl | sh reads it before starting.
main() (
    set -eu
    KIT_USER=${KIT_USER:-viftode4}
    # hq owns any server-specific behavior.
    KIT_SERVER=${KIT_SERVER:-}
    export KIT_USER KIT_SERVER
    PATH="$HOME/.local/bin:$PATH"
    export PATH

    die() { printf 'kit: %s\n' "$*" >&2; exit 1; }
    have() { command -v "$1" >/dev/null 2>&1; }
    case "$KIT_USER" in
        *[!a-zA-Z0-9-]*|-*) die 'KIT_USER must be a GitHub username.' ;;
    esac
    [ "${#KIT_USER}" -le 39 ] || die 'KIT_USER must be a GitHub username.'
    # Check before installing anything. SSH sessions need a terminal (ssh -t).
    if ! ( : </dev/tty ) 2>/dev/null; then
        die 'Run from a terminal (use ssh -t for SSH) so login and vault prompts can read /dev/tty.'
    fi
    as_root() {
        if [ "$(id -u)" -eq 0 ]; then
            "$@"
        else
            have sudo || die 'sudo is required to install system packages.'
            sudo "$@" </dev/tty
        fi
    }
    apt_ready=0
    apt_install() {
        if [ "$apt_ready" -eq 0 ]; then
            as_root apt-get update
            apt_ready=1
        fi
        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
    }
    node_ok() {
        have node && node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 20 ? 0 : 1)' >/dev/null 2>&1
    }
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' 0
    trap 'exit 1' HUP INT TERM

    case "$(uname -s)" in
        Darwin)
            [ "$(id -u)" -ne 0 ] || die 'Run as your regular macOS user; Homebrew cannot install as root.'
            if ! have brew; then
                for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                    if [ -x "$brew_bin" ]; then
                        eval "$("$brew_bin" shellenv)"
                        break
                    fi
                done
            fi
            if ! have brew; then
                # Authenticate sudo first; the Homebrew installer itself stays non-interactive.
                sudo -v </dev/tty
                curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$temp_dir/brew.sh"
                NONINTERACTIVE=1 /bin/bash "$temp_dir/brew.sh"
                for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                    if [ -x "$brew_bin" ]; then
                        eval "$("$brew_bin" shellenv)"
                        break
                    fi
                done
            fi
            have brew || die 'Homebrew is not on PATH after installation.'
            # /usr/bin/git may only be a Command Line Tools stub on a fresh Mac.
            if ! have git || ! git --version >/dev/null 2>&1; then brew install git; fi
            have curl || brew install curl
            have gh || brew install gh
            if ! node_ok || ! have npm; then
                brew install node@24
                # The versioned LTS formula is keg-only; expose it to future shells too.
                brew link --overwrite --force node@24
                PATH="$(brew --prefix node@24)/bin:$PATH"
                export PATH
            fi
            ;;
        Linux)
            if have apt-get; then
                if ! have curl || [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
                    apt_install ca-certificates curl
                fi
                have git || apt_install git
                if ! have gh; then
                    if [ "$apt_ready" -eq 0 ]; then
                        as_root apt-get update
                        apt_ready=1
                    fi
                    gh_candidate=$(apt-cache policy gh | sed -n 's/^[[:space:]]*Candidate: //p')
                    if [ -z "$gh_candidate" ] || [ "$gh_candidate" = '(none)' ]; then
                        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$temp_dir/githubcli.gpg"
                        as_root install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
                        as_root install -m 644 "$temp_dir/githubcli.gpg" /etc/apt/keyrings/githubcli-archive-keyring.gpg
                        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$(dpkg --print-architecture)" >"$temp_dir/github-cli.list"
                        as_root install -m 644 "$temp_dir/github-cli.list" /etc/apt/sources.list.d/github-cli.list
                        as_root apt-get update
                    fi
                    apt_install gh
                fi
                if ! node_ok; then
                    curl -fsSL https://deb.nodesource.com/setup_22.x -o "$temp_dir/node.sh"
                    as_root bash "$temp_dir/node.sh"
                    apt_install nodejs
                fi
                # NodeSource bundles npm; distro Node packages may split it out.
                have npm || apt_install npm
            elif have dnf; then
                if ! have curl; then as_root dnf install -y curl ca-certificates; fi
                have git || as_root dnf install -y git
                if ! have gh; then
                    if ! as_root dnf install -y gh; then
                        curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo -o "$temp_dir/gh-cli.repo"
                        as_root install -m 644 "$temp_dir/gh-cli.repo" /etc/yum.repos.d/gh-cli.repo
                        as_root dnf install -y gh
                    fi
                fi
                if ! node_ok; then
                    as_root dnf install -y nodejs npm
                    if ! node_ok; then as_root dnf upgrade -y nodejs npm; fi
                fi
                have npm || as_root dnf install -y npm
            else
                die 'Supported Linux package managers: apt-get (Debian/Ubuntu) and dnf (Fedora, best effort).'
            fi
            ;;
        *) die 'Supported systems: macOS and Linux. Use install.ps1 on Windows.' ;;
    esac

    node_ok || die 'Node.js 20+ is required; upgrade Node.js or remove an older version shadowing it on PATH.'
    if ! have chezmoi; then
        mkdir -p "$HOME/.local/bin"
        chezmoi_installer=$(curl -fsLS https://get.chezmoi.io)
        sh -c "$chezmoi_installer" -- -b "$HOME/.local/bin"
    fi
    if ! have uv; then
        curl -fsSL https://astral.sh/uv/install.sh -o "$temp_dir/uv.sh"
        UV_INSTALL_DIR="$HOME/.local/bin" sh "$temp_dir/uv.sh"
    fi
    for tool in git gh chezmoi uv node npm; do
        have "$tool" || die "$tool is unavailable after installation. Check PATH and rerun."
    done

    if ! gh auth status --hostname github.com; then
        gh auth login --web --git-protocol https --hostname github.com </dev/tty
    fi
    gh auth setup-git --hostname github.com </dev/tty
    if [ -d "$HOME/.local/share/chezmoi" ]; then
        # Self-heal hq: finish/abort stuck rebases or merges; on conflict GitHub's version wins.
        hq="$HOME/.local/share/chezmoi"
        git -C "$hq" rebase --abort >/dev/null 2>&1 || true
        git -C "$hq" merge --abort >/dev/null 2>&1 || true
        git -C "$hq" add -A && git -C "$hq" commit -qm "kit: local state before update" >/dev/null 2>&1 || true
        git -C "$hq" fetch -q origin
        if ! git -C "$hq" rebase -q origin/main >/dev/null 2>&1; then
            git -C "$hq" rebase --abort >/dev/null 2>&1 || true
            git -C "$hq" merge -q --no-edit -X theirs origin/main
        fi
        git -C "$hq" push -q origin HEAD:main >/dev/null 2>&1 || true
        chezmoi apply --force </dev/tty
    else
        chezmoi init --apply "https://github.com/$KIT_USER/hq.git" </dev/tty
    fi
    printf '%s\n' 'kit setup complete.'
)

# No child process may accidentally consume the streamed script as stdin.
main </dev/null
