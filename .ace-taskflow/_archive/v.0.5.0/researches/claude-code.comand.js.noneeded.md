Short answer (TL;DR)
No — you don’t create .claude/commands/commands.json. Each custom slash command is its own Markdown file (e.g. .claude/commands/my-command.md) and any metadata you need lives in a short YAML “front-matter” block at the top of that file. ￼

⸻

1  Where commands live

Scope	Location	Notes
Project-level	.claude/commands/ inside the repo	Checked in, shared with the team  ￼
User-level	~/.claude/commands/	Follows you across projects  ￼
Namespacing	Sub-folders under either path (e.g. .claude/commands/devops/deploy.md) automatically turn into commands like /devops:deploy  ￼

There is no JSON index file in these folders; Claude at start-up simply scans for *.md files to register the commands. ￼

⸻

2  How to define a command

A command file is pure Markdown with an optional YAML block at the top. Allowed keys include:
	•	allowed-tools – restrict tool usage
	•	argument-hint – autocompletion hint
	•	description – short help text
	•	model – force Sonnet/Opus/Haiku, etc. ￼

---
description: Create a conventional-commit from staged changes
allowed-tools: Bash(git diff:*), Bash(git commit:*)
argument-hint: "[commit-message]"
model: sonnet
---

## Context
- Diff: !`git diff --staged`

## Task
Write a concise **conventional commit** using the diff above.

Everything after the closing --- is the prompt that will be fed to Claude when you run /create-commit. ￼

⸻

3  Where JSON is used (and why it’s different)
	•	Settings & policies live in several *.json files (~/.claude/settings.json,  .claude/settings.json, enterprise-wide managed-settings.json) that control permissions, env-vars, default model, etc. ￼
	•	MCP server definitions (to add external tools) often sit in ~/.claude.json or .claude/settings*.json. ￼
	•	Custom slash commands, sub-agents, and memory all stay in Markdown — they never rely on a central commands.json.

Mixing the two lets you keep behaviour in JSON and prompts in Markdown, following Anthropic’s recommended separation of concerns. ￼

⸻

4  Handy extras
	•	Community sites such as claudecode.io maintain ready-made command libraries you can drop straight into .claude/commands/. ￼
	•	GitHub’s awesome-claude-code list is a treasure-trove of examples. ￼
	•	ClaudeLog and DotClaude host configuration templates if you want boiler-plate YAML front-matter snippets. ￼ ￼
	•	Recent releases added a Connectors directory (Google Drive, Slack, Canva, etc.), but that is configured through MCP JSON, not slash-command files. ￼

⸻

5  Recommended workflow
	1.	Create the folder (if it doesn’t exist):

mkdir -p .claude/commands


	2.	Add a new Markdown file with YAML front-matter as shown above.
	3.	Restart or /reload Claude Code (or just invoke /help) to see your new command appear.
	4.	Version-control project commands; keep personal ones in ~/.claude/commands/.
