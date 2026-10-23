# pi-config

pi 的多设备配置同步仓库，软链挂到 `~/.pi/agent/`。

`settings.json` 里有一组只属于本机的字段，不进仓库：

- `defaultProvider`、`defaultModel`、`defaultThinkingLevel`、`modelThinkingLevels`
- `lastChangelogVersion`（pi 升级时改写，各设备各自一份）

靠 git 的 clean/smudge 过滤器做转换：提交或比较前（clean）把这些字段剥走，存进 `.local/settings.local.json`（已 gitignore）；检出时（smudge）再合并回来。Pi 把默认模型写回 `settings.json` 之后，下次 git 操作会再走 clean，所以这个选择只在本机生效。`packages`、`theme` 等公共字段照常同步。

## 新设备

```bash
git clone <仓库地址> ~/workspace/pi-config
cd ~/workspace/pi-config && ./bootstrap.sh
pi update --extensions
```

`bootstrap.sh` 会注册过滤器（`required`，失败则 git 报错）、把本机已有 `settings.json` 里的本机字段迁入 `.local`、挂上软链，再重新检出 `settings.json` 让 smudge 把存档写回，并 `git add` 对齐索引。

之后在 `/settings` 里选的默认模型只留在本机。

## 同步公共配置

```bash
cd ~/workspace/pi-config
git add -A && git commit -m "chore: 更新配置" && git push
```

其他设备 `git pull` 即可。

Pi 每次写回 `settings.json` 都会换成一个新文件。git 对带过滤器的文件不比较内容，只看修改时间等元数据，所以 `git status` 常显示 `M settings.json`，实际与仓库相同。`git add settings.json` 可刷新索引，且不会产生提交内容。

`git pull` 之前先跑这条。否则刚写入的默认模型还没存档，检出会被旧存档覆盖。

## 新增要同步的文件

1. 移入仓库并挂软链：
   ```bash
   mv ~/.pi/agent/keybindings.json ~/workspace/pi-config/
   ln -s ~/workspace/pi-config/keybindings.json ~/.pi/agent/keybindings.json
   ```
2. 把文件名加入 `bootstrap.sh` 的 `TRACKED=(settings.json AGENTS.md)`
3. 提交；其他设备 `git pull` 后重新运行 `./bootstrap.sh`

## AGENTS.md

本仓库的 `AGENTS.md` 是 Pi 的全局指令母本，只放指令正文；维护说明写在本 README。`bootstrap.sh` 把 `~/.pi/agent/AGENTS.md` 软链到母本，改规则只改这一份，然后 `/reload`（或重启）。

在本仓库目录里运行 Pi 时，母本会加载两次（全局 + 项目）。Pi 或扩展若改写该文件，会经软链写进母本。

## 不纳入同步

- `.local/` — 本机字段存档
- `auth.json` — API 密钥，各设备单独登录
- `models-store.json`、`sessions/` 等本机内容
