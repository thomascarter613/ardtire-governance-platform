#!/usr/bin/env node
/**
 * scripts/context/validate.mjs
 *
 * Validates the integrity and freshness of the context layer.
 * Safe to run in CI (non-TTY) and locally (TTY + color).
 *
 * Exit codes:
 *   0  All checks passed (warnings are non-fatal)
 *   1  One or more validation failures
 *   2  Unrecoverable system error
 *
 * Environment variables:
 *   CONTEXT_STALENESS_DAYS   Max days since state.md last committed  (default: 14)
 *   CONTEXT_ADR_DIR          Path to ADR directory                   (default: docs/architecture/decisions)
 *   CONTEXT_DIR              Path to context directory             (default: context)
 *   CI                       Auto-set by most CI runners; disables colour output
 */

import { execSync }                        from "node:child_process";
import { existsSync, readdirSync,
         readFileSync }                    from "node:fs";
import { join, relative }                 from "node:path";
import { cwd, env, exit, stdout }         from "node:process";

// ─── Config ───────────────────────────────────────────────────────────────────

const ROOT           = cwd();
const CONTEXT_DIR    = env.CONTEXT_DIR          ?? "context";
const ADR_DIR        = env.CONTEXT_ADR_DIR      ?? "docs/architecture/decisions";
const STALENESS_DAYS = Number(env.CONTEXT_STALENESS_DAYS ?? "14");
const IS_TTY         = stdout.isTTY && !env.CI;

// ─── Colour helpers ───────────────────────────────────────────────────────────

const COLOUR_KEYS = ["reset","bold","dim","red","green","yellow","cyan","gray"];
const ANSI        = ["\x1b[0m","\x1b[1m","\x1b[2m","\x1b[31m","\x1b[32m","\x1b[33m","\x1b[36m","\x1b[90m"];

const c = Object.fromEntries(
  COLOUR_KEYS.map((k, i) => [k, IS_TTY ? ANSI[i] : ""])
);

const icon = {
  pass: `${c.green}✓${c.reset}`,
  fail: `${c.red}✗${c.reset}`,
  warn: `${c.yellow}⚠${c.reset}`,
};

const print = (s) => stdout.write(s);

// ─── Types (JSDoc only — no runtime overhead) ─────────────────────────────────

/**
 * @typedef {{ file: string, message: string, hint?: string }} Issue
 * @typedef {{ label: string, failures: Issue[], warnings: Issue[] }} CheckResult
 */

// ─── Low-level helpers ────────────────────────────────────────────────────────

/** Read a repo-root-relative path. Returns null if the file does not exist. */
function readFile(rel) {
  const abs = join(ROOT, rel);
  return existsSync(abs) ? readFileSync(abs, "utf8") : null;
}

/**
 * Run a git command against ROOT. Returns trimmed stdout, or null on any error.
 * Stderr is suppressed — callers decide how to handle a null return value.
 */
function git(cmd) {
  try {
    const out = execSync(`git ${cmd}`, { cwd: ROOT, stdio: ["pipe", "pipe", "pipe"] })
                  .toString().trim();
    return out || null;
  } catch {
    return null;
  }
}

/**
 * Test whether `content` declares a given field.
 * Recognises three conventions used in this repo:
 *   Bold inline:    **Field:**
 *   Heading:        ## Field
 *   Frontmatter:    field:
 */
function hasField(content, field) {
  const f = field.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return [
    new RegExp(`\\*\\*${f}\\*\\*\\s*:`,   "im"),
    new RegExp(`^#{1,3}\\s+${f}\\s*$`,    "im"),
    new RegExp(`^${f}\\s*:`,              "im"),
  ].some(re => re.test(content));
}

/**
 * Extract the value portion of a `key: value` line.
 * Returns null if the field is absent.
 */
function extractFieldValue(content, field) {
  const f = field.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const m = content.match(new RegExp(`^${f}\\s*:\\s*(.+)$`, "im"));
  return m ? m[1].trim() : null;
}

// ─── Checks ───────────────────────────────────────────────────────────────────

