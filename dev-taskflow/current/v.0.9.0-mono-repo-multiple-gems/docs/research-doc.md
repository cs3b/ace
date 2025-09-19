Migration Plan: ACE Monorepo

🎯 Purpose

Transform ACE from its current mixed directory structure into a single monorepo where:
	•	Each package is a Ruby gem at the repo root (ace-* prefix).
	•	Shared docs & ADRs stay under docs/.
	•	Config and markdown discovery works via .ace/ (nearest/deepest wins).
	•	Tools (git-*, handbook, context, etc.) ship as executables inside their gem.
	•	Agents and humans interact with the same deterministic CLI surface.

This makes ACE modular, testable, and extendable while eliminating duplication (tools/ folder) and submodule complexity.

⸻

📦 Final Repo Layout

ace-meta/
├── ace-core/              # gem: shared primitives, config resolver, plugin API
│   ├── lib/ace/core/...
│   ├── exe/ace-core
│   ├── ace-core.gemspec
│   └── README.md
├── ace-handbook/          # gem: workflows, guides, templates, handbook CLI
│   ├── lib/ace/handbook/...
│   ├── exe/handbook
│   ├── ace-handbook.gemspec
│   └── README.md
├── ace-context/           # gem: context loaders, presets, load-context CLI
│   ├── lib/ace/context/...
│   ├── exe/context
│   ├── ace-context.gemspec
│   └── README.md
├── ace-git/               # gem: enhanced git-* tools
│   ├── lib/ace/git/...
│   ├── exe/git-*
│   ├── ace-git.gemspec
│   └── README.md
├── .ace/                  # meta-level config (scanned upward to $HOME)
│   ├── core/.config/*.yml
│   ├── handbook/{workflows,guides,templates,.config/*.yml}
│   └── context/{workflows,.config/*.yml}
├── docs/                  # architecture, blueprint, ADRs, migrations
│   ├── blueprint.md
│   ├── architecture.md
│   ├── decisions/
│   └── migrations/
├── Gemfile                # bundles all local gems via path:
└── README.md


⸻

🔑 Package Responsibilities

ace-core
	•	ATOM primitives (logging, path validation, caching, usage tracking).
	•	Config & markdown resolver (deepest wins, layered overrides).
	•	Plugin system for other gems.
	•	Shared CLI helpers.

ace-handbook
	•	CLI: handbook.
	•	Workflows (.wf.md), guides, templates.
	•	Template sync + self-containment checks.

ace-context
	•	CLI: context.
	•	Presets and loaders.
	•	Implements /load-context flow.

ace-git
	•	CLI: git-* (commit, add, push, etc.) ￼.
	•	Git workflow automation, commit intention, enhanced status/log.

⸻

⚙️ Config & Markdown Resolution
	1.	Search order (deepest → shallowest):
	•	./.ace/<pkg>/**
	•	./.ace/core/**
	•	~/.ace/<pkg>/**
	•	~/.ace/core/**
	•	gem defaults
	2.	Rules:
	•	YAML configs: deep-merge (append or replace for arrays).
	•	Markdown: nearest wins, unless extends: is set.
	3.	Ownership: Implemented once in ace-core; reused everywhere.

⸻

🛠 Migration Phases

Phase 0 – Inventory & Freeze (Day 0–1)
	•	Snapshot dev-handbook/, dev-tools/, dev-taskflow/, docs/.
	•	Mark read-only directories (decisions/, migrations/, completed tasks).

Phase 1 – Scaffold Gems (Day 1–2)
	•	Create ace-core gem:
	•	Move atoms/molecules/organisms (logging, security, cache, usage).
	•	Add config/markdown resolver + tests.
	•	Create ace-handbook gem:
	•	Move workflows, guides, templates, handbook CLI.
	•	Create ace-context gem:
	•	Move context presets + loaders.
	•	Create ace-git gem:
	•	Move Git CLI wrappers (git-commit, git-status, etc.).

Phase 2 – Delete Legacy tools/ (Day 3)
	•	Remove root dev-tools/.
	•	Replace with exe/ inside gems.

Phase 3 – Compatibility Shims (Optional, Day 3–4)
	•	Keep thin bin/ wrappers for old paths.
	•	Print deprecation warnings.

Phase 4 – Docs Refresh (Day 4–5)
	•	Update docs/blueprint.md to describe flat monorepo ￼.
	•	Update docs/architecture.md for new structure ￼.
	•	Record ADR: “Monorepo with flattened ace-* gems.”
	•	Add migration record to docs/migrations/.

Phase 5 – CI & Testing (Day 5–7)
	•	Setup RSpec per gem (unit, integration, CLI, security) ￼.
	•	Add aruba CLI tests for end-to-end commands.
	•	Ensure ≤200ms startup (Zeitwerk autoload).

Phase 6 – Release & Adoption (Ongoing)
	•	Use Bundler path: gems in development.
	•	Optionally publish gems to RubyGems (same repo, multiple gems).
	•	Train agents to use flattened command suite (handbook, git-*, context, etc.).

⸻

🚦 Success Criteria
	•	✅ All CLI commands still work, now shipped from exe/ in their gem.
	•	✅ .ace/ discovery yields correct (nearest) config & markdown.
	•	✅ Docs (blueprint, architecture, ADRs) describe new structure.
	•	✅ Startup time ≤200ms; caching and cost tracking preserved ￼.
	•	✅ Agents and humans see a flat, predictable repo:
	•	ace-* = gem
	•	docs/ = meta reference
	•	.ace/ = config & workflows

⸻

📌 Open Decisions
	•	Umbrella binary (ace) vs per-package binaries?
→ Start per-package for clarity; add umbrella later if needed.
	•	Versioning: one version for all gems vs independent?
→ Independent versions recommended, but tag repo releases for alignment.
	•	Array merging: default append, allow per-key override.

