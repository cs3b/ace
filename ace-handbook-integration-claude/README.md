<div align="center">
  <h1> ACE - Handbook Integration Claude </h1>

  Claude Code provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-handbook-integration-claude"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-claude.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-handbook](../ace-handbook)
`ace-handbook-integration-claude` projects canonical ACE handbook skills into Claude-native runtime assets so that `/as-*` skills invoked from Claude Code resolve to the correct provider-specific entrypoints while preserving shared semantics defined in [ace-handbook](../ace-handbook).

## Use Cases

**Run ACE workflows from Claude Code** - load canonical skill semantics with Claude-specific packaging so that skills like `/as-task-work` and `/as-git-commit` work natively in Claude Code sessions.

**Keep provider integration changes isolated** - update Claude-specific manifests and projections inside this package without altering canonical handbook definitions managed by [ace-handbook](../ace-handbook).

**Standardize cross-provider behavior** - preserve shared conventions while adapting to Claude Code's command surface, ensuring the same skill intent works across all supported providers.

---

Part of [ACE](https://github.com/cs3b/ace)
