#!/bin/bash
set -euo pipefail

# Provide minimal implementation for helpers used by this script when running in CI
# This prevents "command not found" failures for `download` and `git-mini-clone` on runners
# that don't have project helper scripts pre-sourced.

# download <name> <url> [<outpath>]
# - Prefer curl, fallback to wget
# - Retry network failures lightly
download() {
  local name="$1"
  local url="$2"
  local out="${3:-${name}.tar.gz}"

  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --retry-delay 2 -o "$out" "$url" || {
      echo "[download] curl failed to download $url" >&2
      return 1
    }
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url" || {
      echo "[download] wget failed to download $url" >&2
      return 1
    }
    return 0
  fi

  echo "[download] error: neither curl nor wget is available" >&2
  return 1
}

# git-mini-clone <repo-url> <commit-or-branch> <dest>
# - Best-effort clone and checkout of given revision into dest (defaults to current dir '.')
# - Handles shallow clone, and falls back to init+fetch when needed
git-mini-clone() {
  local repo="$1"
  local rev="$2"
  local dest="${3:-.}"

  mkdir -p "$dest"

  # If dest already has .git and rev exists, try to checkout
  if [ -d "$dest/.git" ]; then
    (cd "$dest" && git fetch --all --prune >/dev/null 2>&1 || true)
    if (cd "$dest" && git rev-parse --verify --quiet "$rev" >/dev/null 2>&1); then
      (cd "$dest" && git checkout --quiet "$rev" || true)
      return 0
    fi
  fi

  # Try a regular shallow clone
  if git clone --no-tags --depth 50 "$repo" "$dest" 2>/dev/null; then
    (cd "$dest" && {
      git fetch --depth=1 origin "$rev" >/dev/null 2>&1 || true
      git checkout --quiet "$rev" || git checkout --quiet -b tmp-branch "$rev" || true
    })
    return 0
  fi

  # Fallback: init + fetch
  rm -rf "$dest"
  mkdir -p "$dest"
  git init "$dest"
  (cd "$dest" && git remote add origin "$repo" && {
    git fetch --no-tags --depth 50 origin "$rev" >/dev/null 2>&1 || git fetch --no-tags origin || true
    git checkout --quiet "$rev" || git checkout --quiet -b tmp-branch "$rev" || true
  })
  return 0
}

# End helper implementations


# Original file content follows

download fdk-aac https://github.com/mstorsjo/fdk-aec/archive/refs/tags/v2.0.2.tar.gz
build fdk-aac -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download whisper.cpp https://github.com/ggerganov/whisper.cpp/archive/refs/tags/v1.3.0.tar.gz
build whisper.cpp -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download aribb24 https://github.com/nkoriyama/aribb24/archive/refs/heads/master.tar.gz
build aribb24 --disable-shared --enable-static

download aribcaption https://github.com/nkoriyama/aribcaption/archive/refs/heads/master.tar.gz
build aribcaption -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download lc3 https://github.com/google/liblc3/archive/refs/tags/v1.0.3.tar.gz
build lc3 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS \\
  --enable-libfdk-aac \
  --enable-libwhisper \
  --enable-libaribb24 \
  --enable-libaribcaption \
  --enable-liblc3 \
  --enable-d3d12va \
  --enable-libshaderc \
  --enable-libplacebo"


if [[ -f /tmp/sdks.zip ]]; then
  unzip -q /tmp/sdks.zip -d /opt/sdks
  EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS \\
    --enable-decklink     --extra-cflags=-I/opt/sdks/DecklinkSDK/include --extra-ldflags=-L/opt/sdks/DecklinkSDK/lib \
    --enable-libndi_newtek --extra-cflags=-I/opt/sdks/NDI/SDK/include    --extra-ldflags=-L/opt/sdks/NDI/SDK/lib"
fi
