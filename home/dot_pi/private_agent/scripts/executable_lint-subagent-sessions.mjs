#!/usr/bin/env node

import {
  createReadStream,
  lstatSync,
  readdirSync,
  realpathSync,
  statSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";

const DEFAULT_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;
const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const DEFAULT_SESSION_ROOT = resolve(SCRIPT_DIR, "..", "sessions");

const HELP = `Usage: node lint-subagent-sessions.mjs [options] [session-path ...]

Lint Pi subagent session JSONL files for workflow policy findings.

Options:
  --days N   Inspect files modified in the last N days (default: 7).
  --help     Show this help text.

Paths may be JSONL files or directories. Directories are searched recursively
for *.jsonl files. If no paths are given, ~/.pi/agent/sessions is searched.
Tool calls are deduplicated by their JSONL tool-call ID. Checks cover immediate
post-wait status calls, action:"mission", unexpected detached workflow results,
output-path collision errors, direct or foreground execution, spawn-budget grants,
worker hard budgets, and worker launches without an effective checked-or-stronger
acceptance or host gate. Checked acceptance must list changed-files, commands-run,
residual-risks, validation-output, and no-staged-files. A workflow-level checked
acceptance or host gate counts as the default for its child launches.
A status warning is reported only when the next detectable tool call after a
successful wait is a subagent status call. Dynamic worker agent variables are
not inferred. Exit 0 means clean, 1 means policy warnings, and 2 means usage,
file, or JSONL parse failure.`;

const warnings = [];
const warningKeys = new Set();
const seenCallIds = new Set();
const seenResultIds = new Set();
const callsById = new Map();
const parseErrors = [];

function usageError(message) {
  console.error(`error: ${message}`);
  console.error(HELP);
  process.exitCode = 2;
}

function parseArguments(argv) {
  const paths = [];
  let days = DEFAULT_DAYS;
  let endOptions = false;

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!endOptions && argument === "--") {
      endOptions = true;
      continue;
    }
    if (!endOptions && (argument === "--help" || argument === "-h")) {
      return { help: true };
    }
    if (!endOptions && argument === "--days") {
      index += 1;
      if (index >= argv.length)
        throw new Error("--days requires a positive integer");
      days = parseDays(argv[index]);
      continue;
    }
    if (!endOptions && argument.startsWith("--days=")) {
      days = parseDays(argument.slice("--days=".length));
      continue;
    }
    if (!endOptions && argument.startsWith("-")) {
      throw new Error(`unknown option: ${argument}`);
    }
    paths.push(resolve(argument));
  }

  return { days, paths };
}

function parseDays(value) {
  if (!/^\d+$/.test(value))
    throw new Error("--days requires a positive integer");
  const days = Number(value);
  if (!Number.isSafeInteger(days) || days < 1) {
    throw new Error("--days requires a positive integer");
  }
  return days;
}

function collectFiles(inputPaths) {
  const files = new Map();
  const pending = [...inputPaths];

  while (pending.length > 0) {
    const input = pending.pop();
    let stats;
    try {
      stats = lstatSync(input);
    } catch (error) {
      throw new Error(`${input}: ${error.message}`);
    }

    if (stats.isSymbolicLink()) {
      const target = realpathSync(input);
      pending.push(target);
      continue;
    }
    if (stats.isDirectory()) {
      for (const entry of readdirSync(input, { withFileTypes: true })) {
        pending.push(join(input, entry.name));
      }
      continue;
    }
    if (!stats.isFile()) continue;
    if (!input.endsWith(".jsonl")) continue;

    const canonical = realpathSync(input);
    if (!files.has(canonical)) files.set(canonical, statSync(canonical));
  }

  return [...files.entries()].sort(([left], [right]) =>
    left.localeCompare(right),
  );
}

function contentItems(message) {
  const content = message?.content;
  if (Array.isArray(content)) return content;
  if (content && typeof content === "object") return [content];
  return [];
}

function textFromContent(content) {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) return content.map(textFromContent).join("");
  if (!content || typeof content !== "object") return "";
  if (typeof content.text === "string") return content.text;
  if (content.content) return textFromContent(content.content);
  return "";
}

function decodeArguments(value) {
  if (!value) return {};
  if (typeof value === "object") return value;
  if (typeof value !== "string") return {};
  try {
    const decoded = JSON.parse(value);
    return decoded && typeof decoded === "object" ? decoded : {};
  } catch {
    return {};
  }
}

