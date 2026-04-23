# Goal 8 — No-Report Public Contract

## Goal

Validate the public `--no-report` contract: run lint without report generation and prove no report directory artifacts are produced.

## Workspace

Save all output to `results/tc/08/`. Capture:
- `results/tc/08/lint.stdout`, `.stderr`, `.exit` - command output and exit code
- `results/tc/08/command.txt` - the exact command invocation used for this goal
- `results/tc/08/artifact-check.txt` - a short artifact check showing no `Reports:` line was emitted and no report artifacts were copied

## Constraints

- Use `ace-lint` on the sandbox-root file `valid.rb` with `--no-report`. Do not prefix the path with `fixtures/`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is.
- Follow the `--no-report` semantics documented in `ace-lint/docs/usage.md`.
- Persist the exact command contract so the verifier can prove the run actually used `--no-report`.
- Do not infer from assumptions; use actual command output and observed filesystem state.
- Use this exact command contract:
  - `ace-lint valid.rb --no-report`
- After the lint run, write `artifact-check.txt` with:
  - the files present in `results/tc/08/`
  - whether `lint.stdout` contains a `Reports:` line
  - whether any copied `report.json`, `ok.md`, `fixed.md`, or `pending.md` artifacts exist under `results/tc/08/`
- All artifacts must come from real tool execution, not fabricated.

## Steps

1. Persist the exact command:

   ```bash
   printf 'ace-lint valid.rb --no-report\n' > results/tc/08/command.txt
   ```

2. Run the no-report command and capture output:

   ```bash
   ace-lint valid.rb --no-report > results/tc/08/lint.stdout 2> results/tc/08/lint.stderr
   echo $? > results/tc/08/lint.exit
   ```

3. Write the artifact check:

   ```bash
   (
     cd results/tc/08 || exit 1
     {
       echo "files:"
       find . -maxdepth 1 -type f | sort
       echo
       if grep -q '^Reports:' lint.stdout; then
         echo "reports_in_stdout: present"
       else
         echo "reports_in_stdout: absent"
       fi
       found=0
       for name in report.json ok.md fixed.md pending.md; do
         if [ -e "$name" ]; then
           echo "copied_report_artifact: $name"
           found=1
         fi
       done
       if [ "$found" -eq 0 ]; then
         echo "copied_report_artifacts: none"
       fi
     } > artifact-check.txt
   )
   ```
