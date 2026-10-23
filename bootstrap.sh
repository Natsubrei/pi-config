#!/usr/bin/env bash
set -euo pipefail

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_FILE="$REPO_DIR/.local/settings.local.json"
TRACKED=(settings.json AGENTS.md)

git -C "$REPO_DIR" config filter.piSettings.clean "node \"$REPO_DIR/filter.js\" clean"
git -C "$REPO_DIR" config filter.piSettings.smudge "node \"$REPO_DIR/filter.js\" smudge"
git -C "$REPO_DIR" config filter.piSettings.required true

mkdir -p "$AGENT_DIR" "$(dirname "$LOCAL_FILE")"
[ -f "$LOCAL_FILE" ] || echo '{}' > "$LOCAL_FILE"

# 必须在挂软链之前：此时 $AGENT_DIR/settings.json 还是本机真实文件。
if [ -f "$AGENT_DIR/settings.json" ] && [ ! -L "$AGENT_DIR/settings.json" ]; then
  node "$REPO_DIR/filter.js" extract "$AGENT_DIR/settings.json"
fi

for f in "${TRACKED[@]}"; do
  if [ -f "$AGENT_DIR/$f" ] && [ ! -L "$AGENT_DIR/$f" ]; then
    cp "$AGENT_DIR/$f" "$AGENT_DIR/$f.bak"
  fi
  ln -sfn "$REPO_DIR/$f" "$AGENT_DIR/$f"
done

# 重新检出，让 smudge 把刚迁入的存档合并回工作区。
rm -f "$REPO_DIR/settings.json"
git -C "$REPO_DIR" checkout -q -- settings.json
git -C "$REPO_DIR" add settings.json
