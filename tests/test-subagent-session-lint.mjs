import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, rmSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const script = fileURLToPath(new URL("../home/dot_pi/private_agent/scripts/executable_lint-subagent-sessions.mjs", import.meta.url));
const evidence = ["changed-files", "commands-run", "residual-risks", "validation-output", "no-staged-files"];
const acceptance = { level: "checked", evidence, review: { required: false } };
const call = (id, args, name = "subagent") => ({ type: "message", message: { role: "assistant", content: [{ type: "toolCall", id, name, arguments: args }] } });
const result = (id, text, extra = {}) => ({ type: "message", message: { role: "toolResult", toolCallId: id, toolName: "subagent", content: [{ type: "text", text }], ...extra } });
function lint(events, { duplicate = false, malformed = false } = {}) {
  const dir = mkdtempSync(join(tmpdir(), "subagent-lint-test-"));
  try {
    const text = events.map(e => JSON.stringify(e)).join("\n") + (malformed ? "\n{broken" : "\n");
    writeFileSync(join(dir, "session.jsonl"), text);
    if (duplicate) writeFileSync(join(dir, "fork.jsonl"), text);
    const run = spawnSync(process.execPath, [script, dir], { encoding: "utf8", timeout: 10000 });
    assert.ifError(run.error);
    return { status: run.status, output: run.stdout + run.stderr };
  } finally { rmSync(dir, { recursive: true, force: true }); }
}

test("direct read-only and intentional foreground calls are valid", () => {
  const run = lint([call("scout", { agent: "scout", task: "Find owner", async: false })]);
  assert.equal(run.status, 0, run.output);
});

test("direct worker recognizes current options acceptance", () => {
  const run = lint([call("worker", { agent: "worker", options: { acceptance } })]);
  assert.equal(run.status, 0, run.output);
});

test("worker requires explicit evidence rather than inferred success", () => {
  const run = lint([call("worker", { agent: "worker" })]);
  assert.equal(run.status, 1);
  assert.match(run.output, /worker-acceptance: 1/);
  assert.doesNotMatch(run.output, /direct-execution|foreground-execution/);
});

test("hard worker budgets are detected inside options", () => {
  const run = lint([call("worker", { agent: "worker", options: { acceptance, toolBudget: { maxCalls: 3 } } })]);
  assert.equal(run.status, 1);
  assert.match(run.output, /worker-hard-budget: 1/);
});

test("removed workflow parameters are diagnosed", () => {
  const run = lint([call("old", { workflowScript: "return 1" })]);
  assert.equal(run.status, 1);
  assert.match(run.output, /obsolete-workflow-parameter: 1/);
});

test("current inline workflow worker contract is recognized", () => {
  const script = `return runs.run('fix', { agent: 'worker', acceptance: { level: 'checked', evidence: ${JSON.stringify(evidence)} } });`;
  const run = lint([call("workflow", { workflow: true, options: { script } })]);
  assert.equal(run.status, 0, run.output);
});

test("inline workflow workers without evidence are diagnosed", () => {
  const run = lint([call("workflow", { workflow: true, options: { script: "return runs.run('fix', { agent: 'worker' });" } })]);
  assert.equal(run.status, 1);
  assert.match(run.output, /worker-acceptance: 1/);
});

test("file-backed workflows are not guessed from unrelated text", () => {
  assert.equal(lint([call("workflow", { workflow: "./workflow.js" })]).status, 0);
});

test("current bg_wait followed immediately by status is diagnosed", () => {
  const run = lint([
    call("wait", {}, "bg_wait"),
    result("wait", "Finished", { toolName: "bg_wait", details: { completions: [{ id: "child" }] } }),
    call("status", { action: "status" }),
  ]);
  assert.equal(run.status, 1);
  assert.match(run.output, /status-after-wait: 1/);
});

test("failed child results contribute bounded diagnostic counts", () => {
  const run = lint([
    call("child", { agent: "scout" }),
    result("child", "Failed to load provider. Tool bash timed out. Acceptance failed: missing evidence.", { isError: true }),
  ]);
  assert.equal(run.status, 1);
  for (const kind of ["child-setup-failure", "tool-timeout", "acceptance-failure"]) assert.match(run.output, new RegExp(`${kind}: 1`));
});

test("successful output is not classified as a failure", () => {
  assert.equal(lint([call("child", { agent: "scout" }), result("child", "Fixed tool timeout and missing evidence")]).status, 0);
});

test("forked call and result records are counted once", () => {
  const run = lint([call("child", { agent: "scout" }), result("child", "tool bash timed out", { isError: true })], { duplicate: true });
  assert.equal(run.status, 1);
  assert.match(run.output, /tool-timeout: 1/);
  assert.match(run.output, /found 1 warning/);
});

test("malformed JSONL remains an error, not clean evidence", () => {
  const run = lint([], { malformed: true });
  assert.equal(run.status, 2);
  assert.match(run.output, /parse error/);
});

test("baseline uses manual resume and checkpointing without blanket tool limits", () => {
  const config = JSON.parse(readFileSync(new URL("../home/dot_pi/private_agent/extensions/subagent/config.json", import.meta.url)));
  assert.equal(config.autoResume, false);
  assert.equal(config.checkpointBeforeDeadlineMs, 600000);
  assert.equal(Object.hasOwn(config, "toolTimeoutMs"), false);
  assert.equal(config.globalConcurrencyLimit, 4);
  assert.equal(config.maxActiveAsyncRunsPerSession, 3);
});
