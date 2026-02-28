ACE-RAI / ACE-RAI-TUI Plan (Pi-inspired, Ruby-native) 🧭

This document defines a drop-in successor to your current one-shot ace-llm / ace-llm-providers, expanding it into a resume/continue capable agent runtime with a separate TUI frontend, closely modeled on pi-mono’s separation of concerns.

⸻

1) Reference Model: What “Pi Architecture” Actually Looks Like

pi-mono is a monorepo with distinct packages for:
	•	Unified multi-provider LLM API (@mariozechner/pi-ai)
	•	Agent runtime with tool calling + state machine (@mariozechner/pi-agent-core)
	•	Coding agent CLI (@mariozechner/pi-coding-agent)
	•	Terminal UI library (@mariozechner/pi-tui)  ￼

Key behaviors relevant to ACE-RAI:

1.1 Execution model

Pi’s agent core exposes prompt() and continue(); continue() resumes after tool results or queued messages and enforces continuation rules.  ￼

1.2 Modes

Pi CLI supports:
	•	Interactive (TUI)
	•	Print (one-shot or piped stdin)
	•	RPC (JSON-RPC over stdin/stdout)  ￼

1.3 Session persistence

Sessions are stored as append-only JSONL, with a tree structure (id/parentId) enabling branching.  ￼

1.4 Compaction (long sessions)

Pi tracks token usage and triggers automatic compaction (LLM summarization of older history) while preserving recent context, integrated with session persistence so resumed sessions compact when needed.  ￼

1.5 Tools + rendering

Interactive mode subscribes to agent events and renders tool/batch execution as dedicated UI components; it is explicitly a 3-tier architecture: AgentSession (business logic) ↔ InteractiveMode (presentation).  ￼

⸻

2) ACE-RAI Product Definition

2.1 Deliverables
	1.	ace-rai (headless core)
	•	Agent runtime (prompt/continue), tools, session format, compaction, provider abstraction.
	•	Designed to be invoked per message and to resume cleanly via session state.
	2.	ace-rai-tui (interactive frontend)
	•	Pi-like terminal UX, but strictly a wrapper around ace-rai.
	•	Zero business logic beyond UI state and user input routing.

Ruby gem naming: use dashes for extensions and map to require paths; “ace-rai-tui” as an extension style is consistent with RubyGems guidance.  ￼

⸻

3) Architectural Blueprint

3.1 Layering (Pi-style separation)

Goal: replicate Pi’s clean split: runtime vs UI.
	•	ace-rai-core (library)
	•	Agent (state machine: prompt/continue)
	•	ToolRegistry (built-ins + plugin hooks)
	•	ProviderRegistry (replacement for ace-llm-providers)
	•	SessionStore (JSONL tree)
	•	Compactor (summarize + preserve file/tool traces)
	•	ace-rai (CLI headless)
	•	Commands: print mode, rpc mode, utilities
	•	Config dir and session dir management
	•	ace-rai-tui (CLI interactive)
	•	Rendering + keybindings + panes
	•	Subscribes to agent events
	•	Reuses headless session store

This mirrors Pi’s “business logic separated from TUI” design.  ￼

⸻

4) Core Runtime Design (ace-rai)

4.1 Public API surface

Implement the Pi-like primitives:
	•	Agent#prompt(message, options)
	•	Agent#continue(options = {})

Pi’s semantics to copy (high value):
	•	disallow concurrent execution (isStreaming guard)
	•	continue() validates last message role; can resume after toolResult and process queued messages  ￼

4.2 State model

Use an immutable-ish state snapshot pattern similar to Pi’s state fields:
	•	system_prompt
	•	model + provider metadata
	•	thinking_level
	•	tools[]
	•	messages[] (user/assistant/tool_result)
	•	is_streaming, stream_message
	•	pending_tool_calls
	•	error  ￼

4.3 Event stream (critical for TUI + RPC)

Pi emits structured events like message_start, message_update, message_end, etc.  ￼
ACE-RAI should do the same, as a first-class interface:
	•	agent_start, agent_end
	•	turn_start, turn_end
	•	message_start, message_update, message_end
	•	tool_call_start, tool_call_update, tool_call_end
	•	compaction_start, compaction_end
	•	error

Output formats:
	•	JSON Lines (for print mode + TUI consumption)
	•	Text-only (optional convenience)

4.4 Tools

