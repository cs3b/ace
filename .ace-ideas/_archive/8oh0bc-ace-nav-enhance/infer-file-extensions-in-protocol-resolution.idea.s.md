---
title: Enhance ace-nav Protocol Resolution to Infer File Extensions
filename_suggestion: fix-nav-extension-inference
enhanced_at: 2026-01-18 00:12:36.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2026-01-22 13:31:20.000000000 +00:00
id: 8oh0bc
tags: []
created_at: '2026-01-18 00:12:35'
---

# Enhance ace-nav Protocol Resolution to Infer File Extensions

## Problem
The `ace-nav` tool, which resolves resources via protocols like `guide://` and `wfi://`, currently requires the full file extension to be explicitly provided in the URI (e.g., `guide://markdown-style.g` instead of `guide://markdown-style`). This strict matching causes resource discovery failures when agents or developers use the intuitive base name of a handbook item (e.g., omitting `.g.md` or `.wf.md`). This friction violates the DX/AX Dual Optimization principle by making the tool less intuitive and predictable for autonomous use.

## Solution
Modify the resource resolution mechanism within `ace-support-nav` to automatically attempt inference of common ACE handbook extensions if the initial exact path lookup fails. This "Do What I Mean" (DWIM) behavior will allow users to reference guides, agents, and workflows using only their base slug, significantly improving usability and aligning with the principle of intuitive defaults.

## Implementation Approach
1.  **Identify Component**: The logic resides in `ace-support-nav`, likely within a Molecule responsible for resolving protocol paths (e.g., `Ace::Support::Nav::Molecules::ResourceResolver`).
2.  **Extension List**: Define a configurable, prioritized list of common ACE extensions in `ace-support-nav`'s `.ace-defaults/nav/config.yml` (e.g., `['.g.md', '.wf.md', '.ag.md', '.md']`).
3.  **Resolution Logic**: If the requested path (e.g., `/path/to/markdown-style`) does not exist, the resolver should iterate through the configured extensions, checking for files like `/path/to/markdown-style.g.md`, and return the first match.
4.  **Configuration Cascade**: Ensure the list of inferred extensions is customizable via the standard configuration cascade (`.ace/nav/config.yml`) as per ADR-022.

## Considerations
- **Determinism**: The order of extension checking must be deterministic to ensure predictable results if multiple files match (e.g., prioritize `.g.md` over `.md`).
- **Integration**: This change must be implemented in `ace-support-nav` to benefit all gems that rely on its protocol resolution.
- **CLI Interface Design**: The CLI output must return the full, resolved path, even if inference was used, maintaining deterministic output for agents.

## Benefits
- **Improved AX**: Agents can reliably reference handbook resources without needing to know the exact file extension, simplifying prompt construction and workflow execution.
- **Better DX**: Developers experience less friction when navigating the codebase using `ace-nav`.
- **Consistency**: Aligns `ace-nav` with the principle of providing intuitive defaults and predictable behavior across the ACE ecosystem.

---

## Original Idea

```
ace-nav bug - do not search for documents without extenstion

ace-task.218 on  218-restructure-visionmd-to-focused-manifesto [$!?] via 💎 v3.4.7
❯ ace-nav guide://markdown-style
Resource not found: guide://markdown-style

ace-task.218 on  218-restructure-visionmd-to-focused-manifesto [$!?] via 💎 v3.4.7
❯ ace-nav guide://documentation
Resource not found: guide://documentation

ace-task.218 on  218-restructure-visionmd-to-focused-manifesto [$!?] via 💎 v3.4.7
❯ ace-nav guide://documentation.g
/Users/mc/Ps/ace-task.218/ace-docs/handbook/guides/documentation.g.md

ace-task.218 on  218-restructure-visionmd-to-focused-manifesto [$!?] via 💎 v3.4.7
❯ ace-nav guide://mardown-style.g
Resource not found: guide://mardown-style.g

ace-task.218 on  218-restructure-visionmd-to-focused-manifesto [$!?] via 💎 v3.4.7
❯ ace-nav guide://markdown-style.g
/Users/mc/Ps/ace-task.218/ace-docs/handbook/guides/markdown-style.g.md
```