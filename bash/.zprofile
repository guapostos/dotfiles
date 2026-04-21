# MacPorts Installer addition: keep MacPorts on PATH for login shells.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Keep rustup-managed Rust ahead of package-manager installs for login shells.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
