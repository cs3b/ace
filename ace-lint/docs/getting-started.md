* * *

doc-type: user title: Getting Started with ace-lint purpose: Documentation for ace-lint/docs/getting-started.md
ace-docs: last-updated: 2026-03-22 last-checked: 2026-03-22 ---

# Getting Started with ace-lint

Use `ace-lint` when you want one Ruby-native lint command for markdown, YAML, Ruby, and frontmatter.

## Prerequisites

* Ruby 3.2+
* Optional Ruby validator tools:
  * `standardrb` (recommended)
  * `rubocop` (fallback)

Install gem:

    gem install ace-lint
{: .language-bash}

## Installation

If developing in this monorepo, install dependencies at repo root:

    bundle install
{: .language-bash}

## Lint your first file

Markdown:

    ace-lint README.md
{: .language-bash}

YAML:

    ace-lint .ace/config.yml --type yaml
{: .language-bash}

Ruby:

    ace-lint lib/example.rb --type ruby
{: .language-bash}

## Auto-fix mode

Deterministic auto-fix (then re-lint):

    ace-lint README.md lib/example.rb --auto-fix
{: .language-bash}

Preview without modifying files:

    ace-lint README.md --auto-fix --dry-run
{: .language-bash}

Agent-assisted fix for remaining issues:

    ace-lint README.md --auto-fix-with-agent --model gemini:flash-latest
{: .language-bash}

## Configuration basics

Configuration cascade (highest to lowest):

1.  CLI options
2.  Project config: `.ace/lint/config.yml`
3.  User config: `~/.ace/lint/config.yml`
4.  Gem defaults: `ace-lint/.ace-defaults/lint/config.yml`

## Validate Claude Code files

Lint skill files, workflows, and agent markdown just like other docs:

    ace-lint handbook/skills/as-lint-run/SKILL.md
    ace-lint handbook/workflow-instructions/lint/run.wf.md
{: .language-bash}

## Common Commands

| Command | What it does |
|----------
| `ace-lint README.md` | Auto-detect type and lint |
| `ace-lint file.md --auto-fix` | Deterministic auto-fix, then re-lint |
| `ace-lint file.md --auto-fix --dry-run` | Preview fixes without writing |
| `ace-lint file.md --auto-fix-with-agent` | Auto-fix and escalate remaining issues to agent |
| `ace-lint file.rb --type ruby` | Force Ruby linting |
| `ace-lint --validators standardrb,rubocop **/*.rb` | Use explicit Ruby validators |
| `ace-lint --doctor` | Diagnose config and validator health |
| `ace-lint --doctor-verbose` | Full diagnostics output |

## Next steps

* [Usage Guide](usage.md) - full option and flag reference
* [Handbook Reference](handbook.md) - package skills and workflows
* Use `--doctor` when validator detection or config behavior is unclear
