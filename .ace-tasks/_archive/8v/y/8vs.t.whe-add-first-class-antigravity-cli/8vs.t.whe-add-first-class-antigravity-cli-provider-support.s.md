---
id: 8vs.t.whe
status: done
priority: medium
created_at: "2026-08-29 21:39:20"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [ace-llm-providers-cli/, ace-handbook/]
  commands: [ace-test ace-llm-providers-cli, ace-test ace-handbook]
needs_review: false
---

# Add first-class Antigravity CLI provider support

## Objective

Give ACE users a first-class `agy` provider that invokes the verified public Antigravity CLI contract safely and consistently alongside existing CLI-backed LLM providers, including appropriate handbook projections.

Source: [GitHub issue #319](https://github.com/cs3b/ace/issues/319).

The issue lifecycle field could not be set because `ace-task` requires live authenticated GitHub validation; this assignment must not authenticate to or mutate GitHub.

## Behavioral Specification

Users select provider identifier `agy`, supply a prompt and supported model/session inputs, and receive the normal provider result. ACE builds the invocation from verified public evidence, uses established CLI-provider execution/diagnostics, and exposes Antigravity consistently in handbook surfaces.

Expected behavior:

- `ace-llm-providers-cli` recognizes Antigravity as a first-class provider.
- Arguments and output handling match installed `agy --help` when available or current primary/public evidence; uncertainty is explicit.
- Tests use a fake executable only and never authenticate or execute a real `--dangerously-skip-permissions` operation.
- Appropriate `ace-handbook` projections include Antigravity.

## Interface Contract

Provider identifier: `agy`. The exact command must be derived from current public evidence before implementation. Missing executable and non-zero fake CLI exits follow sibling-provider error behavior. Prompts remain distinct argv values and are never shell-evaluated. Unsupported options are rejected explicitly, without aliases, legacy fallbacks, or guessed alternate flags.

## Scope of Work

- Add `agy` discovery/configuration and invocation behavior.
- Add deterministic fake-CLI tests for exact argv, success, and failure paths.
- Update appropriate handbook projections and usage documentation.
- Prepare local package versions/changelogs required by release workflow.
- Provide a deterministic fixture-based demo scenario.

## Out of Scope

Authentication, real dangerous permission bypass, publishing, deployment, CI changes, production release activity, and compatibility for unverified historical flags.

## Success Criteria

- [ ] `agy` is discoverable and usable as a first-class CLI provider.
- [ ] Generated arguments match verified public behavior and uncertainty is explicit.
- [ ] Fixture tests cover exact argv, success, invalid/missing behavior as fit, and non-zero failure.
- [ ] No test authenticates or invokes a real dangerous permission operation.
- [ ] Appropriate handbook projections and usage docs include Antigravity.
- [ ] A deterministic fixture-based demo exercises the provider.
- [ ] Modified-package tests pass through `ace-test`; repository verification passes through `ace-test-suite`.
- [ ] Local release preparation and valid/fit/shine review cycles finish.
- [ ] Final diff contains no Lab overlay/runtime artifacts.
- [ ] Only the builder branch is pushed; an open Forgejo PR links issue #319 and records exact final SHA and evidence.

## Documentation Impact

Update provider listings, configuration/usage examples, canonical projections, and changelogs in `ace-llm-providers-cli` and relevant `ace-handbook` surfaces. Record public-contract evidence and uncertainty.

## Demo Scenario

Run against a fixture `agy` executable that records argv and returns a deterministic response. Demonstrate selection, supported arguments, output capture, and non-zero failure without authentication.

## Vertical Slice Decomposition

Standalone, medium slice delivering configuration through fixture execution and handbook projection.

## Verification Plan

- Unit/component: exact fixture argv/output and registry/configuration behavior.
- Integration: fixture-backed provider demo and handbook projection consistency.
- Failure: missing executable, non-zero exit, and unsupported options.
- Commands: `ace-test ace-llm-providers-cli`, `ace-test ace-handbook`, `ace-test-suite`.

## Validation Questions

- Which prompt, model, output, and permission flags does current public `agy` support? Resolve from primary evidence before coding.
- Which handbook files are canonical sources versus generated projections?
