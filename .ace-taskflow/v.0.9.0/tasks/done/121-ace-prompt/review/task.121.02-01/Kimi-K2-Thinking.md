# Code Review Summary

This PR delivers two major features: a new `ace-prompt` gem for prompt workspace management and critical subtask ID handling fixes in `ace-git-worktree`. The changes demonstrate excellent ATOM architecture adherence, comprehensive testing, and mature error handling. All critical issues from previous reviews have been addressed.

---

## 🎯 Critical Issues (Blocking)

*No blocking issues found.* The PR correctly implements CLI exit patterns, includes integration tests, and maintains architectural compliance.

---

## 🟡 High Priority Issues

### 1. Command Injection Vulnerability in Template Resolution

**File**: `ace-prompt/lib/ace/prompt/molecules/template_resolver.rb:65`

```ruby
# Current (vulnerable)
output = `#{ace_nav_path} #{uri.shellescape} 2>/dev/null`.strip
```

**Issue**: While `shellescape` provides some protection, direct shell execution with string interpolation is risky. If `ace_nav_path` contains spaces or special characters, this could be exploited.

**Fix**: Use `Open3.capture3` with argument arrays:

```ruby
require 'open3'

# Replace lines 65-66 with:
stdout, stderr, status = Open3.capture3(ace_nav_path, uri, err: File::NULL)
return nil unless status.success?
output = stdout.strip
```

**Rationale**: This eliminates shell interpretation entirely, following the secure pattern used elsewhere in the codebase.

---

### 2. Inconsistent Error Handling in CLI

**File**: `ace-prompt/lib/ace/prompt/cli.rb:58-61, 98-101, 138-141`

```ruby
# Current pattern
rescue StandardError => e
  warn "Setup failed: #{e.message}"
  1
end
```

**Issue**: Different commands handle exceptions differently. `process` rescues `Ace::Prompt::Error` while `setup` and `reset` rescue `StandardError`, creating inconsistency.

**Fix**: Standardize on a custom error hierarchy:

```ruby
# In lib/ace/prompt.rb
module Ace
  module Prompt
    class Error < StandardError; end
    class TemplateError < Error; end
    class ArchiveError < Error; end
  end
end

# Update all CLI commands to rescue Ace::Prompt::Error
rescue Ace::Prompt::Error => e
  warn "Error: #{e.message}"
  1
end
```

---

## 🟢 Medium Priority Issues

### 3. Missing Input Validation for Template URIs

**File**: `ace-prompt/lib/ace/prompt/molecules/template_resolver.rb:24`

```ruby
# Current
def call(uri:)
  unless uri.start_with?("tmpl://")
```

**Issue**: No validation of URI format beyond the prefix. Malformed URIs like `tmpl://` (empty path) or `tmpl://../../etc/passwd` could cause issues.

**Fix**: Add format validation:

```ruby
def call(uri:)
  unless uri.match?(/\Atmpl:\/\/[a-z0-9_-]+\/[a-z0-9_-]+\z/i)
    return {
      success: false,
      path: nil,
      error: "Invalid template URI format: must be tmpl://gem-name/template-name"
    }
  end
  # ... existing logic
end
```

---

### 4. Test Coupling via Global Stubbing

**File**: `ace-prompt/test/integration/cli_integration_test.rb:18-24`

```ruby
# Current pattern
@original_finder = Ace::Core::Molecules::ProjectRootFinder.method(:find_or_current)
Ace::Core::Molecules::ProjectRootFinder.define_singleton_method(:find_or_current) do
  tmpdir
end
```

**Issue**: Modifying singleton methods can affect parallel test execution and creates hidden dependencies between tests.

**Fix**: Use dependency injection pattern:

```ruby
# In molecules:
def self.call(path: nil, project_root_finder: Ace::Core::Molecules::ProjectRootFinder)
  project_root = project_root_finder.find_or_current
  # ...
end

# In tests:
result = Ace::Prompt::Molecules::PromptReader.call(
  path: @prompt_file,
  project_root_finder: MockFinder.new(@tmpdir)
)
```

---

### 5. Missing Configuration Cascade Integration

**File**: `ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb:18`

```ruby
# Current
DEFAULT_ARCHIVE_DIR = ".cache/ace-prompt/prompts/archive"
```

**Issue**: Hardcoded path ignores ACE's configuration cascade pattern used in other gems.

**Fix**: Use ace-support-core configuration:

```ruby
# In .ace.example/prompt/config.yml
archive_dir: ".cache/ace-prompt/prompts/archive"

# In code:
def self.archive_dir
  Ace::Core.config.get('ace', 'prompt', 'archive_dir') || DEFAULT_ARCHIVE_DIR
end
```

---

## 🔵 Low Priority Issues

### 6. CLI Help Text Duplication

**File**: `ace-prompt/lib/ace/prompt/cli.rb`

The `long_desc` blocks duplicate information between setup/reset commands. Consider extracting common template behavior documentation.

### 7. Missing Performance Benchmarks

**File**: `ace