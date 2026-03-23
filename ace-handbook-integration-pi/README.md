<div align="center">
  <h1> ACE - Handbook Integration PI </h1>

  pi-agent provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-handbook-integration-pi"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-pi.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-handbook](../ace-handbook)
`ace-handbook-integration-pi` translates canonical ACE handbook skills into PI provider assets so that skill invocations from pi-agent resolve to the correct provider entrypoints while preserving shared semantics from [ace-handbook](../ace-handbook).

## Use Cases

**Consume canonical skills from PI tooling** - keep provider-specific behavior while preserving shared semantics, so agents running under pi-agent get the same skill intent as any other provider.

**Keep provider updates constrained** - update projection assets inside this package instead of canonical definitions, keeping changes isolated from [ace-handbook](../ace-handbook).

**Enable incremental provider onboarding** - add or update PI support independently of core ACE changes, maintaining a focused provider shim layer.

---
[ace-handbook](../ace-handbook) | Part of [ACE](https://github.com/cs3b/ace)
