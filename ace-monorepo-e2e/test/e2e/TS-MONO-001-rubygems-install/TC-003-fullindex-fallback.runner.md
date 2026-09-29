# Goal 3 — Full-Index Fallback Install

## Goal

Run `bundle install --full-index` in the sandbox with isolated install paths and
capture user-visible fallback-path outcomes.

## Workspace

Save all output to `results/tc/03/`.

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

2. Remove any existing `Gemfile.lock` and isolate the fallback install surface:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/03`
   - `mkdir -p results/tc/03/.bundle results/tc/03/.gem results/tc/03/bundler-home results/tc/03/bundler-cache`
   - Pre-create the remaining verifier input contracts (placeholders are NOT
     postcondition evidence; `bundler-config` must be an empty FILE — bundler
     reads `BUNDLE_USER_CONFIG` as a file):
```bash
: > results/tc/03/install-summary.txt
: > results/tc/03/bundler-config
```

3. Record the exact command contract used for fallback execution:
```bash
cat > results/tc/03/install-command.txt <<'EOF'
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
proof_bundle results/tc/03 install --full-index
EOF
```

4. Run `bundle install --full-index` with the isolated environment:
```bash
proof_bundle results/tc/03 install --full-index > results/tc/03/fullindex.stdout 2> results/tc/03/fullindex.stderr
echo $? > results/tc/03/fullindex.exit
```

5. If install succeeds, capture end-state evidence with the same environment:
   ```bash
   proof_bundle results/tc/03 list > results/tc/03/bundle-list.stdout 2> results/tc/03/bundle-list.stderr
   rg '^\s*\* ace-' results/tc/03/bundle-list.stdout > results/tc/03/installed-ace-gems.txt
   if [ -f Gemfile.lock ]; then
     cp Gemfile.lock results/tc/03/Gemfile.lock
   fi
   cat > results/tc/03/install-summary.txt <<'EOF'
SUCCESS: bundle install --full-index completed.
EOF
```

6. If full-index install fails, write explicit summary evidence:
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
- Do not weaken the isolation: keep `env -i`, the confined `results/tc/03/`
  paths, and the direct sandbox-Ruby executables exactly as prescribed.
