---
id: 8tt.t.fbg
status: progress
priority: medium
created_at: "2026-06-30 10:12:43"
estimate: TBD
dependencies: []
tags: []
---

# Improve new-project agent and docs bootstrap guidance

## Behavioral Specification

### User Experience

- **Input:** A developer initializes ACE guidance in a new repository with `ace-config sync ace-support-core`, optionally from a nested directory.
- **Process:** ACE seeds compact root agent guidance files and a longer project documentation page with current agentic engineering practices.
- **Output:** The new project has root `AGENTS.md` and `CLAUDE.md` files that give agents the most important rules immediately, plus a `docs/` reference page for longer day-to-day practices without bloating the root memory files.

### Expected Behavior

New ACE project initialization should include the recent day-to-day guidance in the generated project bootstrap artifacts:

- Root `AGENTS.md` and `CLAUDE.md` remain short starter files, preferably under 30 lines each.
- Both root files include a compact cost-bias override line:
  `**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.`
- Both root files point to `docs/tools.md#agent-engineering-practices` for expanded agentic engineering conventions.
- Generated `docs/tools.md` includes an `Agent Engineering Practices` section distilled from `/Users/mc/Rs/knowledge-base/day-to-day-guide.md` and the customerkzphoto commit pattern.
- The `Agent Engineering Practices` section captures guidance that is too long for root agent memory, including cost-bias override, workspace/file safety, git-push safety, reproduce-before-fixing, trusted config sources, daemon version handshakes when relevant, visual/layout audits when relevant, and AXI CLI standards when relevant.
- Generated `README.md` or the setup/quick-start docs should include a short pointer to `docs/tools.md#agent-engineering-practices` so humans can discover the same conventions.
- Generated `docs/blueprint.md` should identify canonical project-specific skill locations and provider-projection expectations when the project uses projected skill folders.

Existing overwrite semantics should remain unchanged: generated bootstrap files are created when absent, preserved without `--force`, and refreshed with `--force`.

Existing projects should receive a non-blocking setup hint when the expected guidance is missing. `ace-config doctor` should warn when:

- Root `AGENTS.md` or `CLAUDE.md` exists but lacks the `Cost Bias Override` marker.
- `docs/tools.md` is missing or lacks an `Agent Engineering Practices` heading.
- Root guidance points to `docs/tools.md#agent-engineering-practices`, but the anchor target is absent.

The warning should include a next action such as `Run ace-config sync ace-support-core --force in generated projects, or manually add the Cost Bias Override line and docs/tools.md Agent Engineering Practices section in customized projects.`

### Interface Contract

```bash
ace-config sync ace-support-core
# Expected in a fresh repo:
# - AGENTS.md exists at repo root
# - CLAUDE.md exists at repo root
# - docs/tools.md exists and contains "## Agent Engineering Practices"
# - root files contain the compact Cost Bias Override and link to docs/tools.md#agent-engineering-practices

ace-config sync ace-support-core
# Expected in a repo with custom AGENTS.md / CLAUDE.md / docs guidance:
# - existing user-owned files are preserved without --force

ace-config sync ace-support-core --force
# Expected:
# - generated bootstrap files refresh to the current ACE starter content

ace-config doctor
# Expected in an older/customized repo missing the guidance:
# - emits a warning that AGENTS.md/CLAUDE.md/docs/tools.md are missing agent-engineering guidance
# - gives a concrete next action without modifying files
```

Error Handling:

- Running from a subdirectory should still create project-root files at the detected repository root.
- If a project already has custom root agent files, sync should not overwrite them unless `--force` is used.
- If a project already has a docs guidance file at the chosen target path, sync should preserve it without `--force`.
- Doctor guidance checks should be warnings, not blockers, because missing guidance does not prevent ACE commands from running.

Edge Cases:

- `AGENTS.md` is the generated Codex/root guidance filename; do not introduce a separate singular `AGENT.md` file.
- `CLAUDE.md` should continue to be generated for Claude Code compatibility.
- The docs section should be a concise project starter reference, not a verbatim copy of the external knowledge-base note.
- Projects that intentionally do not use projected skill folders should not be forced to mention `.agents/skills/`, `.codex/skills/`, or `.claude/skills/`; generated blueprint guidance may describe the convention conditionally.

## Success Criteria

