#!/usr/bin/env node
/**
 * soft-task CLI — install / doctor / uninstall (no npm dependencies).
 *
 *   npx github:<you>/soft-task install [--harness opencode|cursor|claude|codex|all] [--global|--project]
 *   npx github:<you>/soft-task doctor
 *   npx github:<you>/soft-task uninstall [--harness ...]
 */
import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
  lstatSync,
  unlinkSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");
const HOME = homedir();

const HARNESSES = {
  opencode: {
    skillDir: join(HOME, ".claude", "skills", "soft-task"),
    altSkillDirs: [
      join(HOME, ".agents", "skills", "soft-task"),
      join(HOME, ".config", "opencode", "skills", "soft-task"),
    ],
    commandDir: join(HOME, ".config", "opencode", "command"),
    commandFile: "soft-task.md",
  },
  cursor: {
    skillDir: join(HOME, ".cursor", "skills", "soft-task"),
    commandDir: join(HOME, ".cursor", "commands"),
    commandFile: "soft-task.md",
  },
  claude: {
    skillDir: join(HOME, ".claude", "skills", "soft-task"),
    commandDir: null,
    commandFile: null,
  },
  codex: {
    skillDir: join(HOME, ".agents", "skills", "soft-task"),
    altSkillDirs: [join(HOME, ".codex", "skills", "soft-task")],
    commandDir: null,
    commandFile: null,
  },
};

function usage() {
  console.log(`soft-task ${readVersion()}

Usage:
  soft-task install [--harness opencode|cursor|claude|codex|all] [--global|--project] [--yes]
  soft-task doctor
  soft-task uninstall [--harness ...]
  soft-task help

Environment:
  SOFTORIA_API_KEY   Softoria API key (never printed). Required for Softoria-HD/SD.
  SOFT_TASK_ROOT     Set by install to this package root.
`);
}

function readVersion() {
  try {
    return JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")).version;
  } catch {
    return "0.0.0";
  }
}

function parseArgs(argv) {
  const args = { cmd: argv[0] || "help", harness: "all", scope: "global", yes: false };
  for (let i = 1; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--harness") args.harness = argv[++i];
    else if (a === "--global") args.scope = "global";
    else if (a === "--project") args.scope = "project";
    else if (a === "--yes" || a === "-y") args.yes = true;
    else if (a === "--help" || a === "-h") args.cmd = "help";
  }
  return args;
}

function selectedHarnesses(name) {
  if (!name || name === "all") return Object.keys(HARNESSES);
  if (!HARNESSES[name]) {
    console.error(`unknown harness: ${name}`);
    process.exit(2);
  }
  return [name];
}

function linkOrCopySkill(dest) {
  mkdirSync(dirname(dest), { recursive: true });
  if (existsSync(dest)) {
    const st = lstatSync(dest);
    if (st.isSymbolicLink() || st.isDirectory() || st.isFile()) {
      rmSync(dest, { recursive: true, force: true });
    }
  }
  const skillSrc = join(ROOT, "skill");
  try {
    symlinkSync(skillSrc, dest, "dir");
    console.log(`  linked skill → ${dest}`);
  } catch {
    cpSync(skillSrc, dest, { recursive: true });
    console.log(`  copied skill → ${dest}`);
  }
}

function installCommand(h, name) {
  const cfg = HARNESSES[name];
  if (!cfg.commandDir) return;
  mkdirSync(cfg.commandDir, { recursive: true });
  const src = join(ROOT, "opencode", "command", "soft-task.md");
  const dest = join(cfg.commandDir, cfg.commandFile);
  // Cursor commands: short wrapper
  if (name === "cursor") {
    writeFileSync(
      dest,
      `---
description: Run soft-task (brief/ticket → Softoria-HD build → acceptance)
---

Follow the soft-task skill at ~/.cursor/skills/soft-task/SKILL.md (or $SOFT_TASK_ROOT/skill/SKILL.md).
Start Phase 0. Pass arguments after the command as mode/depth/brief.
`,
      "utf8",
    );
  } else {
    copyFileSync(src, dest);
  }
  console.log(`  command → ${dest}`);
}

