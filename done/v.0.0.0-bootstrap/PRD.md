# Coding Agent Tools Ruby Gem — Product Requirements Document (PRD)

| **Document Info** |                                                                                                    |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| **Author**        | Michał Czyż                                                                                        |
| **Stakeholders**  | CS3B Dev Tools Guild, AI Platform Team, Developer Experience (DX) │ Security │ Release Engineering |
| **Date**          | 30 May 2025                                                                                        |
| **Version**       | v0.1 (Draft)                                                                                       |

---

## 1  Purpose

Provide a Ruby gem—**Coding Agent Tools (CAT)**—that enables AI‑assisted developers and autonomous coding agents to interact seamlessly with local projects, Git repositories, and task backlogs. CAT exposes predictable CLI commands (executables & binstubs) and a programmable API to off‑load routine Dev Ops chores—querying LLMs, generating commit messages, creating repositories, and navigating task queues—freeing humans and agents to focus on higher‑value design work.

## 2  Problem Statement

Modern coding agents (Google Gemini, LM Studio, GitHub Copilot Agents) can write code but still struggle with environment orchestration: setting up remotes, crafting atomic commits, or locating the next actionable task. Engineers today glue together custom scripts with inconsistent conventions. We need an **opinionated, test‑driven toolkit** that standardises these workflows so that:

* Humans & agents share the same commands → less context drift.
* Tasks remain traceable in Git history → cleaner reviews & audits.
* Repositories spin up in seconds → smoother project kick‑off.

## 3  Goals & Non‑Goals

| Goals                                                                                   | Non‑Goals                                              |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 🟢 Offer a Ruby gem installable via `gem install coding_agent_tools` or Bundler.        | ⛔ Provide cross‑language SDKs (Python/Go/etc.) in v1.  |
| 🟢 Ship CLI executables with ergonomic flags for both agents and humans.                | ⛔ Replace full‑featured Git GUIs or ticketing systems. |
| 🟢 Adhere to ATOM architecture; 100 % coverage of unit & integration tests using RSpec. | ⛔ Implement proprietary LLM endpoints (OpenAI) in v1.  |
| 🟢 Support offline workflows via LM Studio local models.                                | ⛔ Real‑time collaborative editing features.            |

## 4  Success Metrics (v1 Launch)

1. **Time‑to‑Commit**: Reduce median time from code change to committed diff by **30 %** within pilot team.
2. **Agent Adoption**: ≥ 80 % of automated CI runs invoke at least one CAT command.
3. **Support Load**: ≤ 2 support tickets/week related to Git setup or task selection after 1 month.
4. **Reliability**: CLI commands succeed ≥ 99 % over 1,000 automated invocations.

## 5  Personas

| Persona                    | Needs                                                          | Pain Points                                         |
| -------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| **Alex – AI Coding Agent** | Deterministic CLI surface to perform Dev Ops steps.            | Unstructured shell scripts cause brittle runs.      |
| **Sam – Senior Dev**       | Rapidly set up new project remotes, craft descriptive commits. | Forgetting push URLs, writing poor commit messages. |
| **Priya – DX Engineer**    | Testable, extendable framework following Ruby best practices.  | Ad‑hoc tools lack tests & design principles.        |

## 6  User Stories

1. *As an agent,* I want to call `llm-gemini-query --prompt "How to optimise Ruby IO?"` and receive JSON so I can embed responses in code comments.
2. *As a developer,* I want `git-commit-with-message --intention "refactor"` to stage files and generate a concise commit message from the diff.
3. *As an agent,* I want `tn` to emit the next unblocked task so I can start coding immediately.
4. *As release automation,* I want `rc` to print the current release directory so new tasks land in the right location.

## 7  Functional Requirements

### 7.1  Communication with LLMs

|  ID     | Requirement                                                                                                                                      | Priority |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| R‑LLM‑1 | **`llm-gemini-query`** shall accept a prompt string or file, call Google Gemini (model v1.5 Pro), and return the response as plain text or JSON. | P1       |
| R‑LLM‑2 | The command shall support API‑key discovery via ENV `GEMINI_API_KEY` and `~/.gemini/config`.                                                     | P1       |
| R‑LLM‑3 | **`lms-studio-query`** shall interface with LM Studio on `localhost:1234` using the server’s REST protocol for offline inference.                | P2       |
| R‑LLM‑4 | Both commands shall expose a `--model` flag to override default models.                                                                          | P2       |

### 7.2  Git Workflows

