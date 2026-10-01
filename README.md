# pi-config

pi 的多设备配置同步仓库，通过软链挂载到 `~/.pi/agent/`。

机器相关的默认模型配置（`defaultProvider`、`defaultModel` 等）通过 git
clean/smudge 过滤器自动剥离，不会进入仓库；各设备的这份配置存放在
`.local/settings.local.json`（已被 gitignore）。

## 新设备恢复

```bash
git clone <仓库地址> ~/workspace/pi-config
cd ~/workspace/pi-config && ./bootstrap.sh
pi update --extensions
```

bootstrap.sh 会自动注册 git 过滤器并挂载配置软链。之后在 `/settings` 里
选择的默认模型只保存在本机，不会被提交。

## 本机改动后同步

```bash
cd ~/workspace/pi-config
git add -A && git commit -m "chore: 更新配置" && git push
```

其他设备 `git pull` 即可生效（软链实时指向仓库文件）。

## 新增要同步的文件

1. 把文件（如 `keybindings.json`）移入本仓库：
   ```bash
   mv ~/.pi/agent/keybindings.json ~/workspace/pi-config/
   ln -s ~/workspace/pi-config/keybindings.json ~/.pi/agent/keybindings.json
   ```
2. 在 `bootstrap.sh` 的 `for f in settings.json sol-pi.json` 列表中加上该文件名
3. 提交并推送，其他设备 `git pull` 后重新运行 `./bootstrap.sh`

## 全局指令 AGENTS.md

本仓库的 `AGENTS.md` 是 Pi 的全局指令母本，刻意只放指令正文：它会被全文加载，维护说明、命令示例一律写在本 README 里，不写进母本。

`~/.pi/agent/AGENTS.md` 是指向本仓库 `AGENTS.md` 的软链（由 `bootstrap.sh` 挂载），因此改规则时只改母本，不要在别处建副本。Pi 读上下文用的是跟随软链的 `statSync(path).isFile()`，软链可正常加载。改完在 Pi 里 `/reload`（或重启）生效。

已知风险：

- **重复加载**：在 `~/workspace/pi-config` 目录里运行 Pi 时，母本既作为全局指令加载，又作为项目上下文 `./AGENTS.md` 加载，内容相同但会注入两次。
- **写回**：若 Pi 或扩展自己改写这个文件，会通过软链直接改到母本，表现为母本里出现与本机相关的专属内容。

## 不纳入同步的文件

- `.local/` —— 本机默认模型配置（由过滤器自动管理）
- `auth.json` —— API 密钥，各设备单独登录
- `models-store.json`、`sessions/` 等本机内容
