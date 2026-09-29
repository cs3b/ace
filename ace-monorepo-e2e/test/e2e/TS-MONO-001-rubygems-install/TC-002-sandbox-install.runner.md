# Goal 2 — Normal Bundle Install

## Goal

Run `bundle install` in an isolated sandbox and capture user-visible install
outcomes as the primary evidence for normal-path viability.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Define the isolated proof environment once, before any install command.
   It runs the dedicated sandbox Ruby's own bundler directly — never a
   PATH-resolved or shim-resolved `bundle`:
```bash
proof_ruby_root="${ACE_E2E_SANDBOX_RUBY_ROOT:?}"
proof_bundle() {
  proof_case="$1"
  shift
  env -i \
    HOME="$HOME" \
    PATH="$proof_ruby_root/bin:$PATH" \
    PROJECT_ROOT_PATH="$PWD" \
    BUNDLE_GEMFILE="$PWD/Gemfile" \
    BUNDLE_APP_CONFIG="$proof_case/.bundle" \
    BUNDLE_PATH="$proof_case/.bundle" \
    BUNDLE_USER_HOME="$proof_case/bundler-home" \
    BUNDLE_USER_CACHE="$proof_case/bundler-cache" \
    BUNDLE_USER_CONFIG="$proof_case/bundler-config" \
    BUNDLE_DISABLE_SHARED_GEMS=true \
    BUNDLE_WITHOUT="" \
    GEM_HOME="$proof_case/.gem" \
    GEM_PATH="$proof_case/.gem" \
    "$proof_ruby_root/bin/ruby" "$proof_ruby_root/bin/bundle" "$@"
}
```
   Execute the scenario-prescribed isolation exactly as written: do not drop
   `env -i`, do not substitute partial environment overrides, and do not
   replace the direct `$proof_ruby_root/bin` executables with PATH lookups.

2. Ensure a clean local install surface and output workspace:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/02`
   - `mkdir -p results/tc/02/.bundle results/tc/02/.gem results/tc/02/bundler-home results/tc/02/bundler-cache`
   - Pre-create the remaining verifier input contracts (placeholders are NOT
     postcondition evidence; `bundler-config` must be an empty FILE — bundler
     reads `BUNDLE_USER_CONFIG` as a file):
```bash
: > results/tc/02/install-summary.txt
: > results/tc/02/bundler-config
```

3. Record the exact command contract used for execution:
```bash
cat > results/tc/02/install-command.txt <<'EOF'
proof_ruby_root="${ACE_E2E_SANDBOX_RUBY_ROOT:?}"
proof_bundle() {
  proof_case="$1"; shift
  env -i HOME="$HOME" PATH="$proof_ruby_root/bin:$PATH" \
    PROJECT_ROOT_PATH="$PWD" \
    BUNDLE_GEMFILE="$PWD/Gemfile" \
    BUNDLE_APP_CONFIG="$proof_case/.bundle" \
    BUNDLE_PATH="$proof_case/.bundle" \
    BUNDLE_USER_HOME="$proof_case/bundler-home" \
    BUNDLE_USER_CACHE="$proof_case/bundler-cache" \
    BUNDLE_USER_CONFIG="$proof_case/bundler-config" \
    BUNDLE_DISABLE_SHARED_GEMS=true \
    BUNDLE_WITHOUT="" \
    GEM_HOME="$proof_case/.gem" \
    GEM_PATH="$proof_case/.gem" \
    "$proof_ruby_root/bin/ruby" "$proof_ruby_root/bin/bundle" "$@"
}
proof_bundle results/tc/02 install
EOF
```

4. Run `bundle install` with the isolated environment:
```bash
proof_bundle results/tc/02 install > results/tc/02/install.stdout 2> results/tc/02/install.stderr
echo $? > results/tc/02/install.exit
```

5. If install succeeds, capture end-state evidence with the same environment:
   ```bash
   proof_bundle results/tc/02 list > results/tc/02/bundle-list.stdout 2> results/tc/02/bundle-list.stderr
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

6. If install fails, write an explicit summary and preserve command output as evidence:
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
- Do not weaken the isolation: keep `env -i`, the confined `results/tc/02/`
  paths, and the direct sandbox-Ruby executables exactly as prescribed.