function extractToolCalls(message) {
  const calls = [];
  for (const item of contentItems(message)) {
    if (!item || typeof item !== "object") continue;
    if (item.type !== "toolCall" && item.type !== "tool_call") continue;
    calls.push({
      id: item.id,
      name: item.name ?? item.toolName,
      arguments: decodeArguments(item.arguments ?? item.input),
    });
  }
  return calls;
}

function addWarning(kind, key, path, line, message) {
  const warningKey = `${kind}:${key}`;
  if (warningKeys.has(warningKey)) return;
  warningKeys.add(warningKey);
  warnings.push({ kind, path, line, message });
}

const REQUIRED_WORKER_EVIDENCE = [
  "changed-files",
  "commands-run",
  "residual-risks",
  "validation-output",
  "no-staged-files",
];

function hasRequiredWorkerEvidence(evidence) {
  return (
    Array.isArray(evidence) &&
    REQUIRED_WORKER_EVIDENCE.every((kind) => evidence.includes(kind))
  );
}

function isCheckedOrStrongerAcceptance(acceptance) {
  return Boolean(
    acceptance &&
    typeof acceptance === "object" &&
    (acceptance.level === "checked" || acceptance.level === "verified") &&
    hasRequiredWorkerEvidence(acceptance.evidence),
  );
}

function objectSpanAround(text, propertyIndex) {
  const openBraces = [];
  let quote = null;
  let escaped = false;
  for (let index = 0; index < propertyIndex; index += 1) {
    const character = text[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }
    if (character === "'" || character === '"' || character === "`") {
      quote = character;
      continue;
    }
    if (character === "{") openBraces.push(index);
    if (character === "}") openBraces.pop();
  }

  const start = openBraces.at(-1);
  if (start === undefined) return "";

  let depth = 0;
  quote = null;
  escaped = false;
  for (let index = start; index < text.length; index += 1) {
    const character = text[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }
    if (character === "'" || character === '"' || character === "`") {
      quote = character;
      continue;
    }
    if (character === "{") depth += 1;
    if (character === "}") {
      depth -= 1;
      if (depth === 0) return text.slice(start, index + 1);
    }
  }
  return text.slice(start);
}

