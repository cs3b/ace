# Goal 1 — Idea Capture

## Goal

Follow quick-start section 1 ("Capture an idea") and verify that `ace-idea` creates
an idea artifact, returns success, and surfaces it via CLI output.

## Workspace

Save all output to `results/tc/01/`.

## Steps

1. Run create and capture full execution evidence:
   ```bash
   ace-idea create "Add retry logic to webhook delivery" --tags reliability,webhooks \
     > results/tc/01/create.stdout 2> results/tc/01/create.stderr
   echo $? > results/tc/01/create.exit
   ```
2. List ideas and capture evidence:
   ```bash
   ace-idea list --in next --status pending \
     > results/tc/01/list.stdout 2> results/tc/01/list.stderr
   echo $? > results/tc/01/list.exit
   ```
3. Capture candidate idea artifacts and resolve the idea ID from the created file path:
   ```bash
   find .ace-ideas -type f -name '*.idea.s.md' | sort > results/tc/01/ideas.txt
   tail -n 1 results/tc/01/ideas.txt > results/tc/01/idea-path.txt
   idea_path="$(cat results/tc/01/idea-path.txt)"
   idea_file="$(basename "$idea_path")"
   idea_id="${idea_file%%-*}"
   echo "$idea_id" > results/tc/01/idea-id.txt
   ```
4. Resolve and show the created idea using the extracted ID:
   ```bash
   idea_id="$(cat results/tc/01/idea-id.txt)"
   if [ -n "$idea_id" ]; then
     ace-idea show "$idea_id" \
       > results/tc/01/show.stdout 2> results/tc/01/show.stderr
     echo $? > results/tc/01/show.exit
   else
     echo "NO_ID" > results/tc/01/show.stdout
     echo "1" > results/tc/01/show.exit
   fi
   ```
5. Capture a normalized tree snapshot:
   ```bash
   find .ace-ideas -type f -name '*.idea.s.md' | sort > results/tc/01/tree.stdout
   ```

## Constraints

- Use only `ace-idea` commands as documented in quick-start.md.
- Do not create files manually.
- Keep all generated artifacts under `results/tc/01/`.
