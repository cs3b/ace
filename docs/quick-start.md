# Quick Start

Walk through the full ACE workflow: from capturing an idea to shipping a reviewed PR. ACE provides the workflow layer that coding agent harnesses (Claude Code, Codex CLI, Gemini CLI) operate on - structured tasks, context bundles, review cycles, and skills that any harness can consume through standard CLI commands.

## Install

Ruby 3.2+ required. Install the orchestrator stack used in this walkthrough:

```bash
gem install ace-overseer
```

This installs `ace-overseer` plus its workflow dependencies (`ace-assign`, `ace-task`, `ace-git`, `ace-git-worktree`, and `ace-tmux`).
If you want the full ACE toolkit command surface, install additional gems or work from the monorepo with `bundle install`.

## 1. Capture an idea

```bash
ace-idea create "Add retry logic to webhook delivery" --tags reliability,webhooks
```

This creates a markdown file in `.ace-ideas/`:

```
.ace-ideas/_next/8r2f4-add-retry-logic-to-webhook-delivery/
  8r2f4-add-retry-logic-to-webhook-delivery.idea.s.md
```

The file has YAML front matter (id, status, tags, timestamps) and a markdown body with the description. You can edit it directly — it's just a file in your repo.

```bash
ace-idea list                          # list all ideas
ace-idea list --in next --status pending  # filter by location and status
ace-idea show 8r2f4                    # show one idea
ace-idea update 8r2f4 --move-to next   # move between buckets
```

Idea locations: `_next/` (up next), `_maybe/` (considering), `_review/` (needs review), `_archive/` (done).

## 2. Draft a task from the idea

In Claude Code:

```
/as-task-draft
```

Or from the CLI:

```bash
ace-task create "Implement webhook retry with exponential backoff" \
  --tags reliability,webhooks \
  --priority high
```

This creates a task spec in `.ace-tasks/`:

```
.ace-tasks/8r/3/8r3.t.0k7-implement-webhook-retry-with-exponential-backoff/
  8r3.t.0k7-implement-webhook-retry-with-exponential-backoff.s.md
```

The spec file includes front matter (id, status, priority, dependencies, estimate) and structured sections:

- **Behavioral Specification** — what the feature does, expected behavior, success criteria
- **Scope of Work** — deliverables, affected packages
- **Verification Plan** — unit tests, integration tests, failure scenarios

Break large tasks into subtasks:

```bash
ace-task create "Add retry queue data model" --child-of 8r3
ace-task create "Implement backoff calculator" --child-of 8r3
```

```bash
ace-task list                  # list all tasks
ace-task show 8r3              # show task details
ace-task show 8r3 --format full  # show with full spec content
```

## 3. Review the spec

In Claude Code:

```
/as-task-review
```

This validates the spec for completeness, surfaces gaps in the behavioral specification, and flags missing success criteria or test scenarios.

Generate an implementation plan:

```
/as-task-plan
```

## 4. Run it in a worktree

```bash
ace-overseer work-on 8r3
```

This does three things:

1. **Creates an isolated worktree** via `ace-git-worktree` — a separate checkout so your main branch stays clean
2. **Opens a tmux window** via `ace-tmux` — dedicated terminal session for the task
3. **Starts an assignment** via `ace-assign` — loads the `work-on-task` preset and begins stepping through it

Inside the tmux session, use `/as-assign-drive` in Claude Code to walk through each step of the assignment.

Check on active worktrees:

```bash
ace-overseer status    # list active task worktrees
ace-overseer prune     # clean up finished worktrees
```

## 5. What the preset does

The `work-on-task` preset ([ace-assign/.ace-defaults/assign/presets/work-on-task.yml](../ace-assign/.ace-defaults/assign/presets/work-on-task.yml)) runs a multi-step pipeline. Here's what happens in order:

### Implement

1. **onboard** — Load project context via `wfi://onboard`. Orients the agent on repo structure, conventions, and the task spec.
2. **work-on-{task}** — For each task in the batch, fork a context and run `wfi://task/work`. This is where the actual code gets written.

### Verify

3. **verify-test-suite** — Run `wfi://test/verify-suite` across affected packages. Skippable for docs-only changes.
4. **verify-e2e** — Run E2E tests for modified packages. Auto-detects which packages changed.

### Release

5. **release-minor** — Bump versions (minor or patch) and update CHANGELOGs for all modified packages.
6. **update-docs** — Run `wfi://docs/update` if any public API contracts changed.

### Ship