|  ID      | Requirement                                                                                                                                                         | Priority |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| R‑GIT‑1  | **`github-repository-create`** shall create a private GitHub repo via REST v3, set it as `origin`, and push the current branch.                                    | P1       |
| R‑GIT‑2  | The command shall honour `GITHUB_TOKEN` env for authentication.                                                                                                     | P1       |
| R‑GIT‑3  | **`git-commit-with-message`** shall generate a commit message using the diff, intention, and optional instructions via the LLM.                                     | P1       |
| R‑GIT‑4  | `git-commit-with-message` shall support modes: `--all` (stage all), `--staged` (default), or specific files/globs (`--files file1.rb *.txt`).                       | P1       |
| R‑GIT‑5  | `git-commit-with-message` shall provide a `--dry-run` option to preview the generated message without committing.                                                     | P2       |
| R‑GIT‑6  | **`bin/gs`** (Git Status) shall be a wrapper for `git status`, defaulting to a short format with an option for verbose output.                                       | P1       |
| R‑GIT‑7  | **`bin/gl`** (Git Log) shall be a wrapper for `git log`, replicating a format similar to `git log --oneline --decorate --color`.                                      | P1       |
| R‑GIT‑8  | **`bin/gp`** (Git Push) shall be a wrapper for `git push`, passing arguments directly to the underlying Git command.                                                | P1       |
| R‑GIT‑9  | `git-commit-with-message` shall use an LLM (selectable, e.g., Gemini or local via LM Studio helper scripts) to generate messages, reading API keys from ENV.         | P1       |
| R‑GIT‑10 | `git-commit-with-message` shall allow the user to edit the LLM-generated commit message by default and provide a `--no-edit` flag to commit directly.                 | P1       |

### 7.3  Task Utilities

|  ID      | Requirement                                                                                                                                                         | Priority |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| R‑TASK‑1 | **`tr`** shall list recently updated or completed tasks across current & completed releases, respecting `--last N` filter.                                          | P1       |
| R‑TASK‑2 | **`tn`** shall output the next actionable task with all dependencies resolved.                                                                                        | P1       |
| R‑TASK‑3 | **`rc`** shall return the release directory path & version string, or backlog path if none.                                                                           | P1       |
| R‑TASK‑4 | All utilities shall source data via `dev-tools/exe-old/*` scripts and return JSON when `--json` flag is passed.                                                          | P2       |
| R‑TASK‑5 | `tr` shall allow users to specify input scope for searching tasks using file paths, directory paths, or glob patterns if applicable to task storage methods.         | P2       |
| R‑TASK‑6 | `tn` shall allow users to specify input scope for searching tasks using file paths, directory paths, or glob patterns if applicable to task storage methods.         | P2       |

### 7.4  Context Hydration Utilities

|  ID     | Requirement                                                                                                                                                              | Priority |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| R‑CTX‑1 | **`bin/context`** shall generate a single, comprehensive context document for a specific task or prompt.                                                                 | P1       |
| R‑CTX‑2 | The tool shall scan Markdown files, follow internal links, and gather related information including relevant tool calling examples.                                          | P1       |
| R‑CTX‑3 | The output shall be a single Markdown file containing a summary at the top, followed by the embedded content of gathered documents and tool call responses, with links back to original sources. | P1       |
| R‑CTX‑4 | An LLM (e.g., Gemini Flash Lite) shall be used to compact or summarize key information, especially for the summary section.                                                | P1       |
| R‑CTX‑5 | `bin/context` shall allow users to specify input scope using file paths, directory paths, or glob patterns to refine context gathering.                                    | P2       |

### 7.5  Markdown Utilities

|  ID    | Requirement                                                                                                                                                              | Priority |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| R‑MD‑1 | **`bin/lint`** shall include capabilities for linting Markdown documents, specifically checking for broken links, incorrect relative paths, and other format/path issues.   | P1       |
| R‑MD‑2 | The linter shall report errors and warnings, with an improved output format including a final summary of issues per file, overall counts, and initially detailed errors for a limited set of files. | P2       |
| R‑MD‑3 | `bin/lint` shall provide an `--autofix` option to attempt automatic correction of certain identified Markdown issues.                                                      | P2       |
| R‑MD‑4 | `bin/lint` shall allow users to specify input scope using file paths, directory paths, or glob patterns.                                                                   | P1       |

### 7.6  Task Creation Utilities

|  ID     | Requirement                                                                                                                                                              | Priority |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| R‑TCI‑1 | **`bin/tci`** (Task Capture Idea) shall accept a command-line parameter representing the user's intention or core idea for a new task.                                    | P1       |
| R‑TCI‑2 | The tool shall load project environment context and use an LLM to process the intention, expanding it based on a predefined template.                                      | P1       |
| R‑TCI‑3 | The LLM-generated output, formatted by the template, shall be saved as a new Markdown file in `dev-taskflow/backlog/ideas/`.                                               | P1       |
| R‑TCI‑4 | A guide document (`dev-handbook/guides/how-to-capture-ideas.guide.md`) shall be created to detail the usage of `bin/tci`.                                                      | P2       |
| R‑TCI‑5 | `bin/tci` shall allow specifying a scope (file/folder/glob) for project context loading if applicable to refine the context provided to the LLM.                           | P2       |

