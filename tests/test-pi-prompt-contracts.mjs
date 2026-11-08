import test from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { runInNewContext } from "node:vm";

const sourceDir = fileURLToPath(new URL("../home/dot_pi/private_agent/prompts/", import.meta.url));
const roles = { worker: "worker", review: "reviewer", scout: "scout", research: "researcher" };
const nameFor = (role) => `subagent-${role}-contract`;
const sourceFor = (role) => readFileSync(join(sourceDir, `${nameFor(role)}.md`), "utf8");

for (const [role, agent] of Object.entries(roles)) {
  test(`${role} contract has an explicit native role and a supported brief argument`, () => {
    const source = sourceFor(role);
    const frontmatter = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
    assert.ok(frontmatter, "prompt frontmatter is required");
    assert.match(frontmatter[1], new RegExp(`^subagent: ${agent}$`, "m"));
    assert.match(frontmatter[1], /^argument-hint: .*<assignment brief>/m);
    assert.match(source, /^\$1$/m);
    assert.doesNotMatch(source, /\{\{\w+\}\}/, "named fields have no installed renderer");
    assert.ok(source.includes("If no assignment was supplied, ask for it and do not start work."));
  });
}

// Integration uses existing installations only. A fresh dotfiles checkout must
// not download Pi or extensions just to validate source state.
const agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
const installRoot = process.env.PI_MANAGED_INSTALL_ROOT || join(agentDir, "install");
const versionFile = join(installRoot, "current-version");
const hostRoot = process.env.PI_TEST_HOST_ROOT || (existsSync(versionFile)
  ? join(installRoot, "releases", readFileSync(versionFile, "utf8").trim(), "node_modules", "@earendil-works", "pi-coding-agent")
  : "");
const nativeRoot = process.env.PI_TEST_SUBAGENTS_ROOT || join(agentDir, "npm", "node_modules", "pi-subagents");
const hostModule = hostRoot && join(hostRoot, "dist", "core", "prompt-templates.js");
const nativeModule = join(nativeRoot, "src", "slash", "prompt-workflows.js");
const normalizerModule = join(nativeRoot, "src", "extension", "public-execution.js");
const runtimeAvailable = hostModule && existsSync(hostModule) && existsSync(nativeModule) && existsSync(normalizerModule);
if (process.env.PI_TEST_HOST_ROOT || process.env.PI_TEST_SUBAGENTS_ROOT) {
  assert.ok(runtimeAvailable, "explicit Pi integration paths must resolve to an installed host and native adapter");
}

test("installed Pi and native adapter preserve briefs and select the intended roles", {
  skip: runtimeAvailable ? false : "Installed Pi/native adapter unavailable; source checks still run",
  timeout: 10000,
}, async () => {
  const host = await import(pathToFileURL(hostModule).href);
  const { registerPromptWorkflowCommands } = await import(pathToFileURL(nativeModule).href);
  const { normalizePublicSubagentExecution } = await import(pathToFileURL(normalizerModule).href);
  const fixture = mkdtempSync(join(tmpdir(), "pi-prompt-contracts-"));
  const fixtureAgent = join(fixture, "agent");
  const cwd = join(fixture, "project");
  const previousAgentDir = process.env.PI_CODING_AGENT_DIR;
  const brief = 'Goal: inspect the exact candidate.\nCheckout: /tmp/worktree with spaces. Scope: owner.ts. Authority: read only. Preserve literal $1, $ARGUMENTS and "quoted text".';
  const emptyGuard = "If no assignment was supplied, ask for it and do not start work.";
  try {
    mkdirSync(join(fixtureAgent, "prompts"), { recursive: true });
    mkdirSync(join(cwd, ".pi"), { recursive: true });
    for (const role of Object.keys(roles)) {
      writeFileSync(join(fixtureAgent, "prompts", `${nameFor(role)}.md`), sourceFor(role));
    }
    process.env.PI_CODING_AGENT_DIR = fixtureAgent;
    const { templates, diagnostics } = host.loadPromptTemplates({
      cwd, agentDir: fixtureAgent, promptPaths: [], includeDefaults: true,
    });
    assert.deepEqual(diagnostics, []);
    assert.equal(templates.length, Object.keys(roles).length);
    let command;
    let params;
    const notifications = [];
    registerPromptWorkflowCommands({
      pi: { registerCommand(name, definition) {
        assert.equal(name, "prompt-workflow");
        command = definition;
      } },
      run: async (value) => { params = value; },
    });
    const ctx = { cwd, ui: { notify: (...args) => notifications.push(args) } };
    for (const [role, agent] of Object.entries(roles)) {
      const name = nameFor(role);
      const expanded = host.expandPromptTemplate(`/${name} '${brief}'`, templates);
      assert.ok(expanded.includes(brief), `${name}: native expansion must preserve the exact brief`);
      assert.doesNotMatch(expanded, /\{\{\w+\}\}/);
      assert.ok(host.expandPromptTemplate(`/${name}`, templates).includes(emptyGuard));
      for (const assignment of [brief, ""]) {
        params = undefined;
        await command.handler(`${name} '${assignment}'`, ctx);
        assert.ok(params, `${name}: adapter must construct a workflow`);
        assert.equal(normalizePublicSubagentExecution(params).ok, true);
        const calls = [];
        const output = await runInNewContext(`(async () => { ${params.workflowScript} })()`, {
          runs: { run: async (key, child) => {
            calls.push({ key, child });
            return { output: "synthetic result; no child launched" };
          } },
        }, { timeout: 1000 });
        assert.equal(output, "synthetic result; no child launched");
        assert.equal(calls.length, 1);
        assert.equal(calls[0].child.agent, agent);
        if (assignment) assert.ok(calls[0].child.task.includes(assignment));
        else assert.ok(calls[0].child.task.includes(emptyGuard));
        assert.doesNotMatch(calls[0].child.task, /\{\{\w+\}\}/);
      }
    }
    assert.deepEqual(notifications, []);
  } finally {
    if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
    rmSync(fixture, { recursive: true, force: true });
  }
});
