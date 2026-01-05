---
id: v.0.9.0+task.150.18
status: done
priority: medium
estimate: 30m
dependencies:
- v.0.9.0+task.150.15
parent: v.0.9.0+task.150
---

# Verify ace-llm: Thor migration

## Scope

Verify ace-llm Thor migration & CLI standardization. If issues found, propose solution → get user approval → fix → re-verify.

## Verification Checklist

- [ ] `lib/ace/llm/commands/` directory with command files exists
- [ ] `class CLI < Ace::Core::CLI::Base` (not Thor directly)
- [ ] `default_task :query` set
- [ ] `method_missing` delegates to `query`
- [ ] ConfigSummary displayed unless `--quiet`
- [ ] All subcommands have `long_desc` with proper sections
- [ ] `self.help` override with examples

## Manual Tests

```bash
./bin/ace-llm-query --help              # Should show full help
./bin/ace-llm-query --version           # Should show "ace-llm X.X.X"
./bin/ace-llm-query -v                  # Should trigger verbose (NOT version)
./bin/ace-llm-query "test" --model gpt-4 --dry-run
./bin/ace-llm-chat --help
./bin/ace-llm-models --help
```

## Automatic Tests

```bash
cd ace-llm && ace-test
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