## 8  Non‑Functional Requirements

* **Language & Runtime**: Ruby ≥ 3.2, MRI‑only in v1.
* **Architecture**: Conform to ATOM (Action, Transformation, Operation, Model) pattern for maintainability.
* **Testing**: ≥ 95 % line coverage; RSpec as the default framework.
* **CLI UX**: ≤ 200 ms startup latency; helpful `--help` docs for every command.
* **Security**: No plaintext secrets in logs; GitHub tokens & API keys read from ENV or macOS keychain.
* **Observability**: Emit structured logs (JSON) to stdout; support `--verbose` for debug.

## 9  Technical Architecture

```mermaid
flowchart TD
    subgraph Ruby Gem (CAT)
        direction TB
        CLI[Executables / bin/*]
        ServiceObjects[🔧 Service Objects]
        Adapters[🌐 Adapters]
        Models[(Data Models)]
    end
    CLI --> ServiceObjects --> Adapters
    Adapters -->|Gemini REST| GeminiAPI((Google Gemini))
    Adapters -->|LM Studio| LMStudio((Local Model))
    Adapters -->|Git CLI / GitHub API| GitHub((GitHub))
    ServiceObjects --> Models
```

*Each ATOM component lives under `lib/coding_agent_tools/` with explicit boundaries and dependency injection for easy testing.*

## 10  Testing Strategy

| Layer       | Responsibility                             | Tooling            |
| ----------- | ------------------------------------------ | ------------------ |
| Unit        | Pure functions (Transformations, Models)   | RSpec + FactoryBot |
| Integration | Adapters hitting stubbed external services | RSpec + VCR        |
| CLI         | Behaviour of executables                   | Aruba              |
| Contract    | JSON schemas for LLM & GitHub responses    | JSON Schema RSpec  |

CI pipeline (GitHub Actions) runs on pushes & PRs; required checks: `rspec`, `rubocop`, `yard‑docs`.

## 11  Milestones & Timeline

| Date        | Milestone                                                      |
| ----------- | -------------------------------------------------------------- |
| 13 Jun 2025 | Architectural spike complete; baseline gem skeleton generated. |
| 27 Jun 2025 | LLM communication commands GA (Gemini & LM Studio).            |
| 11 Jul 2025 | GitHub repo creation + commit generator ready.                 |
| 01 Aug 2025 | Task utilities implemented; beta release `v0.9.0`.             |
| 15 Aug 2025 | Hardening, docs, 100 % RSpec pass; Release Candidate.          |
| 29 Aug 2025 | v1.0.0 stable published to RubyGems.                           |

## 12  Analytics & Telemetry

* Opt‑in anonymous usage collection (CLI arg `--analytics`) capturing command name, duration, exit code.
* Metrics shipped via HTTPS to internal Snowplow collector; analysed in Looker.

## 13  Dependencies

* Google Gemini API access (billing enabled).
* Local LM Studio installation on dev machines.
* GitHub App with repo‑create scope.
* Ruby 3.2 runtime in CI & dev containers.
* `dev-tools/exe-old/*` scripts present in codebase.

## 14  Risks & Mitigations

| Risk                              | Impact                  | Probability | Mitigation                                     |
| --------------------------------- | ----------------------- | ----------- | ---------------------------------------------- |
| LLM rate limits slow commits.     | Frustrated users.       | Medium      | Bulk prompt caching; exponential back‑off.     |
| Local model API changes.          | Offline mode breaks.    | Low         | Integration contract tests; version pinning.   |
| GitHub API deprecations.          | Repo creation fails.    | Medium      | Monitor changelog; ship patches within 48 h.   |
| Security mis‑config leaks tokens. | High severity incident. | Low         | Secrets scanner in CI; docs on keychain usage. |

## 15  Out of Scope (v1)

* Multi‑language bindings (Python, Go).
* GUI dashboards.
* Advanced prompt‑engineering helpers.

## 16  Open Questions

1. Should we provide a Rubocop plugin to auto‑enforce ATOM directory boundaries?
2. Will agents require streaming LLM responses, or is full‑reply sufficient?
3. Do we need encrypted local storage for cached prompts/results?
4. Should we namespace the gem as `ca-tools` or keep full name `coding_agent_tools`?

---

*End of Document*
