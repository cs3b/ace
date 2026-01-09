---
id: v.0.9.0+task.150.25
status: done
priority: medium
estimate: 20m
dependencies:
- v.0.9.0+task.150.15
parent: v.0.9.0+task.150
---

# Verify ace-docs: Base class adoption & help

## Scope

Verify ace-docs Base class adoption & CLI help standardization. If issues found, propose solution → get user approval → fix → re-verify.

## Verification Checklist

- [ ] `class CLI < Ace::Core::CLI::Base` (not Thor directly)
- [ ] No redundant class_options (quiet/verbose/debug inherited from Base)
- [ ] No redundant `exit_on_failure?` method (inherited from Base)
- [ ] `long_desc` with SYNTAX, EXAMPLES, CONFIGURATION, OUTPUT sections
- [ ] `self.help` override with package-specific examples
- [ ] `--version` mapped (no `-v` alias)

## Manual Tests

```bash
./bin/ace-docs --help              # Should show full help with examples
./bin/ace-docs --version           # Should show "ace-docs X.X.X"
./bin/ace-docs -v                  # Should trigger verbose (NOT version)
./bin/ace-docs status              # Should show doc status
./bin/ace-docs update --set last-updated=today
```

## Automatic Tests

```bash
cd ace-docs && ace-test
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