# ACE Infrastructure Gem Rename - Usage Guide

## Overview

This guide documents the migration from `ace-core` and `ace-test-support` to their new names: `ace-support-core` and `ace-support-test-helpers`. The rename aligns infrastructure gems with the ecosystem naming convention where `ace-support-*` indicates library-only gems without CLI tools.

**What's Changing:**
- `ace-core` → `ace-support-core` (foundational configuration cascade)
- `ace-test-support` → `ace-support-test-helpers` (shared test utilities)

**What's NOT Changing:**
- Module names remain the same (`Ace::Core`, `Ace::TestSupport`)
- Require paths stay the same (`require 'ace/core'`, `require 'ace/test_support'`)
- Internal directory structure unchanged (`lib/ace/core/`, `lib/ace/test_support/`)
- Functionality and APIs identical

## Migration Timeline

**Phase 1 (Week 1):** New gems published, coexisting with old gems
**Phase 2 (Weeks 2-3):** All ACE ecosystem gems updated to use new names
**Phase 3 (Week 4):** Documentation updated, old gems marked deprecated
**Phase 4 (Future):** Old gems frozen with deprecation notices

## For ACE Ecosystem Developers

### Scenario 1: Updating a Single Gem's Dependencies

**Goal:** Update one of the 13 dependent gems to use the new infrastructure gem names.

**Steps:**

1. **Update the gemspec file:**

```ruby
# Before (ace-search/ace-search.gemspec)
Gem::Specification.new do |spec|
  spec.add_dependency "ace-core", "~> 0.9"
  spec.add_development_dependency "ace-test-support", "~> 0.9"
end

# After
Gem::Specification.new do |spec|
  spec.add_dependency "ace-support-core", "~> 0.9"
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
end
```

2. **Update the Gemfile (for development):**

```ruby
# No changes needed - require statements stay the same
require 'ace/core'
require 'ace/test_support'
```

3. **Run tests:**

```bash
cd ace-search
bundle install
bundle exec rake test
```

4. **Expected output:**

```
All tests passing - no code changes needed!
Module names and require paths unchanged.
```

### Scenario 2: Publishing Updated Gems

**Goal:** Publish a gem with updated dependencies to RubyGems.

**Steps:**

1. **Update CHANGELOG.md:**

```markdown
## [0.2.1] - 2025-10-25

### Changed
- Updated dependencies: ace-core → ace-support-core, ace-test-support → ace-support-test-helpers
- No API changes, fully backward compatible
```

2. **Bump version (patch):**

```ruby
# lib/ace/your_gem/version.rb
VERSION = "0.2.1"  # Patch bump for dependency update
```

3. **Build and publish:**

```bash
gem build ace-your-gem.gemspec
gem push ace-your-gem-0.2.1.gem
```

4. **Verify:**

```bash
gem install ace-your-gem --version 0.2.1
ruby -e "require 'ace/your_gem'; puts Ace::YourGem::VERSION"
# Expected: 0.2.1
```

### Scenario 3: Testing the Entire Ecosystem

**Goal:** Verify all gems work together with the new dependency names.

**Steps:**

1. **Update root Gemfile:**

```ruby
# Gemfile (workspace development)
gem "ace-support-core", path: "ace-support-core"
gem "ace-support-test-helpers", path: "ace-support-test-helpers"

# All other gems reference new names in their gemspecs
```

2. **Install dependencies:**

```bash
bundle install
```

3. **Run ecosystem test suite:**

```bash
ace-test --all
# or
bundle exec rake test:all
```

4. **Expected output:**

```
Testing ace-support-core...      ✓ All tests passed
Testing ace-support-test-helpers... ✓ All tests passed
Testing ace-context...            ✓ All tests passed
Testing ace-search...             ✓ All tests passed
Testing ace-lint...               ✓ All tests passed
... (all 15+ gems)

Ecosystem integration: ✓ PASS
```

### Scenario 4: Handling Rollback

**Goal:** Revert to old gem names if issues are discovered.

**Steps:**

1. **Revert gemspec changes:**

```bash
git checkout ace-your-gem/ace-your-gem.gemspec
```

2. **Reinstall dependencies:**

```bash
bundle install
```

3. **Verify old gems work:**

```bash
bundle exec rake test
# Should pass with old gem names
```

4. **Unpublish new gems (within 24h of publishing):**

