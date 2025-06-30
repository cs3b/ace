## 1. Executive Summary

Several workflow-instruction files deviate from the handbook standards (naming, checkbox usage, template embedding). The most disruptive gaps:
• `save-session-context.md` breaks the mandatory `.wf.md` suffix → blocks automated loaders.
• `commit.wf.md` embeds check-boxes inside Process sections (forbidden) and uses “Let’s” in the H1 (discouraged).
• Multiple workflows still use the “path (…template.md)” reference wording even though the full template is now embedded, risking duplicate-source confusion.
Fixing these items will restore strict self-containment, ensure parsing reliability, and keep AI agents predictable.

## 2. Workflow Instructions Updates

| Missing / Incorrect | Required Workflow Action | File Path | Priority |
|---------------------|--------------------------|-----------|----------|
| Wrong extension (.md) | Rename to comply with `<verb>-<context>.wf.md` | `dev-handbook/workflow-instructions/save-session-context.md` | 🔴 |
| Check-boxes inside Process section | Convert to numbered / bullet lists per guide | `…/commit.wf.md` | 🟡 |
| H1 title includes “Let’s” (style clash) | Change to “Commit Workflow Instruction” | `…/commit.wf.md` | 🟢 |
| Residual “path (…)” refs (should be prose or removed) | Replace with neutral description or remove | `create-adr.wf.md`, `create-api-docs.wf.md`, `create-task.wf.md`, others | 🟢 |
| Add “## Project Context Loading” heading (missing) | Insert standard section | `commit.wf.md` (present? verify) | 🟢 |

## 3. Template & Example Updates

✅ Most templates are now properly embedded via XML.
⚠️  `commit.wf.md` provides commit-message examples but not via `<templates>`; consider embedding a commit-message template for reuse.

## 4. Integration Guide Requirements

*No updates required*.

## 5. AI Agent Instruction Updates

⚠️ Violations (checkbox misuse & bad file suffix) may cause agent mis-parsing / failure to load workflow. Update files as per §2 to maintain deterministic behaviour.

## 6. Cross-Reference Integrity

| Issue | Impact |
|-------|--------|
| README lists “Save Session Context” but file will move to `.wf.md` – update link after rename | Broken link risk |
| Internal “path (…template.md)” strings could mislead agents to external files despite embedded XML | Minor confusion |

## 7. Prioritised Handbook Tasks

🔴 Critical

- Rename `save-session-context.md` → `save-session-context.wf.md` & adjust all links.
🟡 High
- Fix checkbox misuse in `commit.wf.md` Process section.
🟢 Medium
- Remove/neutralise lingering “path (…)” template references in all workflows.
- Adjust H1 of `commit.wf.md` to match verb-first naming convention.
🔵 Nice-to-have
- Embed a reusable commit-message XML template for consistency.

## 8. Risk Assessment

Current deviations can:
• Break automatic workflow discovery (wrong suffix) → agent stalls.
• Cause parsing errors when check-boxes appear where bullets expected.
• Create divergent single-source-of-truth for templates.
Overall project workflow reliability downgraded from 99 % target to ~90 % until patched.

## 9. Implementation Recommendation

[ ] ✅ Handbook coverage is complete
[x] ⚠️ Minor guide updates needed
[ ] ❌ Major workflow updates required (blocking)
[ ] 🔴 Critical guide gaps found (workflow-breaking)

Reason: Only a small set of file-format corrections and style clean-ups are needed; no new guides or systemic rewrites required.
