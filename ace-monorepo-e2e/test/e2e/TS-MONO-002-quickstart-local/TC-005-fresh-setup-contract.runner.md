# Goal 5 -- Fresh Setup Contract

## Goal

Follow the quick-start install/setup surface and capture deterministic evidence for
fresh-repo sync behavior, provider/doctor diagnostics, and Codex alias
model defaults.

## Workspace

Save all output to `results/tc/05/`.

## Steps

1. Re-run setup commands and capture outputs:

   ```bash
   ace-config sync ace-llm-providers-cli > results/tc/05/config-sync.stdout 2> results/tc/05/config-sync.stderr
   echo $? > results/tc/05/config-sync.exit

   ace-handbook sync > results/tc/05/handbook-sync.stdout 2> results/tc/05/handbook-sync.stderr
   echo $? > results/tc/05/handbook-sync.exit
   ```

2. Capture provider discovery and doctor diagnostics:

   ```bash
   ace-llm --list-providers > results/tc/05/list-providers.stdout 2> results/tc/05/list-providers.stderr
   echo $? > results/tc/05/list-providers.exit

   ace-config doctor > results/tc/05/config-doctor.stdout 2> results/tc/05/config-doctor.stderr
   echo $? > results/tc/05/config-doctor.exit
   ```

3. Record `.ace-local/` ignore evidence:

   ```bash
   if [ -f .gitignore ]; then
     cp .gitignore results/tc/05/gitignore.snapshot
     grep -n '^\.ace-local/$' .gitignore > results/tc/05/ace-local-ignore-hits.txt || true
   else
     printf 'missing .gitignore\n' > results/tc/05/gitignore.snapshot
     : > results/tc/05/ace-local-ignore-hits.txt
   fi
   ```

4. Capture provider alias files and model-token sanity evidence:

   ```bash
   find . -type f \( -path './.ace/llm/providers/*.yml' -o -path './.ace/llm/**/*.yml' \) | sort > results/tc/05/provider-config-files.txt
   if [ -s results/tc/05/provider-config-files.txt ]; then
     while IFS= read -r provider_file; do
       grep -n 'gpt-5-mini' "$provider_file" >> results/tc/05/provider-mini-hits.txt || true
     done < results/tc/05/provider-config-files.txt
   else
     : > results/tc/05/provider-mini-hits.txt
   fi

   find . -type f -path './.codex/*' | sort > results/tc/05/codex-files.txt
   if [ -s results/tc/05/codex-files.txt ]; then
     while IFS= read -r codex_file; do
       grep -n 'gpt-5-mini' "$codex_file" >> results/tc/05/codex-mini-hits.txt || true
     done < results/tc/05/codex-files.txt
   else
     : > results/tc/05/codex-mini-hits.txt
   fi
   ```

5. Summarize exits and key artifacts:

   ```bash
   printf 'config_sync_exit=%s\n' "$(cat results/tc/05/config-sync.exit)" > results/tc/05/setup-summary.txt
   printf 'handbook_sync_exit=%s\n' "$(cat results/tc/05/handbook-sync.exit)" >> results/tc/05/setup-summary.txt
   printf 'list_providers_exit=%s\n' "$(cat results/tc/05/list-providers.exit)" >> results/tc/05/setup-summary.txt
   printf 'config_doctor_exit=%s\n' "$(cat results/tc/05/config-doctor.exit)" >> results/tc/05/setup-summary.txt
   ```

## Constraints

- Use public CLI commands only.
- Do not fabricate provider availability.
- Keep all artifacts under `results/tc/05/`.
