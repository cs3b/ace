---
name: release-publish
description: Release all modified ACE packages with coordinated package and root changelog updates
allowed-tools: Bash, Read, Edit
argument-hint: package-name... bump-level
doc-type: workflow
purpose: coordinated multi-package release workflow
update:
  update_frequency: on-change
  frequency: on-change
  last-updated: '2026-03-08'
---

# ACE Publish Release Workflow

## Goal

Release every modified ACE package in one pass, update each package version and changelog, update the root
`CHANGELOG.md` once, and create one coordinated release commit.

## Prerequisites

* Repository root contains the target `ace-*` packages
* Implementation and verification work is already complete
* Each target package has exactly one `lib/**/version.rb` file and a package `CHANGELOG.md`
* You understand Semantic Versioning and Keep a Changelog conventions

## Project Context Loading

* Read and follow: `ace-bundle project`
* Review the working tree: `git status --short`
* Load: Keep a Changelog and Semantic Versioning 2.0.0 specifications

## Process Steps

### 1. Resolve Inputs

Treat workflow arguments as:

* zero or more package names such as `ace-assign`
* optional global bump level: `patch`, `minor`, or `major`

Rules:

* If one of `patch|minor|major` is present, apply it to every selected package.
* If package names are present, release only those packages.
* If no package names are present, auto-detect packages from the current working tree.

### 2. Detect Target Packages

When auto-detecting, inspect all current changes:

```bash
git status --short
git diff --name-only
git diff --cached --name-only
git ls-files --others --exclude-standard
```

Include packages using these rules:

1. Any changed path starting with `ace-.../` contributes that top-level package.
2. A changed project config path `.ace/<namespace>/config.yml` contributes the package that owns
   `ace-*/.ace-defaults/<namespace>/config.yml`.
3. Deduplicate and sort the final package list.

Build the namespace owner map from gem defaults:

```bash
find ace-* -path '*/.ace-defaults/*/config.yml'
```

Interpret each match as:

* package: the first path segment
* namespace: the segment between `.ace-defaults/` and `/config.yml`

Examples:

* `.ace/assign/config.yml` -> `ace-assign`
* `.ace/task/config.yml` -> `ace-task`
* `.ace/e2e-runner/config.yml` -> `ace-test-runner-e2e`

Do not auto-select a package from:

* root `CHANGELOG.md`
* `Gemfile.lock`
* task specs or cache files
* a `.ace/<namespace>/...` path with no unique package owner

If no packages are found, stop and report:

```text
No releasable packages detected from the current diff. Pass package names explicitly or modify ace-* package files / uniquely owned .ace/<namespace>/config.yml files.
```

### 3. Validate Package Structure

For each target package, verify:

```bash
find ace-[package]/lib -name version.rb
[ -f "ace-[package]/CHANGELOG.md" ] && echo "✓ CHANGELOG.md"
```

Require exactly one `version.rb` match. If a package is missing `version.rb` or `CHANGELOG.md`, stop before
editing anything.

### 4. Determine Bump Level Per Package

If an explicit bump level was provided, use it for every package.

Otherwise choose a bump per package from the unreleased diff:

* `major`: explicit breaking changes only
* `minor`: new capability, new CLI flag, new config key, new workflow/skill behavior, or other
  backward-compatible feature expansion
* `patch`: fixes, compatibility adjustments, refactors, docs, tests, comments, and polish on existing behavior

Bias rules:

* In `release-minor`, prefer `minor` unless the diff is clearly fix-only.
* In review-cycle child phases (`release`, `release-patch-*`), prefer `patch` unless the diff clearly adds a new
  capability.

Record the decision before editing:

```text
ace-assign -> minor
ace-task -> patch
ace-test-runner-e2e -> minor
```

### 5. Update Each Package Release

For each package, in package order:

1. Read the current version from `version.rb`.
2. Calculate the next version using semver.
3. Update `version.rb`.
4. Add a new package `CHANGELOG.md` entry after `[Unreleased]`.
5. If the bump is `minor` or `major`, update any stale dependent gemspec `~>` constraints that now fall behind
   the new version.

Helpful checks:

```bash
rg -n "\"ace-[package]\"" ace-*/*.gemspec
ruby -c "$(find ace-[package]/lib -name version.rb)"
```

Package changelog categories:

* `Added`: new features
* `Fixed`: bug fixes
* `Changed`: behavior changes and refactors
* `Technical`: tests, docs, comments, and maintenance

### 6. Refresh the Workspace Lockfile

After all version and gemspec edits are complete:

```bash
bundle install
```

This updates the shared `Gemfile.lock` once for the coordinated release.

### 7. Update Root CHANGELOG Once

Add one new root `CHANGELOG.md` entry after `[Unreleased]`.

Versioning:

* Use the next root patch version after the current top entry.

Formatting rules:

* One root entry per `/as-release` invocation
* Include every released package and its new version
* Use bullets like `**ace-assign v0.22.8**: ...`
* Group bullets under Keep a Changelog headings: `Added`, `Fixed`, `Changed`, `Technical`

Do not create separate root changelog entries per package.

### 8. Commit the Coordinated Release

Commit all released package directories plus root release files in one commit:

```bash
ace-git-commit \
  ace-[package-a]/ \
  ace-[package-b]/ \
  CHANGELOG.md \
  Gemfile.lock \
  -i "release v[VERSION_A] for ace-[package-a] and v[VERSION_B] for ace-[package-b]"
```

Also include any additional package directories whose gemspecs changed due to dependency constraint updates.

### 9. Final Verification

Verify the final release surface:

```bash
git status --short
```

Checklist:

* every selected package has an updated `version.rb`
* every selected package has a new package changelog entry
* root `CHANGELOG.md` has one combined release entry
* `Gemfile.lock` reflects the new internal versions
* no unrelated package was released

## Notes

* `wfi://release/bump-version` remains the single-package helper.
* Use `/as-release` for coordinated multi-package releases.
* When no package arguments are supplied, package selection comes from the current diff rather than from user
  prompts.
