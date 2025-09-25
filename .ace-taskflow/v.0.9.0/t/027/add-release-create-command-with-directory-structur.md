---
id: v.0.9.0+task.027
status: pending
priority: medium
estimate: 4h
dependencies: []
sort: 977
---

# Add release create command with directory structure

## Description

Implement a `release create` subcommand for ace-taskflow that creates a new release with proper directory structure, similar to the old release-manager create-release-dir command.

## Planning Steps

* [ ] Study existing release directory structures
* [ ] Design version auto-increment logic
* [ ] Plan release metadata template

## Execution Steps

- [ ] Modify `ace-taskflow/lib/ace/taskflow/commands/release_command.rb`
  - [ ] Add create subcommand handling
  - [ ] Parse release name and version options
  - [ ] Add `--backlog` (default) and `--current` flags
- [ ] Create `ace-taskflow/lib/ace/taskflow/organisms/release_creator.rb`
  - [ ] Implement directory structure creation:
    - [ ] `[release-dir]/tasks/`
    - [ ] `[release-dir]/ideas/`
    - [ ] `[release-dir]/docs/`
    - [ ] `[release-dir]/reflections/`
    - [ ] `[release-dir]/[release-name].md` (overview file)
  - [ ] Auto-increment version if not specified
  - [ ] Generate release overview markdown file
- [ ] Update release resolver to recognize new releases
- [ ] Add validation for duplicate releases
- [ ] Create tests for release creation

## Acceptance Criteria

- [ ] `ace-taskflow release create "feature-name"` creates release with next version
- [ ] `ace-taskflow release create "feature-name" --release v.0.12.0` uses specified version
- [ ] `--backlog` flag creates in backlog directory (default)
- [ ] `--current` flag creates as active release
- [ ] Directory structure matches existing release format
- [ ] Release overview file contains metadata and description
- [ ] Command prevents duplicate version numbers

## Implementation Notes

Release structure based on `.ace-taskflow/done/v.0.4.0-replanning/`:
- Standard folders: tasks/, ideas/, docs/, reflections/
- Overview file named `v.X.Y.Z-release-name.md`
- Version format: v.MAJOR.MINOR.PATCH
