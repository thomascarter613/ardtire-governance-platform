#!/usr/bin/env node
/**
 * scripts/context/inject.mjs
 *
 * Assembles a context bundle from context/ and writes it to stdout
 * or a file, suitable for injection into an AI session.
 *
 * Usage:
 *   node scripts/context/inject.mjs                         # stdout (pipe to pbcopy, etc.)
 *   node scripts/context/inject.mjs --output .context.md    # write to file
 *   node scripts/context/inject.mjs --full                  # include architecture + conventions
 *   node scripts/context/inject.mjs --section architecture  # single named section
 *
 * Flags:
 *   --output   <path>     Write bundle to file instead of stdout
 *   --full                Include all context/ files (not just manifest + state)
 *   --section  <name>     Include a specific section: manifest | state | architecture | conventions
 *                         (repeatable; default: manifest + state)
 *   --no-header           Omit the generated-by header block
 *   --quiet               Suppress stderr progress messages
 *
 * Exit codes:
 *   0  Bundle generated successfully
 *   1  One or more source files were missing or unreadable
 *   2  Bad arguments
 */

import { execSync }                              from "node:child_process";
import { existsSync, mkdirSync,
         readFileSync, writeFileSync }           from "node:fs";
import { dirname, join, resolve }               from "node:path";
import { argv, cwd, env, exit,
         stderr, stdout }                       from "node:process";

// ─── Config ───────────────────────────────────────────────────────────────────

const ROOT        = cwd();
const CONTEXT_DIR = env.CONTEXT_DIR ?? "context";

const SECTIONS = {
  manifest:      `${CONTEXT_DIR}/manifest.md`,
  state:         `${CONTEXT_DIR}/state.md`,
  architecture:  `${CONTEXT_DIR}/architecture.md`,
  conventions:   `${CONTEXT_DIR}/conventions.md`,
};

const SECTION_LABELS = {
  manifest:     "PROJECT MANIFEST",
  state:        "CURRENT STATE",
  architecture: "ARCHITECTURE",
  conventions:  "CONVENTIONS",
};

// ─── Argument parsing ─────────────────────────────────────────────────────────

function parseArgs(rawArgs) {
  const args = {
    output:    null,       // string | null
    sections:  [],         // string[]
    full:      false,
    noHeader:  false,
    quiet:     false,
  };

  const positional = rawArgs.slice(2); // strip node + script path
  let i = 0;

  while (i < positional.length) {
    const tok = positional[i];
    switch (tok) {
      case "--output":
        args.output = positional[++i] ?? die("--output requires a path argument", 2);
        break;
      case "--section":
        args.sections.push(positional[++i] ?? die("--section requires a name argument", 2));
        break;
      case "--full":
        args.full = true;
        break;
      case "--no-header":
        args.noHeader = true;
        break;
      case "--quiet":
        args.quiet = true;
        break;
      default:
        die(`Unknown argument: ${tok}\nRun with --help for usage.`, 2);
    }
    i++;
  }

  // Resolve which sections to include
  if (args.full) {
    args.sections = Object.keys(SECTIONS);
  } else if (args.sections.length === 0) {
    args.sections = ["manifest", "state"];
  } else {
    for (const s of args.sections) {
      if (!SECTIONS[s]) {
        die(`Unknown section: "${s}". Valid: ${Object.keys(SECTIONS).join(", ")}`, 2);
      }
    }
  }

  return args;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function die(message, code = 1) {
  stderr.write(`\ncontext-inject error: ${message}\n\n`);
  exit(code);
}

function log(message, quiet) {
  if (!quiet) stderr.write(`  ${message}\n`);
}

function git(cmd) {
  try {
    return execSync(`git ${cmd}`, { cwd: ROOT, stdio: ["pipe","pipe","pipe"] })
             .toString().trim() || null;
  } catch { return null; }
}

function readSection(rel) {
  const abs = join(ROOT, rel);
  if (!existsSync(abs)) return null;
  return readFileSync(abs, "utf8");
}

function separator(label) {
  const bar = "─".repeat(72);
  return `\n${bar}\n## ${label}\n${bar}\n\n`;
}

// ─── Bundle builder ───────────────────────────────────────────────────────────

function buildBundle(args) {
  const chunks    = [];
  const missing   = [];

  // Header block
  if (!args.noHeader) {
    const sha      = git("rev-parse --short HEAD") ?? "untracked";
    const branch   = git("rev-parse --abbrev-ref HEAD") ?? "unknown";
    const now      = new Date().toISOString();
    const sections = args.sections.join(", ");

    chunks.push(
      `<!-- context-bundle\n` +
      `     generated : ${now}\n` +
      `     git        : ${branch} @ ${sha}\n` +
      `     sections   : ${sections}\n` +
      `     source     : context/\n` +
      `-->\n`
    );
  }

  // Section content
  for (const key of args.sections) {
    const rel     = SECTIONS[key];
    const label   = SECTION_LABELS[key];
    const content = readSection(rel);

    if (content === null) {
      missing.push(rel);
      chunks.push(separator(label));
      chunks.push(`> ⚠️  Source file not found: \`${rel}\`\n`);
      chunks.push(`> Run \`just context-scaffold\` to create it.\n`);
    } else {
      chunks.push(separator(label));
      chunks.push(content.trimEnd());
      chunks.push("\n");
    }
  }

  return { bundle: chunks.join(""), missing };
}

// ─── Output ───────────────────────────────────────────────────────────────────

function writeBundle(bundle, outputPath, quiet) {
  if (outputPath) {
    const abs = resolve(ROOT, outputPath);
    mkdirSync(dirname(abs), { recursive: true });
    writeFileSync(abs, bundle, "utf8");
    log(`Bundle written → ${outputPath}`, quiet);
  } else {
    stdout.write(bundle);
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

(function main() {
  const args = parseArgs(argv);

  log(`Building context bundle  [sections: ${args.sections.join(", ")}]`, args.quiet);

  const { bundle, missing } = buildBundle(args);

  writeBundle(bundle, args.output, args.quiet);

  if (missing.length > 0) {
    log(`\nWarning: ${missing.length} source file(s) not found:`, args.quiet);
    for (const f of missing) log(`  • ${f}`, args.quiet);
    log("Run: just context-scaffold", args.quiet);
    exit(1);
  }

  log("Done.", args.quiet);
  exit(0);
})();
