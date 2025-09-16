#!/usr/bin/env bash
set -euo pipefail

# exline installer (prototype)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/scripts/install.sh | sh
#
# Options (env vars or flags):
#   EXLINE_REPO="owner/repo"   # default: exline-lang/exlc
#   EXLINE_VERSION="latest"    # or "v0.1.0"
#   EXLINE_PREFIX="$HOME/.exline"   # install prefix
#   EXLINE_BIN_DIR="$EXLINE_PREFIX/bin"
#   --prefix <dir>     override EXLINE_PREFIX
#   --version <tag>    override EXLINE_VERSION
#   --force            overwrite existing binary
#   --no-modify-path   don't edit shell rc files
#   --uninstall        remove installed binary

EXLINE_REPO_DEFAULT="exline-lang/exlc"
EXLINE_REPO="${EXLINE_REPO:-$EXLINE_REPO_DEFAULT}"
EXLINE_VERSION="${EXLINE_VERSION:-latest}"
EXLINE_PREFIX="${EXLINE_PREFIX:-$HOME/.exline}"
EXLINE_BIN_DIR="${EXLINE_BIN_DIR:-$EXLINE_PREFIX/bin}"
FORCE=0
NO_MODIFY_PATH=0
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) EXLINE_PREFIX="$2"; shift 2;;
    --version) EXLINE_VERSION="$2"; shift 2;;
    --force) FORCE=1; shift;;
    --no-modify-path) NO_MODIFY_PATH=1; shift;;
    --uninstall) UNINSTALL=1; shift;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
done
EXLINE_BIN_DIR="${EXLINE_BIN_DIR:-$EXLINE_PREFIX/bin}"

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

detect_arch() {
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) echo "x86_64";;
    arm64|aarch64) echo "aarch64";;
    *) echo "unsupported";;
  esac
}

target_triple() {
  os="$(detect_os)"
  arch="$(detect_arch)"
  case "$os-$arch" in
    linux-x86_64) echo "x86_64-unknown-linux-gnu";;
    linux-aarch64) echo "aarch64-unknown-linux-gnu";;
    darwin-x86_64) echo "x86_64-apple-darwin";;
    darwin-aarch64) echo "aarch64-apple-darwin";;
    *) echo "unsupported";;
  esac
}

github_api() {
  url="$1"
  if command_exists curl; then
    curl -fsSL "$url"
  else
    echo "curl is required" >&2; exit 1
  fi
}

ensure_shasum() {
  if command_exists shasum; then
    echo "shasum -a 256"
  elif command_exists sha256sum; then
    echo "sha256sum"
  else
    echo ""
  fi
}

add_path_snippet() {
  local rc="$1"
  local line='export PATH="$HOME/.exline/bin:$PATH"'
  if [[ -f "$rc" ]]; then
    if ! grep -Fq "$line" "$rc"; then
      printf '\n# exline\n%s\n' "$line" >> "$rc"
      echo "Added PATH update to $rc"
    fi
  fi
}

uninstall() {
  local bin="$EXLINE_BIN_DIR/exlc"
  if [[ -f "$bin" ]]; then
    rm -f "$bin"
    echo "Removed $bin"
  else
    echo "exlc not found at $bin"
  fi
  echo "To remove PATH entry, edit your shell rc files (e.g., ~/.bashrc, ~/.zshrc)."
  exit 0
}

if [[ $UNINSTALL -eq 1 ]]; then
  uninstall
fi

os=$(detect_os)
arch=$(detect_arch)
triple=$(target_triple)
if [[ "$triple" == "unsupported" ]]; then
  echo "Unsupported platform: $(uname -s) $(uname -m)" >&2
  exit 1
fi

mkdir -p "$EXLINE_BIN_DIR"

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

version="$EXLINE_VERSION"
if [[ "$version" == "latest" ]]; then
  # fetch latest tag via GitHub API
  tag=$(github_api "https://api.github.com/repos/$EXLINE_REPO/releases/latest" | sed -n 's/ *"tag_name": "\(.*\)".*/\1/p' | head -n1)
  if [[ -z "$tag" ]]; then
    echo "Failed to determine latest release for $EXLINE_REPO" >&2
    exit 1
  fi
  version="$tag"
fi

asset="exlc-${version}-${triple}.tar.gz"
checksums="SHA256SUMS.txt"

download_url="https://github.com/$EXLINE_REPO/releases/download/${version}/${asset}"
checksums_url="https://github.com/$EXLINE_REPO/releases/download/${version}/${checksums}"

echo "Downloading $asset ..."
curl -fsSL "$download_url" -o "$TMPDIR/$asset"

echo "Downloading checksums ..."
if curl -fsSL "$checksums_url" -o "$TMPDIR/$checksums"; then
  sum_cmd=$(ensure_shasum)
  if [[ -n "$sum_cmd" ]]; then
    if command -v sha256sum >/dev/null 2>&1; then
      (cd "$TMPDIR" && sha256sum -c "$checksums" --ignore-missing)
    else
      want=$(grep "  $asset$" "$TMPDIR/$checksums" | awk '{print $1}')
      got=$(shasum -a 256 "$TMPDIR/$asset" | awk '{print $1}')
      [[ "$want" == "$got" ]] || { echo "Checksum mismatch"; exit 1; }
    fi
    echo "Checksum OK"
  else
    echo "No sha256 tool found; skipping checksum verification"
  fi
else
  echo "No checksum file found; continuing without verification"
fi

echo "Installing to $EXLINE_BIN_DIR ..."
tar -xzf "$TMPDIR/$asset" -C "$TMPDIR"
if [[ ! -f "$TMPDIR/exlc" ]]; then
  echo "Archive missing exlc binary" >&2
  exit 1
fi
if [[ -f "$EXLINE_BIN_DIR/exlc" && $FORCE -ne 1 ]]; then
  echo "exlc already exists at $EXLINE_BIN_DIR/exlc (use --force to overwrite)"
  exit 1
fi
install -m 0755 "$TMPDIR/exlc" "$EXLINE_BIN_DIR/exlc"

# PATH guidance
if [[ $NO_MODIFY_PATH -eq 0 ]]; then
  case "${SHELL:-}" in
    *zsh) add_path_snippet "$HOME/.zshrc";;
    *bash) add_path_snippet "$HOME/.bashrc";;
    *fish) echo 'set -gx PATH $HOME/.exline/bin $PATH' >> "$HOME/.config/fish/config.fish";;
    *) add_path_snippet "$HOME/.profile";;
  esac
  echo "Open a new shell or run: export PATH=\"$EXLINE_BIN_DIR:\$PATH\""
else
  echo "Remember to add $EXLINE_BIN_DIR to your PATH."
fi

echo "exlc installed: $("$EXLINE_BIN_DIR/exlc" --version || echo 'installed')"
