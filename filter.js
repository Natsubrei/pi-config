#!/usr/bin/env node
// settings.json 的 git 过滤器：
//   clean  —— 提交时剥离机器相关的默认模型配置（不进仓库）
//   smudge —— 检出时从 .local/settings.local.json 合并回本机配置
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
    for (const k of MACHINE_KEYS) delete data[k];
  } else if (mode === "smudge" && fs.existsSync(LOCAL_FILE)) {
    try {
      Object.assign(data, JSON.parse(fs.readFileSync(LOCAL_FILE, "utf8")));
    } catch {
      // 本地文件损坏时忽略，保持仓库内容
    }
  }
  process.stdout.write(JSON.stringify(data, null, 2) + "\n");
});
