#!/usr/bin/env bash
# 在新设备上恢复 pi 配置：git clone <本仓库> && ./bootstrap.sh
set -e
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$AGENT_DIR" "$REPO_DIR/.local"
# 注册 git 过滤器（提交时剥离默认模型配置，检出时合并回本机配置）
git -C "$REPO_DIR" config filter.piSettings.clean "node \"$REPO_DIR/filter.js\" clean"
git -C "$REPO_DIR" config filter.piSettings.smudge "node \"$REPO_DIR/filter.js\" smudge"
# 本机默认模型配置文件（不存在则初始化为空对象）
[ -f "$REPO_DIR/.local/settings.local.json" ] || echo '{}' > "$REPO_DIR/.local/settings.local.json"
# 挂载配置软链（AGENTS.md 为 Pi 的全局指令文件）
for f in settings.json sol-pi.json AGENTS.md; do
  # 只在遇到本机真实文件时留备份；已是指向仓库的软链则跳过，避免反复覆盖 .bak
  if [ -f "$AGENT_DIR/$f" ] && [ ! -L "$AGENT_DIR/$f" ]; then
    cp "$AGENT_DIR/$f" "$AGENT_DIR/$f.bak"
  fi
  ln -sfn "$REPO_DIR/$f" "$AGENT_DIR/$f"
done
# 强制重新检出 settings.json，使 smudge 过滤器合并本机配置
rm -f "$REPO_DIR/settings.json"
git -C "$REPO_DIR" checkout -q -- settings.json
# 刷新 git 索引，避免 pi 重写文件后 status 出现幻影改动
git -C "$REPO_DIR" add settings.json 2>/dev/null || true
