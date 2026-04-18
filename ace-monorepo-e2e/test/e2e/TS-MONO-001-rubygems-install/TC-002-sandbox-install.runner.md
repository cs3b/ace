# Goal 2 — Normal Bundle Install

## Goal

Run `bundle install` in an isolated sandbox and capture user-visible install
outcomes as the primary evidence for normal-path viability.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Ensure a clean local install surface and output workspace:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/02/.bundle results/tc/02/.gem`
   - `mkdir -p results/tc/02/.bundle results/tc/02/.gem`
   - Pre-create declared artifacts so verifier input contracts are always present:
   ```bash
   : > results/tc/02/.bundle/config
   : > results/tc/02/bundle-list.stdout
   : > results/tc/02/bundle-list.stderr
   : > results/tc/02/installed-ace-gems.txt
   : > results/tc/02/Gemfile.lock
   : > results/tc/02/install-summary.txt
   ```
2. Record the exact command contract used for execution:
```bash
cat > results/tc/02/install-command.txt <<'EOF'
env -i HOME="$HOME" PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
  GEM_HOME="$PWD/results/tc/02/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle install
EOF
```
3. Run `bundle install` in the sandbox root with isolated Bundler paths:
```bash
env -i HOME="$HOME" PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
  GEM_HOME="$PWD/results/tc/02/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle install > results/tc/02/install.stdout 2> results/tc/02/install.stderr
echo $? > results/tc/02/install.exit
```
4. If install succeeds, capture end-state evidence from the sandbox:
   ```bash
   env -i HOME="$HOME" PATH="$PATH" \
     BUNDLE_GEMFILE="$PWD/Gemfile" \
     BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
     BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
     GEM_HOME="$PWD/results/tc/02/.gem" \
     PROJECT_ROOT_PATH="$PWD" \
     bundle list > results/tc/02/bundle-list.stdout 2> results/tc/02/bundle-list.stderr
   rg '^\s*\* ace-' results/tc/02/bundle-list.stdout > results/tc/02/installed-ace-gems.txt
   if [ -f Gemfile.lock ]; then
     cp Gemfile.lock results/tc/02/Gemfile.lock
   fi
   if [ -s results/tc/02/installed-ace-gems.txt ] && [ -s results/tc/02/Gemfile.lock ]; then
     cat > results/tc/02/install-summary.txt <<'EOF'
SUCCESS: bundle install completed in normal mode with installed ace gem evidence.
EOF
   else
     cat > results/tc/02/install-summary.txt <<'EOF'
SUCCESS: bundle install completed in normal mode, but post-install bundle evidence was incomplete. See bundle-list stdout/stderr and copied lockfile artifacts.
EOF
   fi
   ```
5. If install fails, write an explicit summary and preserve command output as evidence:
```bash
if [ "$(cat results/tc/02/install.exit)" != "0" ]; then
  cat > results/tc/02/install-summary.txt <<'EOF'
FAILED: bundle install did not complete successfully in normal mode.
See install.stdout and install.stderr for details.
EOF
fi
```

## Constraints

- Do not use `--full-index` — that is tested in Goal 3.
- Do not modify the Gemfile.
- Capture command output regardless of success or failure.