7. **create-pr** — Create a pull request via `wfi://github/pr/create`, summarizing all tasks in the batch.

### Review cycles

Three review rounds, each progressively more focused:

8. **review-valid** — Correctness review. Catches bugs, logic errors, missing edge cases. Runs: review-pr (code-valid preset) → apply-feedback → release patch.
9. **review-fit** — Quality review. Checks architecture, performance, standards compliance. Same sub-steps with code-fit preset.
10. **review-shine** — Polish review. Simplifies code, improves naming, tightens documentation. Same sub-steps with code-shine preset.

### Finalize

11. **reorganize-commits** — Rewrite history via `wfi://git/reorganize-commits` to group changes by concern (one commit per logical change).
12. **push-to-remote** — Force-push (with lease) the cleaned-up history.
13. **update-pr-desc** — Update the PR description with the final diff summary.
14. **mark-tasks-done** — Archive completed tasks, commit the file moves.
15. **create-retro** — Generate a retrospective for the batch.

## 6. How the handbook works

ACE organizes all content — workflows, guides, templates, prompts, skills — through a protocol system. Each protocol maps to a file type:

| Protocol | File extension | Purpose | Example |
|----------|---------------|---------|---------|
| `wfi://` | `.wf.md` | Workflow instructions | `wfi://task/work` |
| `guide://` | `.g.md` | Guides and references | `guide://changelog` |
| `tmpl://` | `.template.md` | Templates | `tmpl://test-report` |
| `prompt://` | `.md` | LLM prompts | `prompt://git-commit.system` |
| `skill://` | `SKILL.md` | Agent skills | `skill://as-release` |

Each package ships content in its `handbook/` directory:

```
ace-review/
  handbook/
    workflow-instructions/
      review/
        run.wf.md
        apply-feedback.wf.md
    guides/
      review-presets.g.md
    skills/
      as-review-pr/
        SKILL.md
```

Load any resource with `ace-bundle`:

```bash
ace-bundle wfi://task/work       # load a workflow
ace-bundle guide://changelog     # load a guide
```

Discover available resources with `ace-nav`:

```bash
ace-nav wfi://                   # list all workflows
ace-nav guide://                 # list all guides
ace-nav --sources                # list where resources come from
```

The nav system resolves protocols by scanning registered sources in priority order. When multiple packages provide the same protocol resource, the highest-priority source wins.

## 7. How to customize

ACE uses a three-level cascade. Higher levels override lower ones:

```
Gem defaults          (lowest priority)
  └─ User overrides
       └─ Project overrides   (highest priority)
```

### Where each level lives

| Level | Config | Handbook content |
|-------|--------|-----------------|
| Gem defaults | `<gem>/.ace-defaults/` | `<gem>/handbook/` |
| User overrides | `~/.ace/` | `~/.ace-handbook/` |
| Project overrides | `.ace/` | `.ace-handbook/` |

### Override examples

**Override a commit prompt** — create a project-level prompt that replaces the gem default:

```bash
mkdir -p .ace-handbook/prompts
# Write your custom prompt:
cat > .ace-handbook/prompts/git-commit.system.md << 'EOF'
You are a commit message generator.
Always use conventional commits format.
EOF
```

**Override git commit config** — change commit settings for this project:

```bash
mkdir -p .ace/git
cat > .ace/git/commit.yml << 'EOF'
max_subject_length: 72
body_wrap: 80
EOF
```

**Add a custom workflow** — create a project-specific workflow:

```bash
mkdir -p .ace-handbook/workflow-instructions
cat > .ace-handbook/workflow-instructions/deploy.wf.md << 'EOF'
# Deploy Workflow

## Steps

1. Run the test suite
2. Build the container image
3. Push to registry
4. Update the deployment manifest
EOF
```

The new workflow is immediately available as `wfi://deploy`.

**Override a review preset** — customize what a review cycle checks:

```bash
mkdir -p .ace/review/presets
# Your project-level preset overrides the gem default
```

### Agent platform skills

Skills project to agent-specific directories:

- Claude Code: `.claude/skills/`
- Codex CLI: `.codex/skills/`
- Gemini CLI: `.gemini/skills/`

The `ace-handbook-integration-*` gems handle this projection. Run `ace-handbook sync` to project skills to all configured agent platforms.

## Next steps

- Read the [Architecture](architecture.md) doc for how packages fit together
- Browse [Tools Reference](tools.md) for the full command inventory
- Run `ace-bundle project` to see the full project context bundle
- Run `ace-nav --sources` to see all registered content sources
