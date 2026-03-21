---
id: 8qk.t.m3o.0
status: pending
priority: low
created_at: "2026-03-21 14:44:45"
estimate: TBD
dependencies: []
tags: [docs, readme]
parent: 8qk.t.m3o
bundle:
  presets: ["project"]
  files:
    - ace-handbook-integration-claude/README.md
  commands: []
---

# ace-handbook-integration-claude Light Refresh

## Objective

Light refresh of ace-handbook-integration-claude's README to apply consistent structure. Add clear tagline, consistent sections, keep existing docs. No GIF or getting-started.md needed -- this is a provider projection package. The current README (8 lines) has a title and brief description explaining it as the replacement target for legacy ace-integration-claude. It needs a tagline, purpose, install, what it provides, and links to ace-handbook and ACE.

## Behavioral Specification

### User Experience
- **Input**: Current ace-handbook-integration-claude/README.md (8 lines)
- **Process**: Refresh README with consistent structure: tagline, purpose, install, what it provides, ace-handbook link, ACE link
- **Output**: Refreshed README.md with consistent structure

### Expected Behavior

When a developer opens the README, they should see:
1. Clear tagline explaining the package's purpose
2. Concise description of what it provides
3. Installation instructions
4. What it provides (Claude-native workflows and provider manifests)
5. Link to ace-handbook and parent ACE project

Suggested tagline: "Claude-specific provider integration for ACE handbook skills."

Key content to preserve:
- Note about being the replacement target for legacy ace-integration-claude
- Relationship to ace-handbook for shared sync/runtime behavior

### Interface Contract

README.md structure:
- One-line tagline
- Purpose description (1-2 paragraphs)
- Installation
- What It Provides
- Part of ACE footer

### Success Criteria
- [ ] README has clear one-line tagline
- [ ] Structure is consistent with other handbook integration package READMEs
- [ ] Existing useful content preserved
- [ ] Part of ACE footer present
- [ ] All links resolve

### Vertical Slice Decomposition (Task/Subtask Model)
- **Slice Type**: Subtask
- **Slice Outcome**: ace-handbook-integration-claude README refreshed with consistent structure
- **Advisory Size**: small

### Verification Plan
#### Unit / Component Validation
- [ ] README renders correctly on GitHub
- [ ] All links resolve
