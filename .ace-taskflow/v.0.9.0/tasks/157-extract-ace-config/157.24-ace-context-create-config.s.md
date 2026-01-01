---
id: v.0.9.0+task.157.24
status: done
priority: low
estimate: 1h
dependencies:
- v.0.9.0+task.157.11
parent: v.0.9.0+task.157
---

# ace-context - Create Config File

## Objective

Create `.ace-defaults/context/config.yml` with cache_dir and chunk_limit settings.

## Current Issues

Hardcoded values in:
- `molecules/context_file_writer.rb:13-14`:
  - DEFAULT_CACHE_DIR=".cache/ace-context"
  - DEFAULT_CHUNK_LIMIT=150,000

## Scope of Work

### Files to Create

- `ace-context/.ace-defaults/context/config.yml`

### Files to Modify

- `ace-context/lib/ace/context/molecules/context_file_writer.rb`
- `ace-context/lib/ace/context.rb` - Add config loading if not present

## Implementation Plan

### Execution Steps

- [x] Create .ace-defaults/context/config.yml
  ```yaml
  context:
    cache_dir: ".cache/ace-context"
    chunk_limit: 150000
  ```

- [x] Update context_file_writer.rb to read from config
  > Replace DEFAULT_CACHE_DIR constant with config lookup
  > Replace DEFAULT_CHUNK_LIMIT with config lookup

- [x] Ensure ace-context has config loading (may already have it via presets)

- [x] Run tests with `ace-test ace-context`

- [x] Bump patch version

## Acceptance Criteria

- [x] .ace-defaults/context/config.yml created
- [x] cache_dir and chunk_limit configurable
- [x] All ace-context tests pass
- [x] Gem version bumped