/** @returns {CheckResult} */
function checkManifest() {
  const file    = `${CONTEXT_DIR}/manifest.md`;
  const result  = { label: "manifest.md — required fields", failures: [], warnings: [] };
  const content = readFile(file);

  if (!content) {
    result.failures.push({ file, message: "File not found", hint: "Run: just context-scaffold" });
    return result;
  }

  for (const { field, hint } of [
    { field: "Project",
      hint: "Add **Project:** under the Identity section" },
    { field: "Purpose",
      hint: "Add **Purpose:** (one sentence) under Identity" },
    { field: "Stack",
      hint: "Add a ## Stack section listing locked technology decisions" },
    { field: "Architecture Invariants",
      hint: "Add a ## Architecture Invariants section" },
    { field: "Active Phase",
      hint: "Add ## Active Phase with a pointer to state.md" },
  ]) {
    if (!hasField(content, field)) {
      result.failures.push({ file, message: `Missing required field: "${field}"`, hint });
    }
  }

  // Warn on unfilled placeholder values
  const purposeMatch = content.match(/\*\*Purpose:\*\*\s*(.+)/i);
  if (purposeMatch) {
    const val = purposeMatch[1].trim();
    if (val === "(one sentence)" || val.startsWith("TODO") || val.length < 12) {
      result.warnings.push({
        file,
        message: `Purpose appears to be a placeholder: "${val}"`,
        hint: "Replace with a real one-sentence description of this project",
      });
    }
  }

  return result;
}

/** @returns {CheckResult} */
function checkStateFreshness() {
  const file    = `${CONTEXT_DIR}/state.md`;
  const result  = { label: `state.md — required fields & freshness (≤ ${STALENESS_DAYS}d)`, failures: [], warnings: [] };
  const content = readFile(file);

  if (!content) {
    result.failures.push({ file, message: "File not found", hint: "Run: just context-scaffold" });
    return result;
  }

  // Structural fields
  for (const { field, hint } of [
    { field: "Phase",        hint: 'Add ## Phase, e.g. "Phase 1 — Foundation"' },
    { field: "Active Slice", hint: "Add ## Active Slice" },
  ]) {
    if (!hasField(content, field)) {
      result.failures.push({ file, message: `Missing required field: "${field}"`, hint });
    }
  }

  // Inline timestamp: _Last updated: YYYY-MM-DD_
  if (!/Last updated\s*:\s*\d{4}-\d{2}-\d{2}/i.test(content)) {
    result.failures.push({
      file,
      message: 'Missing or malformed "Last updated" timestamp',
      hint: "Add `_Last updated: YYYY-MM-DD_` as the second line of state.md",
    });
  }

  /*
   * Use git log for the commit date rather than fs.stat mtime.
   * fs.stat reflects the checkout time, not when the file was last meaningfully changed.
   */
  const lastCommit = git(`log -1 --format=%cd --date=short -- "${file}"`);

  if (!lastCommit) {
    result.warnings.push({
      file,
      message: "Cannot determine last commit date — file may be untracked",
      hint: "Commit state.md to enable staleness tracking",
    });
  } else {
    const ageMs   = Date.now() - new Date(lastCommit).getTime();
    const ageDays = Math.floor(ageMs / 86_400_000);

    if (ageDays > STALENESS_DAYS) {
      result.failures.push({
        file,
        message: `Stale — last committed ${ageDays}d ago (threshold: ${STALENESS_DAYS}d)`,
        hint: "Update context/state.md to reflect current work and commit it",
      });
    } else if (ageDays > Math.floor(STALENESS_DAYS * 0.75)) {
      result.warnings.push({
        file,
        message: `Last committed ${ageDays}d ago — approaching the ${STALENESS_DAYS}d threshold`,
      });
    }
  }

  return result;
}

