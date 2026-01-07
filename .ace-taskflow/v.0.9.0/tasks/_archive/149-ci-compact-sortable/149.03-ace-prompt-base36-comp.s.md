---
id: v.0.9.0+task.149.03
status: done
priority: high
estimate: 4h
dependencies:
- v.0.9.0+task.149.01
parent: v.0.9.0+task.149
worktree:
  branch: 149.03-migrate-ace-prompt-to-base36-compact-ids
  path: "../ace-task.149.03"
  created_at: '2026-01-06 18:22:46'
  updated_at: '2026-01-06 18:22:46'
---

# Migrate ace-prompt to Base36 Compact IDs

## Objective

Update ace-prompt to use the new ace-support-timestamp package for generating Base36 compact IDs (6 characters) for prompt session directories. Ensure dual-format detection for existing timestamp-based sessions.

## Behavioral Specification

### User Experience

**Before**: Session directories named `session-20251117-231038/`
**After**: Session directories named `session-000000/` (with year_zero=2000)

**Existing Behavior**: Existing timestamp sessions continue to work

### Expected Behavior

**New Sessions**:
- Default to Base36 compact ID format
- Use ace-support-timestamp CompactIdEncoder
- Generate 6-character lowercase IDs

**Existing Sessions**:
- Dual-format detection recognizes both formats
- No migration required
- Read/load operations work transparently

### Interface Contract

```ruby
# TimestampGenerator uses new encoder
result = Ace::Prompt::Atoms::TimestampGenerator.call
# => { timestamp: "000000" }  # Base36 format
```

### Success Criteria

- [ ] New sessions use 6-character Base36 IDs
- [ ] Existing timestamp sessions still load correctly
- [ ] Config defaults updated
- [ ] Tests pass for both formats

## Scope of Work

### Deliverables

#### Modify

- `lib/ace/prompt/atoms/timestamp_generator.rb`
  - Add ace-support-timestamp dependency
  - Use CompactIdEncoder.encode()

- `.ace-defaults/prompt/config.yml`
  - Add format configuration

- `lib/ace/prompt.gemspec`
  - Add dependency: `ace-support-timestamp ~> 0.1`

## Out of Scope

- ❌ Migrating existing session directories

## References

- Parent task: 149 (orchestrator)
- Dependency: 149.01 (ace-support-timestamp package)