function deepMerge(a, b) {
  if (Array.isArray(b)) return b.slice();
  if (b && typeof b === "object") {
    const out = { ...(a && typeof a === "object" ? a : {}) };
    for (const [k, v] of Object.entries(b)) {
      out[k] = k in out ? deepMerge(out[k], v) : deepMerge(undefined, v);
    }
    return out;
  }
  return b;
}

function mergeOpencodeConfig(yes) {
  const cfgPath = join(HOME, ".config", "opencode", "opencode.json");
  const fragment = JSON.parse(
    readFileSync(join(ROOT, "opencode", "provider.fragment.json"), "utf8"),
  );
  mkdirSync(dirname(cfgPath), { recursive: true });
  let current = {};
  if (existsSync(cfgPath)) {
    try {
      current = JSON.parse(readFileSync(cfgPath, "utf8"));
    } catch (e) {
      console.error(`Cannot parse ${cfgPath}: ${e.message}`);
      process.exit(1);
    }
  }

  const hasSoftoria = current.provider && current.provider.softoria;
  const hasVision = current.agent && current.agent.vision;

  if (hasSoftoria && hasVision) {
    console.log("  opencode.json already has softoria provider + vision agent — left untouched");
    return;
  }

  if (!yes) {
    console.log(`
  About to merge Softoria provider + vision agent into:
    ${cfgPath}
  apiKey will be "{env:SOFTORIA_API_KEY}" — your existing keys are never read or copied.
  Re-run with --yes to apply, or merge opencode/provider.fragment.json yourself.
`);
    return;
  }

  const bak = cfgPath + ".bak-soft-task-" + Date.now();
  if (existsSync(cfgPath)) copyFileSync(cfgPath, bak);
  const merged = deepMerge(current, fragment);
  writeFileSync(cfgPath, JSON.stringify(merged, null, 2) + "\n", "utf8");
  console.log(`  merged opencode.json (backup: ${bak})`);
  console.log("  Set SOFTORIA_API_KEY in your environment. Never commit the key.");
}

function writeEnvHint() {
  const hint = join(ROOT, ".env.example");
  if (!existsSync(hint)) {
    writeFileSync(
      hint,
      `# Softoria API (HD + SD). Put the real value in your shell profile or a local .env — never commit it.
SOFTORIA_API_KEY=
`,
      "utf8",
    );
  }
}

function writeRootMarker() {
  const marker = join(HOME, ".config", "soft-task", "root");
  mkdirSync(dirname(marker), { recursive: true });
  writeFileSync(marker, ROOT + "\n", "utf8");
  console.log(`  SOFT_TASK_ROOT marker → ${marker}`);
  console.log(`  Add to your shell: export SOFT_TASK_ROOT="${ROOT}"`);
}

function cmdInstall(args) {
  console.log(`Installing soft-task ${readVersion()} from ${ROOT}`);
  writeEnvHint();
  writeRootMarker();
  for (const name of selectedHarnesses(args.harness)) {
    console.log(`\n[${name}]`);
    const cfg = HARNESSES[name];
    if (args.scope === "project") {
      const dest = join(process.cwd(), ".claude", "skills", "soft-task");
      linkOrCopySkill(dest);
      if (name === "cursor") {
        linkOrCopySkill(join(process.cwd(), ".cursor", "skills", "soft-task"));
      }
    } else {
      linkOrCopySkill(cfg.skillDir);
      for (const alt of cfg.altSkillDirs || []) {
        linkOrCopySkill(alt);
      }
    }
    installCommand(HARNESSES[name], name);
  }
  if (selectedHarnesses(args.harness).includes("opencode") || args.harness === "all") {
    console.log("\n[opencode config]");
    mergeOpencodeConfig(args.yes);
  }
  console.log(`
Done.
  1. export SOFTORIA_API_KEY=…   (if not set)
  2. export SOFT_TASK_ROOT="${ROOT}"
  3. soft-task doctor
  4. In your agent: /soft-task <brief or task>
`);
}

function cmdUninstall(args) {
  for (const name of selectedHarnesses(args.harness)) {
    const cfg = HARNESSES[name];
    for (const dir of [cfg.skillDir, ...(cfg.altSkillDirs || [])]) {
      if (existsSync(dir)) {
        rmSync(dir, { recursive: true, force: true });
        console.log(`removed ${dir}`);
      }
    }
    if (cfg.commandDir) {
      const f = join(cfg.commandDir, cfg.commandFile);
      if (existsSync(f)) {
        unlinkSync(f);
        console.log(`removed ${f}`);
      }
    }
  }
  console.log("Uninstall complete. opencode.json was not modified (merge is left in place).");
}

