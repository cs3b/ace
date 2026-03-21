# Goal 6 Verification: Synthesis Provider Guard

PASS when:
- `results/tc/06/run.exit` is non-zero
- `results/tc/06/run.stderr` mentions `synthesis_provider requires synthesis_workflow`

FAIL when:
- command exits `0`
- validation error text is missing from stderr
