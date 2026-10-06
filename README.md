# pi-config

pi 的多设备配置同步仓库，通过软链挂载到 `~/.pi/agent/`。

机器相关的默认模型配置（`defaultProvider`、`defaultModel`、
`defaultThinkingLevel`、`lastChangelogVersion`）由 git clean/smudge 过滤器
在本机与仓库之间双向转换：

- clean：提交或比较前剥离这些字段，并存档到 `.local/settings.local.json`
  （已被 gitignore，不进仓库）。
- smudge：检出时把存档合并回 `settings.json`。

Pi 会把默认模型写回 `settings.json`（软链到本仓库）。clean 在下次 git 操作时
把它存档，所以该选择只在本机生效，不会被提交。`packages`、`theme` 等公共字段
照常同步。

## 新设备恢复

```bash
git clone <仓库地址> ~/workspace/pi-config
cd ~/workspace/pi-config && ./bootstrap.sh
pi update --extensions
```

bootstrap.sh 会注册 git 过滤器（含 `filter.piSettings.required`，过滤器失败时
git 直接报错）、把本机旧 `settings.json` 的默认模型迁入 `.local` 存档，并挂载
配置软链。之后在 `/settings` 里选择的默认模型只保存在本机，不会被提交。

## 本机改动后同步

```bash
cd ~/workspace/pi-config
git add -A && git commit -m "chore: 更新配置" && git push
```

其他设备 `git pull` 即可生效（软链实时指向仓库文件）。

## 幻影改动

Pi 用「临时文件 + 改名」写回 `settings.json`，每次写回都换 inode。git 对带
filter 的文件只比较 stat，因此 `git status` 会显示 `M settings.json`，而内容
没有变化。刷新索引即可：

```bash
git add settings.json
```

该命令没有副作用：clean 剥离后内容与仓库一致，不会产生任何提交内容。

`git pull` 之前请先运行该命令。否则 Pi 刚写入的默认模型还没存档，检出会用旧
存档把它覆盖。

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

- `.local/` —— 本机默认模型存档（由 filter 自动读写，初始为 `{}`）
- `auth.json` —— API 密钥，各设备单独登录
- `models-store.json`、`sessions/` 等本机内容
