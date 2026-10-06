#!/usr/bin/env bash
# 在新设备上恢复 pi 配置：git clone <本仓库> && ./bootstrap.sh
#
# 步骤：1 注册 git 过滤器  2 准备本机存档  3 迁移本机旧配置
#       4 挂载配置软链      5 按存档重建 settings.json
set -euo pipefail

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_FILE="$REPO_DIR/.local/settings.local.json"
TRACKED=(settings.json sol-pi.json AGENTS.md)

# --- 1. 注册 git 过滤器，由 filter.js 实现 ------------------------------
# clean 剥离本机字段并存档；smudge 检出时恢复；required 让过滤器失败时
# git 直接报错，而不是静默写入未剥离的内容。
git -C "$REPO_DIR" config filter.piSettings.clean "node \"$REPO_DIR/filter.js\" clean"
git -C "$REPO_DIR" config filter.piSettings.smudge "node \"$REPO_DIR/filter.js\" smudge"
git -C "$REPO_DIR" config filter.piSettings.required true

# --- 2. 准备本机存档，初始为空对象 --------------------------------------
mkdir -p "$AGENT_DIR" "$(dirname "$LOCAL_FILE")"
[ -f "$LOCAL_FILE" ] || echo '{}' > "$LOCAL_FILE"

# --- 3. 迁移本机旧配置里的默认模型 --------------------------------------
# 必须在挂软链之前执行：此时 $AGENT_DIR/settings.json 还是本机真实文件。
if [ -f "$AGENT_DIR/settings.json" ] && [ ! -L "$AGENT_DIR/settings.json" ]; then
  node "$REPO_DIR/filter.js" extract "$AGENT_DIR/settings.json"
fi

# --- 4. 挂载配置软链 ----------------------------------------------------
# AGENTS.md 是 pi 的全局指令母本，改它即改全局指令。
for f in "${TRACKED[@]}"; do
  # 只备份本机真实文件；已是指向仓库的软链则跳过，避免反复覆盖 .bak
  if [ -f "$AGENT_DIR/$f" ] && [ ! -L "$AGENT_DIR/$f" ]; then
    cp "$AGENT_DIR/$f" "$AGENT_DIR/$f.bak"
  fi
  ln -sfn "$REPO_DIR/$f" "$AGENT_DIR/$f"
done

# --- 5. 按存档重建 settings.json ----------------------------------------
# 删除后重新检出，让 smudge 把步骤 3 得到的存档合并回工作区。
rm -f "$REPO_DIR/settings.json"
git -C "$REPO_DIR" checkout -q -- settings.json
# 刷新索引，避免 pi 下次写回后 git status 出现幻影改动
git -C "$REPO_DIR" add settings.json
