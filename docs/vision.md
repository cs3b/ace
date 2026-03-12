---
update:
  update_frequency: on-change
  last-updated: '2026-01-17'
  max_lines: 120
  required_sections:
  - why-ace-exists
  - core-principles
---

# ACE Vision

> Developers and AI agents now work side by side. But our tools weren't built for this - GUIs, IDEs, scattered APIs make it hard for agents to work alongside us, or sandboxed.
>
> ACE bridges this gap with CLI tools designed for developers - and useful for agents, because LLMs learned from human work.

---

## Why ACE Exists

Agents can run CLI commands and read files, but they struggle with:

- **Context bloat** from verbose tools (test runners, linters) and full API responses
- **No isolation boundary** - working in sandboxed environments without writing to external APIs
- **Prompt fragility** - copy-pasting skills from the internet; no versioning, no governance
- **Lost flow** - switching between agent-assisted and manual work

ACE applies Unix philosophy to solve these: files as interchange (not just APIs), tools that do one thing well, composable workflows. Plus a distribution model to share them.

---

## Core Principles

### 1. 🖥️ CLI-First, Agent-Agnostic

Any agent that can run CLI commands and access the filesystem can use ACE. Works with Claude Code, Codex CLI, OpenCode, Antigravity, Gemini CLI - if it can run bash, it can use ACE.

### 2. 🔍 Transparent & Inspectable

You can see what happened. Review sessions save LLM responses to files. Commands support dry-run. Configs are readable YAML. When something breaks, you can trace it.

### 3. 🤝 Same Tools, Same Experience

No separate "agent API." Every ACE tool is a standard CLI command. Developers and agents use the same binary, same configuration, same output. If it's awkward for developers, it will be worse for agents - so we optimize for both.

### 4. 📦 Packaged and Customizable

Each package is a complete bundle: CLI tool, defaults, workflows, and docs - install and it works. Override at any level - user preferences, project standards, or nested packages. Any workflow, any prompt can be swapped - no forking required.

### 5. 🔌 Provider Freedom

LLM providers and agents are abstracted away. Switch between APIs (Anthropic, OpenAI, Google) or delegate to CLI agents (Claude Code, Codex CLI, Gemini CLI). Use the best tool for each task without changing your workflow.

---

## How It Works

**Example: `ace-git-commit`**

```
ace-git-commit -i "fix auth bug"
```

Analyzes the diff. Considers your intention. Applies formatting rules. Under one second. Same command for developers and agents.

📦 **Package ships with defaults** ([ace-git-commit/](../ace-git-commit/)):

```
ace-git-commit/
├── .ace-defaults/git/commit.yml      # model config
├── handbook/prompts/
│   └── git-commit.system.md          # commit style
├── handbook/workflow-instructions/
│   └── commit.wf.md                  # workflow
└── exe/ace-git-commit                # CLI
```

👤 **Override at user level** (`~/.ace/`):

```
~/.ace/
└── git/commit.yml                    # user preferred model (e.g. openai:mini)
```

📁 **Override at project level** (`.ace/`, committed to repo):

```
.ace/
├── handbook/prompts/
│   └── git-commit.system.md          # project commit style
```

🤖 **Agent integration** - canonical skills are authored once, then projected into provider-native folders:

- Canonical source lives in package `handbook/skills/`
- Provider packages generate `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`, `.opencode/skills/`, and `.pi/skills/`
- Provider-specific frontmatter overrides live inside the canonical skill under `integration.providers.<provider>`

This is the simplest ACE tool. The pattern scales to code review, task management, and documentation workflows.

---

*ACE: CLI tools designed for developers - ready for agents too.*
