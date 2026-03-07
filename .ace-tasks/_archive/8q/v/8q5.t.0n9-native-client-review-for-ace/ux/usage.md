# Native Client Review for Subtree Pre-Commit - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Automatic Pre-Commit Review in Subtree Workflow

**Goal**: Changes are automatically reviewed before commit during subtree execution

```
# During ace-assign work-on subtree execution:

# [Phase: pre-commit-review]
# Detected provider: claude (native review available)
# Running native review on 5 changed files...
#
# Review findings:
#   WARNING lib/foo.rb:15 - Consider extracting method (complexity)
#   INFO    lib/bar.rb:42 - Unused import
#
# 2 findings (0 critical, 1 warning, 1 info)
# Proceeding to commit...
```

### Scenario 2: Disable Pre-Commit Review

**Goal**: Skip the review step when speed is more important

```yaml
# .ace/assign/config.yml
subtree:
  pre_commit_review: false
```

```
# During subtree execution:
# (no review phase - proceeds directly to commit)
```

### Scenario 3: Block Commit on Critical Findings

**Goal**: Prevent committing code with critical review findings

```yaml
# .ace/assign/config.yml
subtree:
  pre_commit_review_block: true
```

```
# During subtree execution:
# Review findings:
#   CRITICAL lib/auth.rb:23 - SQL injection vulnerability
#
# 1 critical finding - commit blocked.
# Address the finding and retry.
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
