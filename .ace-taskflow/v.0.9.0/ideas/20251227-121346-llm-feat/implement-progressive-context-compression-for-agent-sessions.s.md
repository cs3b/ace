---
title: Progressive Context Compression for Agent Sessions using LLMs
filename_suggestion: feat-llm-progressive-compression
enhanced_at: 2025-12-27 12:13:44
location: active
llm_model: gflash
---

# Progressive Context Compression for Agent Sessions using LLMs

## Problem
Long-running agent workflows, especially those involving complex operations managed by `ace-taskflow` or detailed code analysis via `ace-review`, generate extensive raw context (prompts, tool outputs, code diffs from `ace-git`). Repeatedly feeding this entire history into the LLM for subsequent steps is highly inefficient, costly, and quickly exhausts context windows, leading to degraded performance and loss of state awareness.

## Solution
Implement a progressive, context-aware compression mechanism. After every significant agent action (message, tool call, or code modification), a specialized LLM (via `ace-llm`) compresses the *new* event based on the *existing compressed history*. This creates a highly dense, structured log of the session state. The compressed log serves as the primary context for future steps, supplemented only by the most recent raw data.

## Implementation Approach
This feature requires integration across several existing ACE gems, potentially introducing a new `ace-session` gem or extending `ace-prompt` and `ace-taskflow`.

1. **Compression Molecule:** A new Molecule, perhaps `Ace::Session::Molecules::ContextCompressor`, will be responsible for orchestrating the LLM call. It will take the current raw input and the existing compressed log as input.
2. **LLM Integration (`ace-llm`):** Use a dedicated, high-throughput model (as suggested, potentially a local OSS model integrated via `ace-llm-providers-cli`) optimized for structured summarization and compression.
3. **Structured Output:** The compression LLM must adhere to a strict output format for the compressed entry, including fields like `Summary (1 line)`, `Repo Impact (1 line)`, and `Next Action/State Change`. This ensures deterministic parsing.
4. **Caching:** The compressed history will be stored using the standardized `.cache/` pattern (e.g., `.cache/ace-session/compressed-log.md`), allowing for quick retrieval and state restoration.
5. **Linking Raw Data:** The compressed entry must include metadata linking back to the full raw message or code diff (stored via `ace-context` or `ace-git`) using the `wfi://` protocol or file paths, allowing the agent to retrieve full detail on demand.

## Considerations
- **Lossy vs. Lossless:** This is a lossy compression strategy. The system must ensure that critical information (like file paths or specific command outputs) is preserved or linked.
- **Prompt Optimization:** The system prompt for the compression LLM must be rigorously engineered to prioritize brevity and the preservation of actionable state information.
- **Performance Requirement:** The success of this feature relies on the compression step being near-instantaneous (high TPS) to avoid introducing latency into the agent's workflow.
- **Integration:** `ace-taskflow` must be updated to use the compressed log as its primary context source when executing subtasks or generating status reports.

## Benefits
- **Massive Token Reduction:** Significantly lowers the cost and time required for LLM interactions in long sessions.
- **Enhanced State Management:** Provides an instant, compact overview of the session state, improving agent coherence and debugging capabilities.
- **Enables Deeper Context:** Allows the agent to maintain a much longer history of actions within the LLM's context window.
- **Improved Session Overview:** The compressed log serves as a high-quality, human-readable summary of the entire development process.

---

## Original Idea

```
session compression bit by bit -> every message -> every tool call -> is compresed to single line (or more if needed ) and and when we compress next message we send all the compressions we already have (as context / system prompt) and ask for compression only this one -> this is how we can get pretty damn good compression algorighmt for the agent sessions. We can even train to compress certain type of message in certain way. we can add links to full message, and for full code diff. Or meybe have one line summary what have been done, one line for what impact it have for the repo, The Next Action. This benefit for instant compact, restating sesion, and it would give better overview whats going on. Using some TPU maybe even OSS 20B or 120B -> where we can get 500 - 1000 tps it would make it live and instant. Maybe even in the future we could use it for coding - we will not send the whole context all the time but the steps log and only last few steps fully (we would need to have multiple cache sessions to do it effectively, but that would be something
```