function workflowWorkerLaunches(workflowScript) {
  const launches = [];
  const workerPattern = /\bagent\s*:\s*(['"])worker\1/g;
  let match;
  while ((match = workerPattern.exec(workflowScript)) !== null) {
    const objectText = objectSpanAround(workflowScript, match.index);
    const hasCheckedOrStrongerLevel =
      /\bacceptance\s*:\s*\{[\s\S]*?\blevel\s*:\s*(['"])(?:checked|verified)\1/.test(
        objectText,
      );
    const evidenceMatch = /\bevidence\s*:\s*\[([\s\S]*?)\]/.exec(objectText);
    const evidence = evidenceMatch
      ? [...evidenceMatch[1].matchAll(/(['"])(.*?)\1/g)].map((item) => item[2])
      : [];
    launches.push({
      checked:
        /\bgate\s*:/.test(objectText) ||
        (hasCheckedOrStrongerLevel && hasRequiredWorkerEvidence(evidence)),
      hardBudget: /\b(?:turnBudget|toolBudget)\s*:/.test(objectText),
    });
  }
  return launches;
}

function inspectWorkerLaunch(record) {
  if (record.name !== "subagent") return;
  const args = record.arguments;
  if (args.agent === "worker") {
    if (!args.gate && !isCheckedOrStrongerAcceptance(args.acceptance)) {
      addWarning(
        "worker-acceptance",
        record.id,
        record.path,
        record.line,
        'worker launch has no host gate or checked-or-stronger acceptance; add gate or acceptance.level="checked" or "verified" with the required evidence fields',
      );
    }
    if (args.turnBudget || args.toolBudget) {
      addWarning(
        "worker-hard-budget",
        record.id,
        record.path,
        record.line,
        "mutation-capable worker has a hard turn/tool budget; rely on scoped work and runtime timeouts so it can return a complete checkpoint",
      );
    }
  }
  if (typeof args.workflowScript !== "string") return;
  const workflowAcceptance =
    Boolean(args.gate) || isCheckedOrStrongerAcceptance(args.acceptance);
  workflowWorkerLaunches(args.workflowScript).forEach((launch, index) => {
    if (!launch.checked && !workflowAcceptance) {
      addWarning(
        "worker-acceptance",
        `${record.id}:${index}`,
        record.path,
        record.line,
        'workflow worker launch has no host gate or checked-or-stronger acceptance; pass gate or acceptance.level="checked" or "verified" in the child launch',
      );
    }
    if (launch.hardBudget) {
      addWarning(
        "worker-hard-budget",
        `${record.id}:${index}`,
        record.path,
        record.line,
        "workflow worker has a hard turn/tool budget; rely on scoped work and runtime timeouts so it can return a complete checkpoint",
      );
    }
  });
}

function inspectCall(record) {
  if (record.name !== "subagent") return;
  const args = record.arguments;
  if (!args.action) {
    if (typeof args.workflowScript !== "string") {
      addWarning(
        "direct-execution",
        record.id,
        record.path,
        record.line,
        "subagent execution bypasses workflowScript; use one stable-key workflow even for a single child",
      );
    }
    if (args.async === false) {
      addWarning(
        "foreground-execution",
        record.id,
        record.path,
        record.line,
        "foreground subagent execution blocks the parent; launch async unless the parent itself must block",
      );
    }
  }
  if (args.action === "grant-spawn-budget") {
    addWarning(
      "spawn-budget-grant",
      record.id,
      record.path,
      record.line,
      "spawn-budget grant required user confirmation; prefer decomposition or a fresh session, and grant capacity only when the user approves it",
    );
  }
  if (args.action === "mission") {
    addWarning(
      "unsupported-mission-action",
      record.id,
      record.path,
      record.line,
      'unsupported action "mission"; use a supported mission.* action such as mission.close',
    );
  }
  inspectWorkerLaunch(record);
}

function isSuccessfulWait(result) {
  if (result.isError === true) return false;
  if (
    result.details &&
    Array.isArray(result.details.completions) &&
    result.details.completions.length > 0
  ) {
    return true;
  }
  return /\boutcome:\s*[1-9]\d*\s+(?:complete|completed)\b/i.test(
    result.text,
  );
}

function isDetachedWorkflowResult(result, call) {
  if (!call || call.name !== "subagent") return false;
  if (typeof call.arguments.workflowScript !== "string") return false;
  const details = result.details;
  const expectedOuterAsyncLaunch = Boolean(
    call.arguments.async !== false &&
      details?.asyncId &&
      Array.isArray(details.results) &&
      details.results.length === 0,
  );
  if (expectedOuterAsyncLaunch) return false;
  return (
    /\bdetached\b/i.test(result.text) &&
    /\b(?:async|workflow|child)\b/i.test(result.text)
  );
}

function isOutputCollision(result, call) {
  const isSubagentResult =
    call?.name === "subagent" || result.toolName === "subagent";
  if (!isSubagentResult || result.isError !== true) return false;

  return (
    /output(?:\s+path)?[^\n]{0,120}(?:collision|collid|already\s+exists|in\s+use|occupied)/i.test(
      result.text,
    ) ||
    /(?:collision|collid)[^\n]{0,120}output(?:\s+path)?/i.test(result.text) ||
    /EEXIST[^\n]{0,120}output/i.test(result.text)
  );
}

async function scanFile(path, cutoff) {
  const stats = statSync(path);
  if (stats.mtimeMs < cutoff) return false;

  const events = [];
  const callsInFileById = new Map();
  const input = createReadStream(path, { encoding: "utf8" });
  const reader = createInterface({ input, crlfDelay: Infinity });
  let line = 0;
  try {
    for await (const sourceLine of reader) {
      line += 1;
      if (!sourceLine.trim()) continue;
      let event;
      try {
        event = JSON.parse(sourceLine);
      } catch (error) {
        parseErrors.push(`${path}:${line}: ${error.message}`);
        continue;
      }
      if (!event || event.type !== "message") continue;
      const message = event.message ?? event;
      if (!message || typeof message !== "object") continue;

      for (const toolCall of extractToolCalls(message)) {
        const id = toolCall.id ?? `${path}:${line}:${events.length}`;
        const record = {
          id,
          name: toolCall.name,
          arguments: toolCall.arguments,
          path,
          line,
        };
        callsInFileById.set(id, record);
        events.push({ type: "call", record });
        if (seenCallIds.has(id)) continue;
        seenCallIds.add(id);
        callsById.set(id, record);
        inspectCall(record);
      }

      if (message.role !== "toolResult") continue;
      const toolCallId = message.toolCallId;
      const resultId = toolCallId ?? `${path}:${line}`;
      const result = {
        id: resultId,
        toolCallId,
        toolName: message.toolName,
        text: textFromContent(message.content),
        details: message.details,
        isError: message.isError === true,
        path,
        line,
      };
      events.push({ type: "result", result });
      if (seenResultIds.has(resultId)) continue;
      seenResultIds.add(resultId);
      resultRecords.push(result);
    }
  } catch (error) {
    parseErrors.push(`${path}: ${error.message}`);
  } finally {
    reader.close();
  }

  for (let index = 0; index < events.length; index += 1) {
    const event = events[index];
    if (event.type !== "result") continue;
    const result = event.result;
    const call = result.toolCallId
      ? (callsInFileById.get(result.toolCallId) ??
        callsById.get(result.toolCallId))
      : undefined;
    if (call?.name === "subagent_wait" && isSuccessfulWait(result)) {
      for (let next = index + 1; next < events.length; next += 1) {
        if (events[next].type !== "call") continue;
        const nextCall = events[next].record;
        if (
          nextCall.name === "subagent" &&
          nextCall.arguments.action === "status"
        ) {
          addWarning(
            "status-after-wait",
            call.id,
            nextCall.path,
            nextCall.line,
            "subagent status immediately follows a successful wait; do not status-poll merely to observe progress",
          );
        }
        break;
      }
    }
  }
  return true;
}

function inspectResults() {
  for (const result of resultRecords) {
    const call = result.toolCallId
      ? callsById.get(result.toolCallId)
      : undefined;
    if (isDetachedWorkflowResult(result, call)) {
      addWarning(
        "detached-workflow",
        result.toolCallId ?? result.id,
        result.path,
        result.line,
        "workflow result returned a detached child notice; await stable-key child results inside the workflow",
      );
    }
    if (isOutputCollision(result, call)) {
      addWarning(
        "output-collision",
        result.toolCallId ?? result.id,
        result.path,
        result.line,
        "output-path collision error; preflight a unique per-run output path before retrying",
      );
    }
  }
}

const resultRecords = [];

async function main() {
  let options;
  try {
    options = parseArguments(process.argv.slice(2));
  } catch (error) {
    usageError(error.message);
    return;
  }
  if (options.help) {
    console.log(HELP);
    return;
  }

  const inputPaths =
    options.paths.length > 0 ? options.paths : [DEFAULT_SESSION_ROOT];
  let files;
  try {
    files = collectFiles(inputPaths);
  } catch (error) {
    usageError(error.message);
    return;
  }

  const cutoff = Date.now() - options.days * DAY_MS;
  let scanned = 0;
  for (const [path] of files) {
    const wasScanned = await scanFile(path, cutoff);
    if (wasScanned) scanned += 1;
  }

  // Inspect results after every file has contributed its call records. This
  // lets a workflow result resolve a call inherited from another session file.
  inspectResults();

  warnings.sort((left, right) => {
    const pathOrder = left.path.localeCompare(right.path);
    return (
      pathOrder ||
      left.line - right.line ||
      left.message.localeCompare(right.message)
    );
  });

  for (const parseError of parseErrors)
    console.error(`parse error: ${parseError}`);
  for (const warning of warnings) {
    console.error(
      `${warning.path}:${warning.line}: warning: ${warning.message}`,
    );
  }

  if (parseErrors.length > 0) {
    console.error(
      `Session lint failed to parse ${parseErrors.length} JSONL line(s).`,
    );
    process.exitCode = 2;
    return;
  }
  if (warnings.length > 0) {
    console.error(
      `Session policy lint found ${warnings.length} warning(s) in ${scanned} file(s).`,
    );
    process.exitCode = 1;
    return;
  }
  console.log(`Session policy lint clean: ${scanned} file(s) scanned.`);
}

main().catch((error) => {
  console.error(`error: ${error.message}`);
  process.exitCode = 2;
});
