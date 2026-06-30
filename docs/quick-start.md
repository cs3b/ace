# Quick Start

By the end of this walkthrough you will have captured an idea, turned it into a task spec, run a full implement-test-review-ship pipeline in an isolated worktree, and understood how to customize every part of it. Total time: about 15 minutes of reading, then one command to start real work.

## Install

Ruby 3.2+ required.

Choose one setup path:

- **Minimal (first-use default):** enough for task specs, context loading, provider access, and one integration.
- **Full-stack (recommended for this walkthrough):** includes assign/overseer/review/tmux/test/docs/retro/demo/git workflows.

### What this will create

Before setup commands run, expect:

- `.ace/` config overrides when project-local config is synced
- Agent skill folders for installed integrations (for example `.codex/skills/`, `.claude/skills/`)
- Optional `AGENTS.md`, `CLAUDE.md`, and `docs/tools.md` starter guidance with ACE provenance, customization notes,
  expanded [agent engineering practices](tools.md#agent-engineering-practices), and refresh commands when you also sync
  `ace-support-core` project-root templates
  (existing user-maintained content is preserved)
- `Gemfile` and `Gemfile.lock` dependency updates

### 1. Add the ACE tools you need

Minimal path:

```bash
bundle add --group "development, test" \
  ace-task ace-bundle ace-handbook ace-llm ace-llm-providers-cli \
  ace-handbook-integration-codex
# Optional integrations: ace-handbook-integration-claude, ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Full-stack path:

```bash
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs ace-llm ace-llm-providers-cli \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
# Also available: ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

If you install only the minimal path, advanced workflow commands in this walkthrough may be unavailable until you add the full-stack packages. In particular, `ace-git-commit` is part of the full-stack path, so the first-commit flow below includes a plain `git commit` fallback for minimal installs.

### 2. Install gems

```bash
bundle install
```

### 3. Sync CLI provider config (`ace-config` comes from `ace-support-config`, not a separate gem)

```bash
bundle exec ace-config sync ace-llm-providers-cli
```

If you also want starter `AGENTS.md`, `CLAUDE.md`, and `docs/tools.md` guidance in the repository root, sync the
`ace-support-core` project-root templates separately:

```bash
bundle exec ace-config sync ace-support-core
```

Use `bundle exec` for this repo-local setup path so the copied commands run against the ACE gems installed in the
current project instead of any global executable that may be older or configured differently. If you intentionally use
binstubs, shell wrappers, or global installs, bare `ace-*` commands remain an advanced option.

Most ACE tools run from packaged `.ace-defaults`; sync additional package config only when you want project-local
overrides.

When you sync `ace-support-core`, ACE creates compact `AGENTS.md` and `CLAUDE.md` starter files plus
`docs/tools.md` for longer day-to-day guidance. The root files hold must-read agent rules, while
[`docs/tools.md#agent-engineering-practices`](tools.md#agent-engineering-practices) holds expanded practices for
workspace safety, debugging, push safety, daemon reuse, UI review, and agent-facing CLI output. Use
`bundle exec ace-config sync ace-support-core --force` to refresh generated starter content and
`bundle exec ace-handbook sync` when you want to refresh projected skill folders.

### 4. Sync handbook assets to your agent platforms

```bash
bundle exec ace-handbook sync
```

### 5. Verify setup, providers, and project context

```bash
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-bundle project
```

Treat these commands as separate checks with different purposes:

- `bundle exec ace-llm --list-providers` is the canonical provider discovery command for repo-local setup. It lists
  available providers and setup hints, but it does not prove your configured ACE roles can execute prompts.
- `bundle exec ace-config doctor` is the readiness check for the quick-start path. It validates generated local
  artifacts, ignored `.ace-local/` output, provider package availability, config hygiene, and provider execution
  readiness. Use `bundle exec ace-config doctor --no-probe` if you want to skip live provider probes during setup.
- `bundle exec ace-bundle project` confirms project context loading once setup is ready.

If CLI providers are unavailable in `--list-providers`, verify `ace-llm-providers-cli` is in your install list.
Missing credentials or local CLI account access should be treated as provider readiness issues, not ACE install
corruption. API-only usage remains valid even when unrelated CLI providers are inactive.

### 6. Optional assignment sanity check in plain projects

```bash
bundle exec ace-assign create --preset work-on-task --task <taskref>
```

If `bundle install` fails right after a large ACE release, run:

```bash
bundle install --full-index
```

Then return to normal `bundle install` once RubyGems propagation catches up.

### 7. First commit after setup

For the initial ACE setup snapshot, prefer a deterministic first commit before relying on provider-backed message
generation.

If you installed the full-stack path, use:

```bash
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

If you installed only the minimal path, use plain Git instead:

```bash
git commit -m "chore: set up ace tooling"
```

If you want to preview the LLM-backed path after readiness is confirmed, add the full-stack packages first, then run:

```bash
bundle exec ace-git-commit --dry-run -i "set up ace tooling"
```

Use this first-commit guidance when setup files are already staged or when a prior LLM-backed attempt failed after
staging. Check the current state with:

```bash
git status
```

Why this combination is recommended for the first setup commit:

- `--only-staged` commits the current index only, so unrelated unstaged changes stay out of the setup snapshot.
- `--no-split` forces one setup commit even if ACE detects multiple configuration scopes across root files and
  generated agent assets.
- `-m` bypasses LLM-backed message generation entirely, which keeps the first setup commit unblocked while provider
  readiness is still being verified.

Once `bundle exec ace-config doctor` passes, LLM-backed commit generation becomes an optional next step rather than a
setup prerequisite.

## 1. Capture an idea

```bash
ace-idea create "Add retry logic to webhook delivery" --tags reliability,webhooks
```

This creates a markdown file in `.ace-ideas/`:

```
.ace-ideas/8r2f4-add-retry-logic-to-webhook-delivery/
  8r2f4-add-retry-logic-to-webhook-delivery.idea.s.md
```

The file has YAML front matter (id, status, tags, timestamps) and a markdown body. Edit it directly — it's just a file in your repo.

```bash
ace-idea list                              # list all ideas
ace-idea list --in next --status pending   # filter by location and status
ace-idea show 8r2f4                        # show one idea
ace-idea update 8r2f4 --move-to next       # move between buckets
```

Idea locations: root scope is the virtual `next` queue; `_maybe/`, `_review/`, and `_archive/` are physical folders.

## 2. Draft a task from the idea

In Claude Code:

```
/as-task-draft
```

Or from the terminal:

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

The spec file includes front matter (id, status, priority, dependencies) and structured sections:

- **Behavioral Specification** — what the feature does, expected behavior, success criteria
- **Scope of Work** — deliverables, affected packages
- **Verification Plan** — `fast` tests, `feat` tests, failure scenarios

Break large tasks into subtasks:

```bash
ace-task create "Add retry queue data model" --child-of 8r3
ace-task create "Implement backoff calculator" --child-of 8r3
```

```bash
ace-task list                      # list all tasks
ace-task show 8r3                  # show task details
ace-task show 8r3 --format full    # show with full spec content
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
ace-overseer work-on -t 8r3
```

This does three things:

1. **Creates an isolated worktree** via `ace-git-worktree` — a separate checkout so your main branch stays clean
2. **Opens a tmux window** via `ace-tmux` — a dedicated terminal session for the task
3. **Starts an assignment** via `ace-assign` — loads the `work-on-task` preset and begins stepping through it

Inside the tmux session, use `/as-assign-drive` in Claude Code to walk through each assignment step.

Check on active worktrees:

```bash
ace-overseer status    # list active task worktrees
ace-overseer prune     # clean up finished worktrees
```

## 5. What happens inside the pipeline

The `work-on-task` preset ([source](../ace-assign/.ace-defaults/assign/presets/work-on-task.yml)) runs a 15-step pipeline. Here is what each phase does:

### Implement

- **onboard** — Load project context via `wfi://onboard`. Orients the agent on repo structure, conventions, and the task spec.
- **work-on-{task}** — For each task in the batch, fork a sub-agent context and run `wfi://task/work`. This is where the actual code gets written.

### Verify

- **verify-test-suite** — Run `wfi://test/verify-suite` across affected packages. Skipped for docs-only changes.
- **verify-e2e** — Run E2E tests for modified packages. Auto-detects which packages changed.

### Release

- **release-minor** — Bump versions and update CHANGELOGs for all modified packages.
- **update-docs** — Run `wfi://docs/update` if any public API contracts changed.

### Ship

- **create-pr** — Create a pull request summarizing all tasks in the batch.

### Review cycles

Three progressively focused review rounds, each running review → apply-feedback → release:

- **review-valid** — Correctness. Catches bugs, logic errors, missing edge cases. Uses `code-valid` preset.
- **review-fit** — Quality. Checks architecture, performance, standards compliance. Uses `code-fit` preset.
- **review-shine** — Polish. Simplifies code, improves naming, tightens documentation. Uses `code-shine` preset.

### Finalize

- **reorganize-commits** — Rewrite history to group changes by concern (one commit per logical change).
- **push-to-remote** — Force-push (with lease) the cleaned-up history.
- **update-pr-desc** — Update the PR description with the final diff summary.
- **mark-tasks-done** — Archive completed tasks.
- **create-retro** — Generate a retrospective capturing what went well and what to improve.

Other presets are available for different workflows: `fix-bug`, `quick-implement`, `release-only`, and `work-on-docs`.

## 6. The protocol system

ACE organizes all content — workflows, guides, templates, prompts, skills — through a protocol system. Each protocol maps to a file type:

| Protocol | Extension | Purpose | Example |
|----------|-----------|---------|---------|
| `wfi://` | `.wf.md` | Workflow instructions | `wfi://task/work` |
| `guide://` | `.g.md` | Guides and references | `guide://changelog` |
| `tmpl://` | `.template.md` | Templates | `tmpl://test-report` |
| `prompt://` | `.md` | LLM prompts | `prompt://git-commit.system` |
| `skill://` | `SKILL.md` | Agent skills | `skill://as-release` |

Each package ships content in its `handbook/` directory:

```
ace-review/
  handbook/
    workflow-instructions/review/
      run.wf.md
      apply-feedback.wf.md
    guides/
      review-presets.g.md
    skills/as-review-pr/
      SKILL.md
```

Load any resource:

```bash
ace-bundle wfi://task/work       # load a workflow
ace-bundle guide://changelog     # load a guide
```

Discover what's available:

```bash
ace-nav list 'wfi://*'           # list all workflows
ace-nav list 'guide://*'         # list all guides
ace-nav sources                  # show where resources come from
```

The nav system resolves protocols by scanning registered sources in priority order. When multiple packages provide the same protocol resource, the highest-priority source wins.

## 7. Customization

ACE uses a three-level configuration cascade. Higher levels override lower ones:

```
Gem defaults            (lowest priority)
  └─ User overrides     (~/.ace/, ~/.ace-handbook/)
       └─ Project       (.ace/, .ace-handbook/)    (highest priority)
```

### Override a commit prompt

Create a project-level prompt that replaces the gem default:

```bash
mkdir -p .ace-handbook/prompts
cat > .ace-handbook/prompts/git-commit.system.md << 'EOF'
You are a commit message generator.
Always use conventional commits format.
EOF
```

### Override config

Change settings for this project:

```bash
mkdir -p .ace/git
cat > .ace/git/commit.yml << 'EOF'
max_subject_length: 72
body_wrap: 80
EOF
```

### Verify cascade with public commands

Confirm the project overrides are visible without internal Ruby probing:

```bash
ace-config diff --file .ace/git/commit.yml
ace-bundle prompt://git-commit.system
```

### Add a custom workflow

Create a project-specific workflow that's immediately available as `wfi://deploy`:

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

### Agent platform skills

Skills project to agent-specific directories — `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`. The `ace-handbook-integration-*` gems handle this projection. Run `ace-handbook sync` to project skills to all configured agent platforms.

## Next steps

- [Architecture](architecture.md) — how packages fit together and the ATOM pattern
- [Tools Reference](tools.md) — full command inventory for all 40+ packages
- `ace-bundle project` — load the complete project context bundle
- `ace-nav sources` — see all registered content sources
