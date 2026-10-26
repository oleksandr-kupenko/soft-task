#!/usr/bin/env node
/**
 * Minimal screenshot helper for visual acceptance.
 * usage: node shot.mjs <url> <out.png> [--width 1280] [--height 800] [--wait 1000]
 *
 * Uses playwright-core if installed in the target project or globally.
 * soft-task does not vendor Playwright — the project or the user installs it.
 */
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import { resolve, dirname } from "node:path";
import { mkdirSync } from "node:fs";

const args = process.argv.slice(2);
if (args.length < 2) {
  console.error("usage: shot.mjs <url> <out.png> [--width N] [--height N] [--wait ms]");
  process.exit(2);
}

const url = args[0];
const out = resolve(args[1]);
let width = 1280;
let height = 800;
let wait = 1000;
for (let i = 2; i < args.length; i++) {
  if (args[i] === "--width") width = Number(args[++i]);
  else if (args[i] === "--height") height = Number(args[++i]);
  else if (args[i] === "--wait") wait = Number(args[++i]);
}

async function loadPlaywright() {
  const tried = [];
  for (const name of ["playwright", "playwright-core"]) {
    try {
      return await import(name);
    } catch (e) {
      tried.push(`${name}: ${e.message}`);
    }
  }
  // walk up from cwd for node_modules
  const require = createRequire(pathToFileURL(resolve(process.cwd(), "package.json")).href);
  for (const name of ["playwright", "playwright-core"]) {
    try {
      return require(name);
    } catch (e) {
      tried.push(`require ${name}: ${e.message}`);
    }
  }
  console.error("Playwright not found. Install in the project: npm i -D playwright");
  console.error(tried.join("\n"));
  process.exit(3);
}

const pw = await loadPlaywright();
const browser = await pw.chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width, height } });
await page.goto(url, { waitUntil: "networkidle", timeout: 60000 }).catch(async () => {
  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
});
if (wait > 0) await page.waitForTimeout(wait);
mkdirSync(dirname(out), { recursive: true });
await page.screenshot({ path: out, fullPage: true });
await browser.close();
console.log(out);