Start with Pi’s baseline tool list (good minimum):
	•	read, write, edit (find/replace)
	•	bash
	•	grep, find, ls  ￼

Tool protocol:
	•	deterministic tool_call_id
	•	execute(args, signal, on_update, ctx)
	•	tool result messages appended as toolResult (Pi naming) / tool_result (Ruby naming)

4.5 Sessions: JSONL tree format

Adopt Pi’s pattern:
	•	append-only JSONL
	•	id, parentId
	•	message/event line objects
	•	keep metadata (timestamp, model, usage, toolCalls)  ￼

Add ACE-RAI specifics:
	•	workspace_root
	•	git_head (optional)
	•	tool_policy_version
	•	provider_auth_profile

Branching model: identical to Pi: branch from any node by writing a new entry pointing to the chosen parent, without creating a new file.  ￼

4.6 Context management + compaction

Copy Pi’s system behavior, not necessarily implementation details:
	•	Maintain token accounting.
	•	Trigger compaction:
	•	overflow guard (hard limit)
	•	threshold/reserve tokens (soft limit)  ￼
	•	Compaction produces a summary entry and preserves recent messages.
	•	Persist compaction events in session file so resume continues safely.  ￼

Important Pi insight to copy: track file operations cumulatively across compactions/branch summaries (helps “what changed” continuity).  ￼

4.7 Provider abstraction (replacement for ace-llm-providers)

Pi maintains a model catalog / provider registry that normalizes provider differences and quirks.  ￼
ACE-RAI should implement a slimmer Ruby-native version:
	•	Provider interface:
	•	stream_chat(messages:, tools:, model:, thinking_level:, ...) -> event stream
	•	capability discovery (tool calling, vision, etc.)
	•	usage reporting (tokens, cost if available)
	•	ModelRegistry:
	•	local config file (ship defaults)
	•	override/merge behavior (custom models)
	•	pattern selection (like Pi’s model globbing/fuzzy patterns)  ￼

⸻

5) TUI Design (ace-rai-tui)

5.1 Non-negotiable rule

No business logic in TUI.
Pi explicitly keeps agent logic in AgentSession and uses InteractiveMode only for presentation/input routing.  ￼

5.2 UI responsibilities
	•	Render the conversation transcript
	•	Stream assistant output live (message_update)
	•	Render tool executions as expandable blocks (pending/success/error)
(Pi does this via dedicated components and event subscriptions).  ￼
	•	Provide:
	•	session picker / resume
	•	model switcher
	•	keybindings help
	•	status footer (context size, tokens, model)
	•	abort/cancel

5.3 Ruby libraries for TUI

Two viable approaches:

A) TTY toolkit stack (fastest to ship)
	•	tty-reader for keystroke + line editing/history  ￼
	•	tty-screen, tty-cursor, tty-prompt, etc.

B) Custom renderer
If you want Pi-like differential rendering, implement a minimal virtual tree + diff.
(But start with TTY unless differential rendering is a hard requirement.)

⸻

6) “What Should We Do Differently in Ruby?” (Leverage Ruby strengths)

6.1 Use Fibers for I/O concurrency (streaming, tool output, multiple requests)

Ruby’s Fiber Scheduler provides a standard interface for non-blocking I/O without rewriting code into callbacks; schedulers are typically provided by gems (e.g., Async).  ￼
Implications for ACE-RAI:
	•	implement provider streaming using Fiber scheduler (clean, Ruby-idiomatic)
	•	run tool processes with non-blocking reads (stream stdout/stderr into events)
	•	keep the agent loop single-threaded but highly concurrent for I/O

6.2 Use Ractors surgically (parallel CPU-bound tasks)

Ractors enable parallel execution without shared mutable state.  ￼
Use cases (optional):
	•	heavy diff/patch validation across many files
	•	indexing / embeddings preprocessing
	•	large log parsing
Keep it simple: message passing of immutable data blobs.

6.3 Use Ruby 4.0 features for safety + packaging

Ruby 4.0 introduces Ruby Box (isolation of definitions and monkey patches) and ZJIT.  ￼
Practical ACE-RAI opportunities:
	•	Plugin isolation: load untrusted extensions/skills inside a Box to avoid global monkey patches polluting the agent runtime (experimental; gate behind config).
	•	Performance: enable ZJIT in long-running TUI sessions (nice-to-have; LLM latency dominates overall time).

