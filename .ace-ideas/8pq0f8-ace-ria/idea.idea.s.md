---
title: Create ace-ria as LLM Provider Replacement and Agent Runtime
filename_suggestion: feat-llm-ria-runtime
enhanced_at: 2026-02-27 00:16:56.000000000 +00:00
location: active
llm_model: pi:glm
id: 8pq0f8
status: pending
tags: []
created_at: '2026-02-27 00:16:54'
---

# Create ace-ria as LLM Provider Replacement and Agent Runtime

## What I Hope to Accomplish

Replace ace-llm with ace-ria (Runner Interface for Agents) that provides dual functionality: (1) maintain the existing CLI-based LLM provider abstraction that ace-llm offers, enabling developers and agents to invoke models through `ace-ria chat|complete` commands with deterministic output; (2) extend to become a full agent runtime where ace-ria itself hosts and executes agents defined as `.ag.md` files, eliminating the need for external agent wrappers. This consolidates LLM provider management and agent execution into a single cohesive system following ACE's CLI-first, agent-agnostic principles, and providing ACP (Agent Control Protocol) support so other systems can orchestrate agents through ace-ria.

## What "Complete" Looks Like

- **ace-ria gem** with ATOM architecture (atoms: model_resolution, prompt_builder, response_parser; molecules: provider_manager, agent_loader, executor; organisms: chat_command, complete_command, agent_runner) replacing ace-llm functionality
- **CLI interface**: `ace-ria chat -p provider -m model` and `ace-ria complete -p provider -m model` with deterministic, parseable JSON/text output for both interactive and programmatic use
- **Agent runtime**: `ace-ria run agent.ag.md --input json` that loads `.ag.md` files with frontmatter-defined capabilities and executes them using configured LLM providers
- **ACP support**: Standardized interface for external systems to invoke agents via ace-ria, with JSON-RPC or simple CLI protocol for agent discovery, execution, and result retrieval
- **Provider compatibility**: All existing ace-llm providers (Anthropic, OpenAI, Google, CLI-based providers like Claude Code, Codex CLI, Gemini CLI) work through ace-ria with zero breaking changes to consuming gems (ace-git-commit, ace-review, ace-prompt-prep)
- **Handbook integration**: `handbook/agents/*.ag.md` for agent definitions with frontmatter (capabilities, input_schema, output_schema) that ace-ria can discover and execute
- **Configuration cascade**: `.ace-defaults/ria/config.yml` for provider defaults, user/project overrides via `~/.ace/ria/` and `.ace/ria/`, following ADR-022
- **Migration path**: ace-llm deprecated but shim-able; consuming gems updated to use Ace::RIA instead of Ace::LLM; clear upgrade documentation

## Success Criteria

- `ace-ria chat` and `ace-ria complete` commands produce identical output to ace-llm equivalents for all providers
- ace-ria can load and execute any `.ag.md` agent from handbook/ directories with correct input validation and output formatting
- External systems can list available agents via `ace-ria agents list` and invoke them via `ace-ria agents run <name> --input json`
- All existing ace-llm consumers (ace-git-commit, ace-review, etc.) work with zero code changes after updating dependency to ace-ria
- ace-ria handbook includes agent development guide (.ag.md frontmatter patterns) and ACP integration documentation
- Test coverage ≥ 80% for all atoms/molecules/organisms; E2E tests cover provider compatibility and agent execution
- Configuration cascade (gem defaults > user > project > CLI) works correctly for all provider and agent settings

---

## Original Idea

```
create ace-ria as replacement for ace-llm (with cmd line and acp support for other agents, but also be the agents itself
```