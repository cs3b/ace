---
id: v.0.9.0+task.150.29
status: done
priority: medium
estimate: 20m
dependencies:
- v.0.9.0+task.150.15
parent: v.0.9.0+task.150
---

# Verify ace-prompt: Base class adoption & help

## Scope

Verify ace-prompt Base class adoption & CLI help standardization. If issues found, propose solution → get user approval → fix → re-verify.

## Verification Checklist

- [ ] `class CLI < Ace::Core::CLI::Base` (not Thor directly)
- [ ] No redundant class_options (inherited from Base)
- [ ] No redundant `exit_on_failure?` method (inherited from Base)
- [ ] Default command routing (file-like args → main command)
- [ ] `long_desc` with SYNTAX, EXAMPLES, CONFIGURATION, OUTPUT sections
- [ ] `self.help` override with package-specific examples
- [ ] `--version` mapped (no `-v` alias)

## Manual Tests

```bash
./bin/ace-prompt --help              # Should show full help
./bin/ace-prompt --version           # Should show "ace-prompt X.X.X"
./bin/ace-prompt -v                  # Should trigger verbose (NOT version)
./bin/ace-prompt setup --task 150    # Setup prompt for task
```

## Automatic Tests

```bash
cd ace-prompt && ace-test
```

## Remediation Process

If any verification check fails:

1. **Document the issue**: What check failed and what the actual behavior is
2. **Propose solution**: Describe the fix needed
3. **Get user approval**: Present proposal and wait for approval
4. **Implement fix**: Make the code changes
5. **Re-verify**: Run tests and manual checks again

## Acceptance Criteria

- [ ] All verification checks pass
- [ ] All manual tests produce expected output
- [ ] All automatic tests pass
- [ ] No issues found OR all issues found and fixed