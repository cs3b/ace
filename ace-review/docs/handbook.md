# ace-review Handbook Reference

Skills, workflows, prompts, guide, and template shipped with ace-review.

## Skills

| Skill | What it does |
|-------|-------------|
| `as-review-run` | Review code changes with preset-based analysis and LLM feedback |
| `as-review-pr` | Review a GitHub PR with feedback verification and comment resolution |
| `as-review-package` | Comprehensive code, docs, UX/DX review with recommendations |
| `as-review-apply-feedback` | Apply verified feedback items — implement fixes, mark resolved |
| `as-review-verify-feedback` | Verify feedback items through multi-dimensional claim analysis |

## Workflow Instructions

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://review/run` | Code review: preset selection, model execution, feedback extraction | `as-review-run` |
| `wfi://review/pr` | PR review: determine PR, run review, verify/apply feedback, resolve comments | `as-review-pr` |
| `wfi://review/package` | Package review: structure, surface, docs, tests analysis | `as-review-package` |
| `wfi://review/apply-feedback` | Work through verified items: implement, resolve, skip with evidence | `as-review-apply-feedback` |
| `wfi://review/verify-feedback` | Multi-dimensional claim analysis with false positive detection | `as-review-verify-feedback` |

## Prompts

ace-review ships 22 modular prompt files composed via `--prompt-*` flags.

### Base Prompts

| Prompt | Purpose |
|--------|---------|
| `base/system.md` | Core review system prompt — role, principles, output format |
| `base/sections.md` | Review section structure and organization |

### Focus Modules

Select via `--prompt-focus` or `--add-focus`:

| Category | Prompts | Purpose |
|----------|---------|---------|
| Architecture | `architecture/atom.md`, `architecture/reflection.md` | ATOM pattern review, architectural reflection |
| Frameworks | `frameworks/rails.md`, `frameworks/vue-firebase.md` | Framework-specific review guidance |
| Languages | `languages/ruby.md` | Language-specific conventions and patterns |
| Phase | `phase/correctness.md`, `phase/quality.md`, `phase/polish.md` | Review depth: bugs → quality → polish |
| Quality | `quality/performance.md`, `quality/security.md` | Performance and security focus |
| Scope | `scope/docs.md`, `scope/spec.md`, `scope/tests.md` | Documentation, spec, or test focus |

### Format Modules

Select via `--prompt-format`:

| Prompt | Purpose |
|--------|---------|
| `format/compact.md` | Minimal output, finding-per-line |
| `format/standard.md` | Balanced detail (default) |
| `format/detailed.md` | Full context and reasoning |

### Guideline Modules

Select via `--prompt-guidelines`:

| Prompt | Purpose |
|--------|---------|
| `guidelines/icons.md` | Icon conventions for severity and status |
| `guidelines/tone.md` | Review tone and communication style |

### Synthesis Prompts

| Prompt | Purpose |
|--------|---------|
| `synthesis-review-reports.system.md` | Synthesize multi-model review reports into unified findings |
| `synthesize-feedback.system.md` | Extract structured feedback items from review output |

## Guides

| Guide | Purpose |
|-------|---------|
| `code-review-process.g.md` | Code review principles, methodology, priority framework (Critical/High/Medium/Low), development workflow phases, and quality standards |

## Templates

| Template | Purpose |
|----------|---------|
| `task-review-summary.template.md` | 12-section review summary: executive summary, project alignment, task structure, dependencies, implementation, issues by priority, scope, risk, recommendations, questions, approval, next steps |