```bash
gem yank ace-support-core -v 0.9.0
gem yank ace-support-test-helpers -v 0.9.0
```

## For External Users

### Scenario 5: Upgrading an External Project

**Goal:** Update your project to use the new gem names without breaking your code.

**Before (your project's Gemfile):**

```ruby
gem 'ace-core', '~> 0.9'
gem 'ace-test-support', '~> 0.9', group: :development
```

**After:**

```ruby
gem 'ace-support-core', '~> 0.9'
gem 'ace-support-test-helpers', '~> 0.9', group: :development
```

**Your code (NO CHANGES NEEDED):**

```ruby
# Still works exactly the same
require 'ace/core'
require 'ace/test_support'

config = Ace::Core.config
# All module names unchanged
```

**Steps:**

1. Update Gemfile with new gem names
2. Run `bundle update ace-support-core ace-support-test-helpers`
3. Run your test suite (should pass without code changes)

### Scenario 6: Staying on Old Gems (Temporary)

**Goal:** Continue using old gem names during transition period.

**Current behavior:**

```ruby
# Gemfile
gem 'ace-core', '~> 0.9'  # Will continue to work

# But you'll see a deprecation warning:
# WARNING: ace-core is deprecated. Please use ace-support-core instead.
# See: https://github.com/cs3b/ace-meta/blob/main/docs/migrations/ace-support-gem-rename.md
```

**Timeline:**
- Old gems maintained for 6 months minimum
- Deprecation warnings start in Phase 3
- Old gems frozen but still available on RubyGems

## Execution Guide (Post-Review)

Based on comprehensive review completed 2025-11-01, here are the validated execution steps for implementing the gem rename:

### Phase 1: Create and Test New Gems

**Execute in order:**

```bash
# 1.1: Create ace-support-core from ace-core
cp -r ace-core ace-support-core
cd ace-support-core

# Update gemspec manually:
# - Change spec.name from "ace-core" to "ace-support-core"
# - Keep all other settings identical
# - Version remains 0.10.0

# Build and verify
gem build ace-support-core.gemspec
cd ..

# 1.2: Create ace-support-test-helpers from ace-test-support
cp -r ace-test-support ace-support-test-helpers
cd ace-support-test-helpers

# Update gemspec manually:
# - Change spec.name from "ace-test-support" to "ace-support-test-helpers"
# - Keep all other settings identical
# - Version remains 0.9.2

# Build and verify
gem build ace-support-test-helpers.gemspec
cd ..

# 1.3: Update root Gemfile for local development
# Add these lines to Gemfile:
#   gem "ace-support-core", path: "ace-support-core"
#   gem "ace-support-test-helpers", path: "ace-support-test-helpers"

bundle install

# 1.4: Test new gems in isolation
cd ace-support-core && bundle exec rake test && cd ..
cd ace-support-test-helpers && bundle exec rake test && cd ..
```

**Validation:**
```bash
# Verify module loading works
ruby -e "require 'ace/core'; puts Ace::Core::VERSION"
ruby -e "require 'ace/test_support'; puts Ace::TestSupport::VERSION"
```

### Phase 2: Update Dependent Gems by Tier

**Tier 1 - Foundation (both dependencies):**

```bash
# ace-test-runner (0.1.5 → 0.1.6)
cd ace-test-runner
# Edit ace-test-runner.gemspec:
#   s.add_dependency "ace-support-core", "~> 0.1"
#   s.add_development_dependency "ace-support-test-helpers", "~> 0.1"
# Update version to 0.1.6 in lib/ace/test_runner/version.rb
# Update CHANGELOG.md
bundle install && bundle exec rake test
cd ..

# ace-nav (0.10.1 → 0.10.2)
cd ace-nav
# Edit ace-nav.gemspec:
#   s.add_dependency "ace-support-core", "~> 0.1"
#   s.add_development_dependency "ace-support-test-helpers", "~> 0.1"
# Update version to 0.10.2 in lib/ace/nav/version.rb
# Update CHANGELOG.md
bundle install && bundle exec rake test
cd ..
```

**Tier 2 - Core Tools:**

```bash
# Update each gem following the same pattern:
# ace-context (0.16.0 → 0.16.1)
# ace-git-commit (0.11.0 → 0.11.1)
# ace-git-diff (0.1.1 → 0.1.2) - also has dev dependency
# ace-llm (0.9.4 → 0.9.5)
# ace-taskflow (0.13.2 → 0.13.3)

for gem in ace-context ace-git-commit ace-git-diff ace-llm ace-taskflow; do
  cd $gem
  # Update gemspec dependencies
  # Bump patch version
  # Update CHANGELOG
  bundle install && bundle exec rake test
  cd ..
done
```

**Tier 3 - Feature Gems:**

```bash
# Update remaining gems:
# ace-search (0.11.2 → 0.11.3) - runtime + dev
# ace-lint (0.3.0 → 0.3.1)
# ace-docs (0.6.1 → 0.6.2)
# ace-review (0.11.1 → 0.11.2) - runtime + dev
# ace-support-markdown (0.1.2 → 0.1.3) - dev only

for gem in ace-search ace-lint ace-docs ace-review ace-support-markdown; do
  cd $gem
  # Update gemspec dependencies
  # Bump patch version
  # Update CHANGELOG
  bundle install && bundle exec rake test
  cd ..
done
```

### Phase 3: Documentation Updates

**Bulk update markdown references:**

```bash
# Update all markdown files (review changes before committing!)
find . -name "*.md" -type f -exec sed -i.bak 's/gem.*ace-core/gem "ace-support-core/g' {} +
find . -name "*.md" -type f -exec sed -i.bak 's/gem.*ace-test-support/gem "ace-support-test-helpers/g' {} +

# Review changes
git diff --name-only | xargs git diff

# Clean up backup files after verification
find . -name "*.md.bak" -type f -delete
```

### Bundle Install Verification

After any gem update, verify bundler resolution:

```bash
# Clear bundle cache
bundle clean --force
rm -rf vendor/bundle

# Fresh install with verbose output
bundle install --verbose

# Check for mixed old/new names
bundle list | grep ace- | sort

# Expected: All gems resolve correctly
```

### Test Suite Verification

Run tests in isolation and integration:

```bash
# Individual gem tests
for gem in ace-support-core ace-support-test-helpers; do
  echo "Testing $gem..."
  cd $gem && bundle exec rake test && cd .. || break
done

# Dependent gem tests (sample)
for gem in ace-context ace-search ace-lint; do
  echo "Testing $gem..."
  cd $gem && bundle exec rake test && cd .. || break
done

# Full ecosystem test (if available)
ace-test --all

# Expected: All tests pass, no LoadError or NameError
```

### Rollback Procedures

**Phase 1 Rollback (New gems created but not yet used):**

```bash
# Remove new directories
rm -rf ace-support-core ace-support-test-helpers

# Revert Gemfile changes
git checkout Gemfile Gemfile.lock
bundle install

# Impact: Zero (no dependent gems updated yet)
```

**Phase 2 Rollback (Some gems updated):**

```bash
# For each updated gem, revert gemspec
for gem in ace-test-runner ace-nav ace-context; do
  cd $gem
  git checkout ${gem}.gemspec
  bundle install && bundle exec rake test
  cd ..
done

# Impact: Low (easy to revert)
```

**Emergency Rollback (All phases):**

```bash
# Create tag before starting migration
git tag pre-gem-rename-migration

# Emergency rollback to pre-migration state
git reset --hard pre-gem-rename-migration

# Reinstall dependencies
bundle install

# Impact: Complete rollback, loses interim work
```

## Command Reference

### RubyGems Installation

```bash
# New gems (recommended)
gem install ace-support-core
gem install ace-support-test-helpers

# Old gems (deprecated, will show warning)
gem install ace-core
gem install ace-test-support
```

### Bundler Commands

```bash
# Update specific gems
bundle update ace-support-core ace-support-test-helpers

# Update all ACE gems
bundle update ace-*

# Check installed versions
bundle list | grep ace
```

### Development Commands

```bash
# Build gems locally
gem build ace-support-core.gemspec
gem build ace-support-test-helpers.gemspec

# Test gem installation locally
gem install ace-support-core-0.9.0.gem --local

# Verify module loading
ruby -e "require 'ace/core'; puts Ace::Core::VERSION"
```

### Verification Commands

```bash
# Check for old gem names in gemspecs
grep -r "ace-core\|ace-test-support" ace-*/ace-*.gemspec

# Verify all gems use new names
for gem in ace-*/ace-*.gemspec; do
  echo "Checking $gem..."
  grep "ace-support" "$gem" || echo "  → Still using old names"
done

# Count documentation references
grep -r "ace-support-core" . --include="*.md" | wc -l
```

## Tips and Best Practices

### For Gem Maintainers

1. **Update in dependency order:** Update foundation gems (ace-test-runner, ace-nav) before feature gems (ace-search, ace-lint)
2. **Test between updates:** Run full test suite after each gem update to catch issues early
3. **Use patch versions:** Dependency updates are patch-level changes (0.2.0 → 0.2.1)
4. **Document in CHANGELOG:** Always note the dependency update in your gem's CHANGELOG
5. **Verify require paths:** Confirm that `require 'ace/core'` still works in your tests

### For External Users

1. **Update Gemfile only:** No code changes needed in your application
2. **Test before deploying:** Run your full test suite after updating gems
3. **Use version pinning:** Pin to specific versions during testing (`gem 'ace-support-core', '0.9.0'`)
4. **Check deprecation warnings:** Old gems will warn but continue working
5. **Plan migration window:** Allow time to test before deploying to production

### Common Pitfalls

**Pitfall 1: Mixing old and new gem names**
```ruby
# DON'T MIX
gem 'ace-core', '~> 0.9'
gem 'ace-support-test-helpers', '~> 0.9'

# DO USE CONSISTENTLY
gem 'ace-support-core', '~> 0.9'
gem 'ace-support-test-helpers', '~> 0.9'
```

**Pitfall 2: Changing require paths**
```ruby
# DON'T CHANGE
require 'ace/support/core'  # ✗ Wrong

# DO KEEP THE SAME
require 'ace/core'  # ✓ Correct
```

**Pitfall 3: Updating module names**
```ruby
# DON'T CHANGE
Ace::Support::Core.config  # ✗ Wrong

# DO KEEP THE SAME
Ace::Core.config  # ✓ Correct
```

## Troubleshooting

### Issue: Bundle install fails with dependency conflict

**Symptom:**
```
Bundler could not find compatible versions for gem "ace-core":
  In Gemfile:
    ace-support-core was resolved to 0.9.0, which depends on
      ace-core
```

**Solution:**
Some gem hasn't been updated yet. Check which gems still reference old names:
```bash
grep -r "ace-core" */Gemfile */*.gemspec
```

### Issue: Tests fail after updating dependencies

**Symptom:**
```
LoadError: cannot load such file -- ace/core
```

**Solution:**
This shouldn't happen - require paths are unchanged. Check:
1. Bundle installed correctly: `bundle install`
2. Gem is in bundle: `bundle list | grep ace-support-core`
3. Old gem removed from cache: `bundle clean --force`

### Issue: RubyGems shows old gem when installing

**Symptom:**
```bash
gem install ace-support-core
# Installs ace-core instead
```

**Solution:**
Old gem might be aliased. Verify gem name:
```bash
gem spec ace-support-core --remote | grep "^name:"
# Should show: name: ace-support-core
```

## Migration Checklist

For ACE ecosystem developers updating a gem:

- [ ] Update gemspec dependencies (ace-core → ace-support-core)
- [ ] Update gemspec dev dependencies (ace-test-support → ace-support-test-helpers)
- [ ] Run `bundle install`
- [ ] Run full test suite (`bundle exec rake test`)
- [ ] Update CHANGELOG.md with dependency changes
- [ ] Bump gem version (patch level for dependency update)
- [ ] Update README.md if it shows dependency examples
- [ ] Build gem (`gem build your-gem.gemspec`)
- [ ] Test locally before publishing
- [ ] Publish to RubyGems (`gem push your-gem-x.y.z.gem`)
- [ ] Verify installation from RubyGems
- [ ] Tag release in Git
- [ ] Update documentation references

## References

- **Migration Planning:** `.ace-taskflow/v.0.9.0/tasks/086-task-support-align-infrastructure-gem-namin/task.086.md`
- **Naming Convention Guide:** `docs/ace-gems.g.md`
- **Mono-repo Architecture:** `docs/decisions/ADR-015-mono-repo-ace-gems-migration.md`
- **Source Ideas:**
  - `.ace-taskflow/v.0.9.0/ideas/done/20251007-220339-rename-this-pacage-to-ace-support-test-helpers.md`
  - `.ace-taskflow/v.0.9.0/ideas/done/20251007-220406-rename-this-pacage-to-ace-support-core.md`
