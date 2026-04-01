# Goal 2 — Normal Bundle Install

## Goal

Run `bundle install` in the sandbox with a sanitized environment and isolate Bundler output so we verify fresh RubyGems-based install behavior.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Ensure a clean local install surface and lock state:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/02/.bundle results/tc/02/.gem`
   - `mkdir -p results/tc/02/.bundle results/tc/02/.gem`
2. Save installation environment capture evidence:
```bash
env -i \
  HOME="$HOME" \
  PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
  GEM_HOME="$PWD/results/tc/02/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle env > results/tc/02/bundle-env.stdout 2> results/tc/02/bundle-env.stderr
```
3. Run `bundle install` in the sandbox root with all Bundler-preserved variables set to the local surface:
```bash
env -i HOME="$HOME" PATH="$PATH" \
  BUNDLE_GEMFILE="$PWD/Gemfile" \
  BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
  BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
  GEM_HOME="$PWD/results/tc/02/.gem" \
  PROJECT_ROOT_PATH="$PWD" \
  BUNDLE_WITHOUT="" \
  bundle install > results/tc/02/install.stdout 2>&1
echo $? > results/tc/02/install.exit
```
4. If install succeeds:
   - Capture local install state:
   ```bash
   env -i HOME="$HOME" PATH="$PATH" \
     BUNDLE_GEMFILE="$PWD/Gemfile" \
     BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
     BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
     GEM_HOME="$PWD/results/tc/02/.gem" \
     PROJECT_ROOT_PATH="$PWD" \
     bundle list > results/tc/02/bundle-list.stdout 2> results/tc/02/bundle-list.stderr
   env -i HOME="$HOME" PATH="$PATH" \
     BUNDLE_GEMFILE="$PWD/Gemfile" \
     BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
     BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
     GEM_HOME="$PWD/results/tc/02/.gem" \
     PROJECT_ROOT_PATH="$PWD" \
     bundle env > results/tc/02/bundle-env-install.stdout 2> results/tc/02/bundle-env-install.stderr
   ```
   - Verify ace gem resolution freshness against RubyGems and write artifacts:
   ```bash
   env -i HOME="$HOME" PATH="$PATH" \
     BUNDLE_GEMFILE="$PWD/Gemfile" \
     BUNDLE_APP_CONFIG="$PWD/results/tc/02/.bundle/config" \
     BUNDLE_PATH="$PWD/results/tc/02/.bundle" \
     GEM_HOME="$PWD/results/tc/02/.gem" \
     PROJECT_ROOT_PATH="$PWD" \
     bundle exec ruby - <<'RUBY' > results/tc/02/version-check.stdout 2> results/tc/02/version-check.stderr
require "bundler/setup"
require "rubygems"
require "rubygems/spec_fetcher"

gemfile = File.join(Dir.pwd, "Gemfile")
gems = File.read(gemfile)
  .scan(/^\s*gem\s+['"]([^'"]+)['"][^#\n]*/)
  .map { |match| match.first }
  .grep(/\Aace-/)
  .sort
  .uniq

if gems.empty?
  puts "NO-ACE-GEMS"
  puts "SUMMARY:OK"
  exit 0
end

ok = true

gems.each do |name|
  local_spec = Gem::Specification.find_all_by_name(name).max_by(&:version)
  local_version = local_spec&.version

  begin
    fetched = Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(name, ">= 0"))[0] || []
    remote_version = fetched.map { |entry| entry[0]&.version }.compact.max
  rescue StandardError => error
    puts "#{name}:REMOTE_LOOKUP_ERROR #{error.class}:#{error.message}"
    ok = false
    next
  end

  if local_version.nil?
    puts "#{name}:MISSING"
    ok = false
    next
  end

  if remote_version.nil?
    puts "#{name}:REMOTE_MISSING local=#{local_version}"
    ok = false
    next
  end

  if Gem::Version.new(local_version.to_s) >= remote_version
    puts "#{name}:OK local=#{local_version} remote=#{remote_version}"
  else
    puts "#{name}:STALE local=#{local_version} remote=#{remote_version}"
    ok = false
  end
end

if ok
  puts "SUMMARY:OK"
  exit 0
else
  puts "SUMMARY:FAIL"
  exit 1
end
RUBY
echo $? > results/tc/02/version-check.exit
```

## Constraints

- Do not use `--full-index` — that is tested in Goal 3.
- Do not modify the Gemfile.
- Capture the full output regardless of success or failure.
