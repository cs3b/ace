---
id: 8qk.t.m3o
status: draft
priority: low
created_at: "2026-03-21 14:44:05"
estimate: TBD
dependencies: []
tags: [docs, readme]
bundle:
  presets: ["project"]
  files: []
  commands: []
---

# Documentation Overhaul - Handbook Integration Packages (Light Refresh)

## Objective

Light refresh of handbook integration package READMEs for ace-handbook-integration-claude, ace-handbook-integration-codex, ace-handbook-integration-gemini, ace-handbook-integration-opencode, and ace-handbook-integration-pi to apply consistent structure. No GIFs needed. Add clear tagline, consistent sections, keep existing docs. These are provider projection packages — very uniform in structure. Update gemspec summary/description to match README tagline (no internal jargon).

See retros 8qkop7, 8qku8y, 8qkvc4 for learnings applied here.

Research basis: Diataxis framework, top OSS library README patterns for internal/developer-facing packages.

## Behavioral Specification

### User Experience

- **Input**: Existing handbook integration package READMEs (5-8 lines each)
- **Process**: Refresh README structure with consistent tagline, sections, purpose statement, update gemspec metadata
- **Output**: Per package: refreshed README.md with consistent structure, updated gemspec

### Expected Behavior

When a developer opens any handbook integration package README, they should:
1. See a clear tagline explaining the package's purpose
2. See what provider it targets
3. Find installation and basic usage
4. Find link to parent ace-handbook and ACE project

### Interface Contract

Lightweight template applied to each package:
- Tagline: one-line purpose statement identifying the target provider
- Purpose: brief explanation of what the package provides (provider manifests, projections)
- Installation: gem install or Gemfile entry
- What It Provides: description of provider manifests and projections
- Relationship to ace-handbook: how this package fits in the handbook ecosystem
- Link to parent ACE project for broader context

No GIF, no getting-started.md, no usage.md deletion required. Keep existing docs intact.

### Success Criteria

- [ ] Each package README opens with a one-line tagline
- [ ] Each package README has a clear purpose statement
- [ ] Each package README includes installation instructions
- [ ] Each package README describes what it provides
- [ ] Each package README links to ace-handbook and the parent ACE project
- [ ] Consistent section ordering across all five packages
- [ ] Consistent section ordering matches other support library orchestrators for cross-group uniformity
- [ ] Existing documentation is preserved (no deletions)
- [ ] Gemspec summary matches README tagline (no internal jargon)
- [ ] All internal links resolve correctly
- [ ] ace-lint passes on all modified files

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator
- **Subtasks**: One per package (ace-handbook-integration-claude, ace-handbook-integration-codex, ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi)
- **Advisory Size**: small per subtask

### Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| Consistent tagline for ace-handbook-integration-claude | ace-handbook-integration-claude subtask | -- | KEPT |
| Consistent tagline for ace-handbook-integration-codex | ace-handbook-integration-codex subtask | -- | KEPT |
| Consistent tagline for ace-handbook-integration-gemini | ace-handbook-integration-gemini subtask | -- | KEPT |
| Consistent tagline for ace-handbook-integration-opencode | ace-handbook-integration-opencode subtask | -- | KEPT |
| Consistent tagline for ace-handbook-integration-pi | ace-handbook-integration-pi subtask | -- | KEPT |
| Uniform section structure across handbook integration packages | all subtasks | -- | KEPT |
| Gemspec metadata alignment | all subtasks | -- | KEPT |

### Verification Plan

#### Unit / Component Validation
- [ ] Each README.md renders correctly on GitHub
- [ ] Code examples in README are syntactically valid

#### Integration / E2E Validation
- [ ] All internal links resolve
- [ ] ace-lint passes on all modified files
- [ ] Section ordering is consistent across all five packages

#### Failure / Invalid-Path Validation
- [ ] No existing documentation was deleted
- [ ] No GIF placeholders or broken image references

## Scope of Work

### Deliverables

**ace-handbook-integration-claude:**
- Refreshed README.md with consistent tagline, purpose, install, what it provides, ace-handbook link, ACE link
- Updated gemspec (summary = tagline, description = value prop, no jargon)

**ace-handbook-integration-codex:**
- Refreshed README.md with consistent tagline, purpose, install, what it provides, ace-handbook link, ACE link
- Updated gemspec (summary = tagline, description = value prop, no jargon)

**ace-handbook-integration-gemini:**
- Refreshed README.md with consistent tagline, purpose, install, what it provides, ace-handbook link, ACE link
- Updated gemspec (summary = tagline, description = value prop, no jargon)

**ace-handbook-integration-opencode:**
- Refreshed README.md with consistent tagline, purpose, install, what it provides, ace-handbook link, ACE link
- Updated gemspec (summary = tagline, description = value prop, no jargon)

**ace-handbook-integration-pi:**
- Refreshed README.md with consistent tagline, purpose, install, what it provides, ace-handbook link, ACE link
- Updated gemspec (summary = tagline, description = value prop, no jargon)

## Out of Scope

- Code changes to any package
- New features or functionality
- GIF recordings or demo assets
- Creating new docs/getting-started.md files
- Modifications to test suites
