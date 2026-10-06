#!/usr/bin/env node
// settings.json 的 git 过滤器。本文件同时是 bootstrap.sh 的辅助脚本。
//
//   clean    —— 提交/比较时剥离机器相关字段，并把它存档到 .local/settings.local.json
//   smudge   —— 检出时把 .local 的存档合并回 settings.json
//   extract  —— 抽取任意 settings.json 里的机器字段，并入 .local 存档（供迁移使用）
//
// 存档文件不进仓库（.gitignore 覆盖 .local/），因此本机默认模型不参与同步。
const fs = require("fs");
const path = require("path");

const mode = process.argv[2];
const MACHINE_KEYS = [
  "lastChangelogVersion", // pi 内部状态：各设备随升级独立改写，无需同步
  "defaultProvider",
  "defaultModel",
  "defaultThinkingLevel",
  "modelThinkingLevels",
];
const LOCAL_FILE = path.join(__dirname, ".local", "settings.local.json");

function readLocal() {
  try {
    return JSON.parse(fs.readFileSync(LOCAL_FILE, "utf8"));
  } catch {
    return {}; // 文件缺失或损坏时按空处理
  }
}

function writeLocal(data) {
  fs.mkdirSync(path.dirname(LOCAL_FILE), { recursive: true });
  fs.writeFileSync(LOCAL_FILE, JSON.stringify(data, null, 2) + "\n");
}

// 把 data 中的机器字段并入 .local 存档。返回值表示是否真的写入了。
function archive(data) {
  const machine = {};
  for (const k of MACHINE_KEYS) if (k in data) machine[k] = data[k];
  if (Object.keys(machine).length === 0) return false;
  // 合并而不是覆盖：pi 可能只改写其中一部分字段
  writeLocal({ ...readLocal(), ...machine });
  return true;
}

function strip(data) {
  for (const k of MACHINE_KEYS) delete data[k];
}

if (mode === "extract") {
  const src = process.argv[3];
  if (src && fs.existsSync(src)) {
    try {
      archive(JSON.parse(fs.readFileSync(src, "utf8")));
    } catch {
      // 源文件损坏时不动存档
    }
  }
  process.exit(0);
}

let raw = "";
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    process.stdout.write(raw); // 解析失败时原样透传
    return;
  }
  if (mode === "clean") {
    // 只在输入确实带机器字段时存档。输入已是剥离后的内容时保留现有存档，
    // 避免用空值覆盖本机配置。
    archive(data);
    strip(data);
  } else if (mode === "smudge") {
    Object.assign(data, readLocal());
  }
  process.stdout.write(JSON.stringify(data, null, 2) + "\n");
});