- Fresh `ace-config sync ace-support-core` creates root `AGENTS.md`, root `CLAUDE.md`, and `docs/tools.md` with `## Agent Engineering Practices`.
- Root agent files include the `Cost Bias Override` line and point to `docs/tools.md#agent-engineering-practices` while staying compact.
- `docs/tools.md` includes the selected day-to-day practices from `/Users/mc/Rs/knowledge-base/day-to-day-guide.md` and the customerkzphoto commit pattern.
- `ace-config doctor` warns with a concrete next action when an existing project is missing the root marker or docs/tools section.
- Existing bootstrap preservation and `--force` refresh behavior remain covered by tests.
- Quick-start/setup docs explain that root agent files hold short must-read rules and `docs/tools.md` holds expanded practices.

## Validation Questions

- None open. Default target is to improve `ace-support-core` project-root bootstrap templates because `ace-config sync ace-support-core` is the current new-project initialization path.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Standalone task.
- **Slice outcome:** A newly initialized ACE project receives compact root agent guidance, an expanded `docs/tools.md` reference, and doctor warnings when existing projects are missing those conventions.
- **Advisory size:** Medium.
- **Context dependencies:** `ace-support-core/.ace-defaults/project-root/AGENTS.md`, `ace-support-core/.ace-defaults/project-root/CLAUDE.md`, `ace-support-config` bootstrap sync behavior, `docs/quick-start.md`, and `/Users/mc/Rs/knowledge-base/day-to-day-guide.md`.

## Verification Plan

### Unit/Component Validation

- Update bootstrap sync coverage to assert fresh sync creates the new docs guidance file.
- Assert generated `AGENTS.md` and `CLAUDE.md` include the `Cost Bias Override` marker and link to `docs/tools.md#agent-engineering-practices`.
- Assert generated `docs/tools.md` includes `## Agent Engineering Practices`.
- Assert `ace-config doctor` emits a warning and next action when root guidance or `docs/tools.md` is missing the canonical markers.
- Assert `ace-config doctor` passes without that warning when the root marker and docs section are present.
- Assert existing custom root agent files and docs guidance are preserved without `--force`.
- Assert `--force` refreshes generated starter content.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- If demo or quick-start fixtures cover `ace-config sync ace-support-core`, update them so the generated docs file appears in the expected bootstrap artifact set.

### Failure/Invalid Path Validation

- Run sync from a nested subdirectory and verify root files and docs guidance land at the repository root, not inside the subdirectory.

### Verification Commands

- `ace-test ace-support-core`
- `ace-test ace-support-config`

## Objective

Make new ACE projects carry the recent day-to-day agentic engineering lessons at initialization time without overloading root agent memory, and make older/customized projects discover missing guidance through setup health checks. Agents should see the highest-priority rules immediately and have `docs/tools.md` as the expanded reference.

## Scope of Work

- Update `ace-support-core` project-root bootstrap templates for `AGENTS.md` and `CLAUDE.md`.
- Add or update generated `docs/tools.md` in the project-root bootstrap defaults with an `Agent Engineering Practices` section.
- Add `ace-config doctor` warning coverage for missing cost-bias and docs/tools guidance in existing projects.
- Update bootstrap tests and quick-start/setup documentation to reflect the new generated docs artifact.
- Preserve existing sync overwrite semantics and repository-root targeting.

## Deliverables

- Compact updated root agent guidance templates.
- Generated `docs/tools.md` guidance template with `Agent Engineering Practices`.
- Doctor warning for missing agent-engineering guidance in existing projects.
- Tests covering fresh sync, preservation, force refresh, subdirectory sync behavior, and missing-guidance warnings.
- Changelog entries for affected packages if user-visible generated content changes.

## Out of Scope

- Creating a singular `AGENT.md` file.
- Copying the full external guide verbatim into every initialized project.
- Changing `ace-config sync` command syntax.
- Implementing worktree pools, daemon handshakes, force-push guards, or AXI checks as runtime features in this task.

## References

- Source learning document: `/Users/mc/Rs/knowledge-base/day-to-day-guide.md`
- Customer project precedent: https://github.com/cs3b/customerkzphoto/commit/1dcf467f7e7684415ba0310d72162be82dc1f143
- Commit pattern to preserve: root `AGENTS.md` gets a compact `Cost Bias Override`; `README.md` points to `docs/tools.md#agent-engineering-practices`; `docs/tools.md` owns the expanded practices; `docs/blueprint.md` documents canonical skill-source/projection conventions where applicable.
- Current bootstrap templates: `ace-support-core/.ace-defaults/project-root/AGENTS.md` and `ace-support-core/.ace-defaults/project-root/CLAUDE.md`
- Current bootstrap behavior tests: `ace-support-config/test/feat/config_synchronizer_bootstrap_test.rb`
- Current setup doctor: `ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb`
- Current setup documentation: `docs/quick-start.md`
