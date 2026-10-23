#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const mode = process.argv[2];
const MACHINE_KEYS = [
  "lastChangelogVersion",
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
    return {};
  }
}

function writeLocal(data) {
  fs.mkdirSync(path.dirname(LOCAL_FILE), { recursive: true });
  fs.writeFileSync(LOCAL_FILE, JSON.stringify(data, null, 2) + "\n");
}

function archive(data) {
  const machine = {};
  for (const k of MACHINE_KEYS) if (k in data) machine[k] = data[k];
  if (Object.keys(machine).length === 0) return;
  // 合并，避免 pi 只改写部分字段时冲掉其余本机值。
  writeLocal({ ...readLocal(), ...machine });
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
      process.exit(0);
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
    process.stdout.write(raw);
    return;
  }
  if (mode === "clean") {
    archive(data);
    strip(data);
  } else if (mode === "smudge") {
    Object.assign(data, readLocal());
  }
  process.stdout.write(JSON.stringify(data, null, 2) + "\n");
});