function which(bin) {
  const r = spawnSync("bash", ["-lc", `command -v ${bin}`], { encoding: "utf8" });
  return r.status === 0 ? r.stdout.trim() : null;
}

function cmdDoctor() {
  const lines = [];
  const ok = (m) => lines.push(`PASS  ${m}`);
  const bad = (m) => lines.push(`FAIL  ${m}`);
  const warn = (m) => lines.push(`WARN  ${m}`);

  const py = which("python3") || which("python");
  py ? ok(`python: ${py}`) : bad("python3 not found");

  const git = which("git");
  git ? ok(`git: ${git}`) : bad("git not found");

  const oc = which("opencode");
  if (oc) {
    const v = spawnSync("opencode", ["--version"], { encoding: "utf8" });
    ok(`opencode: ${oc} (${(v.stdout || v.stderr || "").trim() || "?"})`);
  } else {
    bad("opencode not found — required for Softoria-HD executor and Softoria-SD vision");
  }

  if (process.env.SOFTORIA_API_KEY) ok("SOFTORIA_API_KEY is set (value not shown)");
  else bad("SOFTORIA_API_KEY is not set");

  const rootMarker = join(HOME, ".config", "soft-task", "root");
  if (process.env.SOFT_TASK_ROOT || existsSync(rootMarker)) {
    ok(`SOFT_TASK_ROOT: ${process.env.SOFT_TASK_ROOT || readFileSync(rootMarker, "utf8").trim()}`);
  } else {
    warn("SOFT_TASK_ROOT not set — install writes a marker under ~/.config/soft-task/root");
  }

  const cfgPath = join(HOME, ".config", "opencode", "opencode.json");
  if (existsSync(cfgPath)) {
    try {
      const cfg = JSON.parse(readFileSync(cfgPath, "utf8"));
      if (cfg.provider?.softoria) ok("opencode softoria provider present");
      else warn("opencode softoria provider missing — run: soft-task install --harness opencode --yes");
      if (cfg.agent?.vision) ok("opencode vision agent present");
      else warn("opencode vision agent missing — run install --yes");
    } catch (e) {
      bad(`opencode.json parse error: ${e.message}`);
    }
  } else {
    warn("no ~/.config/opencode/opencode.json");
  }

  // API ping (name only; no key echo)
  if (oc && process.env.SOFTORIA_API_KEY) {
    console.log("Pinging Softoria-HD (1 token)…");
    const ping = spawnSync(
      "opencode",
      ["run", "--auto", "--standalone", "--pure", "--model", "softoria/Softoria-HD#low", "--", "Reply with exactly: pong"],
      { encoding: "utf8", timeout: 120000, env: process.env },
    );
    const out = (ping.stdout || "") + (ping.stderr || "");
    if (ping.status === 0 && /pong/i.test(out)) ok("Softoria-HD ping ok");
    else if (/timeout|ECONN|ENOTFOUND|5\d\d|fetch|network/i.test(out) || ping.status !== 0) {
      bad("Softoria-HD ping failed — enable corporate VPN and check SOFTORIA_API_KEY");
      if (out.trim()) lines.push("      " + out.trim().split("\n").slice(-3).join(" | "));
    } else {
      warn("Softoria-HD ping inconclusive");
    }
  }

  // skill presence
  for (const name of Object.keys(HARNESSES)) {
    const d = HARNESSES[name].skillDir;
    existsSync(join(d, "SKILL.md")) ? ok(`skill (${name}): ${d}`) : warn(`skill missing (${name}): ${d}`);
  }

  console.log(lines.join("\n"));
  const failed = lines.some((l) => l.startsWith("FAIL"));
  process.exit(failed ? 1 : 0);
}

const args = parseArgs(process.argv.slice(2));
switch (args.cmd) {
  case "install":
    cmdInstall(args);
    break;
  case "uninstall":
    cmdUninstall(args);
    break;
  case "doctor":
    cmdDoctor();
    break;
  case "help":
  case undefined:
    usage();
    break;
  default:
    console.error(`unknown command: ${args.cmd}`);
    usage();
    process.exit(2);
}
