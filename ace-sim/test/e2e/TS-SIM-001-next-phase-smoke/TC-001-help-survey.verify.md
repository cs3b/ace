# Goal 1 Verification: Help Survey

PASS when:
- `results/tc/01/help.exit` is `0`
- `results/tc/01/run-help.exit` is `0`
- `results/tc/01/run-help.stdout` mentions `--preset`
- `results/tc/01/run-help.stdout` mentions `--source`
- `results/tc/01/run-help.stdout` mentions `--provider`
- `results/tc/01/run-help.stdout` mentions `--dry-run`
- `results/tc/01/run-help.stdout` mentions `--writeback`
