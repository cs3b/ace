# Goal 1 — Discover ACE Gems

## Goal

Inspect the sandbox Gemfile (generated during setup from the project root Gemfile with `path:` directives stripped). List all ACE gem names found and record the total count.

## Workspace

Save all output to `results/tc/01/`.

## Steps

1. Read the sandbox `Gemfile` and extract all `gem 'ace-*'` declarations.
2. Write the sorted gem list to `results/tc/01/gem-list.txt` (one gem name per line).
3. Write the total gem count to `results/tc/01/gem-count.txt` (just the number).
4. Verify the Gemfile contains no `path:` directives — write the check result to `results/tc/01/path-check.txt`.
5. Confirm the frozen release manifest copied by setup is present and record
   its package count:
```bash
"$ACE_E2E_SANDBOX_RUBY_ROOT/bin/ruby" -rjson -e 'puts JSON.parse(File.read("results/tc/01/release-manifest.json"))["packages"].size' \
  > results/tc/01/manifest-package-count.txt
```

## Constraints

- Do not modify the Gemfile.
- Do not modify `results/tc/01/release-manifest.json`; setup validated and
  copied it, and later goals consume that exact copy.
- The gem list must come from actually reading the file, not from assumptions.
- If the Gemfile is empty or missing ace-* gems, record the finding and continue.
