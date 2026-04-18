# Goal 3 — Full-Index Fallback Install

## Goal

Run `bundle install --full-index` in the sandbox with isolated install paths and
capture user-visible fallback-path outcomes.

## Workspace

Save all output to `results/tc/03/`.

## Steps

1. Remove any existing `Gemfile.lock` and isolate the fallback install surface:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/03/.bundle results/tc/03/.gem`
   - `mkdir -p results/tc/03/.bundle results/tc/03/.gem`
   - Pre-create declared artifacts so verifier input contracts are always present:
   ```bash
   : > results/tc/03/.bundle/config
   : > results/tc/03/bundle-list.stdout
   : > results/tc/03/bundle-list.stderr
   : > results/tc/03/installed-ace-gems.txt
   : > results/tc/03/Gemfile.lock
   : > results/tc/03/install-summary.txt
   ```
2. Record the exact command contract used for fallback execution:
```bash
cat > results/tc/03/install-command.txt <<'EOF'
env -i HOME="$HOME" PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/03/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/03/.bundle" \
  GEM_HOME="$PWD/results/tc/03/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle install --full-index
EOF
```
3. Run `bundle install --full-index` with isolated Bundler paths:
```bash
env -i HOME="$HOME" PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/03/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/03/.bundle" \
  GEM_HOME="$PWD/results/tc/03/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle install --full-index > results/tc/03/fullindex.stdout 2> results/tc/03/fullindex.stderr
echo $? > results/tc/03/fullindex.exit
```
4. If install succeeds:
   - Capture sandbox end-state install evidence:
   ```bash
   env -i HOME="$HOME" PATH="$PATH" \
     BUNDLE_GEMFILE="$PWD/Gemfile" \
     BUNDLE_APP_CONFIG="$PWD/results/tc/03/.bundle/config" \
     BUNDLE_PATH="$PWD/results/tc/03/.bundle" \
     GEM_HOME="$PWD/results/tc/03/.gem" \
     PROJECT_ROOT_PATH="$PWD" \
     bundle list > results/tc/03/bundle-list.stdout 2> results/tc/03/bundle-list.stderr
   rg '^\s*\* ace-' results/tc/03/bundle-list.stdout > results/tc/03/installed-ace-gems.txt
   if [ -f Gemfile.lock ]; then
     cp Gemfile.lock results/tc/03/Gemfile.lock
   fi
   cat > results/tc/03/install-summary.txt <<'EOF'
SUCCESS: bundle install --full-index completed.
EOF
```
5. If full-index install fails, write explicit summary evidence:
```bash
if [ "$(cat results/tc/03/fullindex.exit)" != "0" ]; then
  cat > results/tc/03/install-summary.txt <<'EOF'
FAILED: bundle install --full-index did not complete successfully.
See fullindex.stdout and fullindex.stderr for details.
EOF
fi
```

## Constraints

- Must use `--full-index` flag.
- Do not modify the Gemfile.
- Capture command output regardless of success or failure.