/** @returns {CheckResult} */
function checkADRStatuses() {
  const result     = { label: "ADRs — status field presence and validity", failures: [], warnings: [] };
  const VALID      = new Set(["open", "decided", "superseded", "deprecated"]);
  const adrAbsPath = join(ROOT, ADR_DIR);

  if (!existsSync(adrAbsPath)) {
    result.warnings.push({ file: ADR_DIR, message: "ADR directory not found — skipping ADR checks" });
    return result;
  }

  let entries;
  try {
    entries = readdirSync(adrAbsPath, { withFileTypes: true });
  } catch (err) {
    result.failures.push({ file: ADR_DIR, message: `Cannot read directory: ${err.message}` });
    return result;
  }

  // Exclude ADR-000 (template) by naming convention
  const adrFiles = entries
    .filter(e => e.isFile() && e.name.endsWith(".md") && !e.name.startsWith("ADR-000"))
    .map(e => e.name);

  if (adrFiles.length === 0) {
    result.warnings.push({
      file: ADR_DIR,
      message: "No ADR files found — only the template exists",
      hint: "Create your first ADR when making a significant architectural decision",
    });
    return result;
  }

  for (const name of adrFiles) {
    const rel     = `${ADR_DIR}/${name}`;
    const content = readFile(rel);
    if (!content) continue;

    const raw = extractFieldValue(content, "status");

    if (!raw) {
      result.failures.push({
        file: rel,
        message: 'Missing required "status:" field',
        hint: "Add a line:  status: open | decided | superseded | deprecated",
      });
      continue;
    }

    if (!VALID.has(raw.toLowerCase().trim())) {
      result.failures.push({
        file: rel,
        message: `Invalid status value: "${raw}"`,
        hint: `Valid values: ${[...VALID].join(" | ")}`,
      });
    }
  }

  return result;
}

/** @returns {CheckResult} */
function checkSupportingFiles() {
  const result = { label: "context — supporting files & CLAUDE.md present", failures: [], warnings: [] };

  for (const { file, hint } of [
    { file: `${CONTEXT_DIR}/architecture.md`,
      hint: "Create context/architecture.md documenting system boundaries and data flow" },
    { file: `${CONTEXT_DIR}/conventions.md`,
      hint: "Create context/conventions.md documenting naming patterns and code-style rationale" },
  ]) {
    if (!existsSync(join(ROOT, file))) {
      result.failures.push({ file, message: "File not found", hint });
    }
  }

  if (!existsSync(join(ROOT, "CLAUDE.md"))) {
    result.warnings.push({
      file: "CLAUDE.md",
      message: "CLAUDE.md not found at repo root",
      hint: "Create CLAUDE.md so Claude Projects automatically picks up context/ pointers",
    });
  }

  return result;
}

// ─── Reporter ─────────────────────────────────────────────────────────────────

/** Print a CheckResult. Returns true if the check passed (zero failures). */
function report(result) {
  const passed  = result.failures.length === 0;
  const rowIcon = !passed ? icon.fail : result.warnings.length > 0 ? icon.warn : icon.pass;

  print(`  ${rowIcon} ${result.label}\n`);

  for (const { file, message, hint } of result.failures) {
    print(`      ${icon.fail} ${c.bold}${relative(ROOT, join(ROOT, file))}${c.reset}: ${message}\n`);
    if (hint) print(`        ${c.gray}→ ${hint}${c.reset}\n`);
  }

  for (const { file, message, hint } of result.warnings) {
    print(`      ${icon.warn} ${c.bold}${relative(ROOT, join(ROOT, file))}${c.reset}: ${message}\n`);
    if (hint) print(`        ${c.gray}→ ${hint}${c.reset}\n`);
  }

  return passed;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

(function main() {
  print(`\n${c.bold}Context Layer Validation${c.reset}  ${c.dim}${ROOT}${c.reset}\n\n`);

  const checks  = [checkManifest, checkStateFreshness, checkADRStatuses, checkSupportingFiles];
  const results = checks.map(fn => {
    try { return fn(); }
    catch (err) {
      return {
        label:    fn.name,
        failures: [{ file: "unknown", message: `Unexpected error: ${err.message}` }],
        warnings: [],
      };
    }
  });

  const allPassed     = results.map(report).every(Boolean);
  const totalFailures = results.reduce((n, r) => n + r.failures.length, 0);
  const totalWarnings = results.reduce((n, r) => n + r.warnings.length, 0);

  print("\n");

  if (allPassed) {
    print(`${c.green}${c.bold}  All checks passed${c.reset}`);
    if (totalWarnings) print(` ${c.yellow}(${totalWarnings} warning${totalWarnings === 1 ? "" : "s"})${c.reset}`);
  } else {
    print(`${c.red}${c.bold}  ${totalFailures} check${totalFailures === 1 ? "" : "s"} failed${c.reset}`);
    if (totalWarnings) print(`, ${c.yellow}${totalWarnings} warning${totalWarnings === 1 ? "" : "s"}${c.reset}`);
  }

  print("\n\n");
  exit(allPassed ? 0 : 1);
})();
