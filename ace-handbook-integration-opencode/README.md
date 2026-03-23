<div align="center">
  <h1> ACE - Handbook Integration OpenCode </h1>

  OpenCode provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-handbook-integration-opencode"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-opencode.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-handbook](../ace-handbook)
`ace-handbook-integration-opencode` provides OpenCode-focused handbook manifests and projection artifacts so that canonical ACE skills invoked from OpenCode resolve to the correct provider entrypoints while preserving shared semantics from [ace-handbook](../ace-handbook).

## Use Cases

**Run ACE workflows from OpenCode integrations** - keep canonical skill intent while targeting OpenCode entrypoints, so agents running under OpenCode get the same behavior as any other provider.

**Adapt quickly to provider-specific layouts** - update projection assets inside this package instead of rewriting handbook logic, keeping changes isolated from [ace-handbook](../ace-handbook) canonical definitions.

**Keep provider layers small** - isolate integration glue from core handbook behavior with a focused set of manifests and projection assets.

---
[ace-handbook](../ace-handbook) | Part of [ACE](https://github.com/cs3b/ace)
