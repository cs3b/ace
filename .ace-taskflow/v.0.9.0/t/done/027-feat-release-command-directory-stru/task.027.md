---
id: v.0.9.0+task.027
status: done
estimate: 4h
dependencies: []
sort: 963
---

# Add release create command with directory structure

## Description

Implement a `release create` subcommand for ace-taskflow that creates a new release with proper directory structure, similar to the old release-manager create-release-dir command.

## Planning Steps

* [x] Study existing release directory structures
* [x] Design version auto-increment logic
* [x] Plan release metadata template

## Execution Steps

* [x] Modify `ace-taskflow/lib/ace/taskflow/commands/release_command.rb`
  * [x] Add create subcommand handling
  * [x] Parse release name and version options
  * [x] Add `--backlog` (default) and `--current` flags
* [x] Create `ace-taskflow/lib/ace/taskflow/organisms/release_creator.rb`
  * [x] Implement directory structure creation:
    * [x] `[release-dir]/t/` (tasks)
    * [x] `[release-dir]/ideas/`
    * [x] `[release-dir]/docs/`
    * [x] `[release-dir]/retro/` (retrospectives)
    * [x] `[release-dir]/[release-name].md` (overview file)
  * [x] Auto-increment version if not specified
  * [x] Generate release overview markdown file
* [x] Update release resolver to recognize new releases
* [x] Add validation for duplicate releases
* [ ] Create tests for release creation

## Acceptance Criteria

* [x] `ace-taskflow release create "feature-name"` creates release with next version
* [x] `ace-taskflow release create "feature-name" --release v.0.12.0` uses specified version
* [x] `--backlog` flag creates in backlog directory (default)
* [x] `--current` flag creates as active release
* [x] Directory structure matches existing release format
* [x] Release overview file contains metadata and description
* [x] Command prevents duplicate version numbers

## Implementation Notes

Release structure based on `.ace-taskflow/done/v.0.4.0-replanning/`:
* Standard folders: t/ (tasks), ideas/, docs/, retro/ (retrospectives)
* Overview file named `v.X.Y.Z-release-name.md`
* Version format: v.MAJOR.MINOR.PATCH