6.4 Ruby conventions: ship as composable gems
	•	ace-rai as core gem (headless runtime + CLI)
	•	ace-rai-tui as an extension gem (depends on core)
RubyGems naming guidance supports this pattern.  ￼

⸻

7) CLI Specification (match Pi where it matters)

Implement Pi-compatible ergonomics where beneficial:

7.1 Modes
	•	ace-rai (default) → interactive? (optional)
	•	ace-rai --print/-p → one-shot output (like Pi print mode)  ￼
	•	ace-rai --mode rpc → JSON-RPC over stdio (embedding)  ￼
	•	ace-rai-tui → explicit interactive mode (recommended)

7.2 Session flags (direct Pi analogs)
	•	-c/--continue (continue most recent session in cwd)  ￼
	•	-r/--resume (open session picker UI)  ￼
	•	--session <path|id-prefix>
	•	--session-dir <dir>
	•	--no-session (ephemeral)

7.3 Tool flags
	•	--tools read,bash,edit,write,...
	•	--no-tools

7.4 Config directory layout

Pi defaults to a global config/session dir (e.g., ~/.pi/agent/) and allows override via env var.  ￼
ACE-RAI should mirror:
	•	~/.ace/rai/ (suggested)
	•	env override ACE_RAI_DIR

⸻

8) Migration Plan from ace-llm / ace-llm-providers

Because internal GitHub repos weren’t selectable in this chat, this migration plan is based on the functional description you provided (one-shot wrappers).

8.1 Target end state
	•	ace-llm becomes either:
	•	deprecated, or
	•	a thin compatibility layer that calls ace-rai provider adapter.
	•	ace-llm-providers becomes:
	•	ace-rai/providers/* implementing the unified Provider interface.

8.2 Phased migration
	1.	Provider parity
	•	re-implement your existing providers behind Ace::RAI::Provider interface
	•	keep output stable
	2.	Introduce session + continue
	•	JSONL store
	•	continue() semantics
	•	event stream
	3.	Add tools
	•	start read/write/edit/bash
	•	tool events + persistence
	4.	Compaction
	•	token tracking
	•	manual + auto compaction
	•	persist compaction entries
	5.	TUI
	•	consume event stream
	•	implement tool execution panels
	•	add session picker

⸻

9) Implementation Milestones (Concrete)

Milestone 0 — Repo + packaging
	•	ace-rai gem skeleton + CLI entrypoint
	•	ace-rai-tui gem skeleton (depends on core)
	•	config dir conventions + basic settings file
	•	(Optional) ace-rai-dev scripts

Milestone 1 — Provider + streaming
	•	Provider interface
	•	at least one provider end-to-end streaming
	•	event stream contract locked

Milestone 2 — Agent loop (prompt/continue)
	•	Agent#prompt, Agent#continue
	•	guardrails (no concurrent streaming; continuation validity checks)  ￼

Milestone 3 — Session store
	•	JSONL append-only tree
	•	resume/continue resolution
	•	export

Milestone 4 — Tools + tool results
	•	tool registry + execution (with streamed stdout/stderr events)
	•	tool results appended to session and fed into continue()

Milestone 5 — Compaction
	•	token estimation + thresholds
	•	compaction entry persistence and replay on resume  ￼

Milestone 6 — TUI v1
	•	transcript + streaming text
	•	tool panels (expand/collapse)
	•	session picker + continue
	•	model switch + status footer

Milestone 7 — Hardening
	•	sandboxing policy hooks
	•	plugin system (skills/extensions)
	•	(Optional) Ruby Box isolation for plugins (experimental)  ￼

⸻

10) Key Design Decisions (Lock Early)
	1.	Event schema is the product.
Everything (TUI, RPC, print) depends on it.
	2.	Session format must be stable.
JSONL tree + compaction entries from day one.  ￼
	3.	Keep TUI dumb.
Mirror Pi’s tier split.  ￼
	4.	Ruby-first concurrency.
Prefer Fibers + scheduler for I/O; reserve Ractors for rare CPU hotspots.  ￼

⸻

11) Appendix: Why This Matches Your “Headless Resume” Requirement ✅

Your requirement: each message finishes a unit of work, and you can resume later with another message.

This is exactly what Pi’s design enables:
	•	prompt() starts a cycle
	•	tools run, results are appended
	•	continue() resumes deterministically from stored messages/tool results  ￼

ACE-RAI should adopt the same “conversation + tool results are the state” model.
