---
id: v.0.9.0+task.218
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Restructure vision.md to focused manifesto

## Objective

Reduce `docs/vision.md` from 610 lines to ~120-150 lines by focusing on WHY and WHAT GUIDES US, moving technical details elsewhere.

## Problem

Current vision.md tries to be:
- Manifesto (why ACE exists, principles)
- Feature showcase (4 workflow examples with mermaid diagrams)
- Architecture documentation (ATOM, config cascade)
- Getting started guide
- Cross-references

A vision document should only answer:
1. **WHY** do we exist? (problem + belief)
2. **WHAT** guides our decisions? (principles)
3. **HOW** does it feel? (one example)

## Scope of Work

### Keep in vision.md (~120-150 lines)
- Opening quote/belief statement
- "Why ACE Exists" section (problem, vision, why "agentic")
- "Core Principles" (4 principles, concise, NO mermaid diagrams)
- ONE example (ace-git-commit - same command for human/agent)
- Brief "What We Build" statement (not a list)
- Closing tagline

### Migrate to architecture.md (~40 lines)
- Configuration cascade mermaid diagram + explanation

### Remove (duplicate or belongs elsewhere)
- ATOM architecture diagram + details (already in architecture.md)
- Tools/capabilities list (already in architecture.md, gets stale)
- 3 of 4 workflow examples (ace-review, ace-bundle, ace-taskflow)
- Getting Started section (README has Quick Start)
- Cross-references section (navigation, not vision)

## Implementation Plan

### Phase 1: Migrate config cascade to architecture.md

- [ ] Read current architecture.md
- [ ] Add "Configuration Cascade" section with mermaid diagram from vision.md
- [ ] Verify no duplication

### Phase 2: Restructure vision.md

- [ ] Keep: Opening quote + "Why ACE Exists" (~55 lines)
- [ ] Keep: "Core Principles" but remove mermaid diagrams, keep concise (~60 lines)
- [ ] Keep: ONE example (ace-git-commit) (~20 lines)
- [ ] Add: Brief "What We Build" statement (3-5 lines, no list)
- [ ] Remove: ATOM section (duplicate)
- [ ] Remove: Config cascade section (migrated)
- [ ] Remove: 3 workflow examples (ace-review, ace-bundle, ace-taskflow)
- [ ] Remove: Getting Started section
- [ ] Remove: Cross-references section
- [ ] Update frontmatter (max_lines: 150)

### Phase 3: Verification

- [ ] vision.md is ~120-150 lines
- [ ] architecture.md has config cascade
- [ ] No broken links
- [ ] Content reads as focused manifesto

## Acceptance Criteria

- [ ] vision.md reduced from 610 to ~120-150 lines
- [ ] Config cascade migrated to architecture.md
- [ ] Vision focuses on: WHY, PRINCIPLES, ONE EXAMPLE
- [ ] No duplicate content between vision.md and architecture.md
- [ ] Document reads as inspiring manifesto, not technical reference

## Target Structure

```markdown
# ACE Vision: Agentic Coding Environment

> ACE is built on a simple belief: AI coding assistants should work
> in the same environment as developers, using the same tools.

## Why ACE Exists
### The Problem (~10 lines)
### The Vision (~15 lines)
### Why "Agentic"? (~15 lines)

## Core Principles
### 1. Same Environment, Same Tools (~15 lines)
### 2. DX/AX Dual Optimization (~15 lines)
### 3. Configuration Without Lock-In (~10 lines)
### 4. Distribution Without Friction (~10 lines)

## Example: ace-git-commit (~15 lines)
[One example showing same command for human/agent]

## What We Build (~5 lines)
[Brief statement, link to architecture.md and tools.md]

---
*ACE: Making AI-assisted development as simple as `gem install`.*
```

## References

- Current vision.md: 610 lines
- architecture.md: ~160 lines (will grow to ~200)
- Original what-do-we-build.md was ~50 lines
