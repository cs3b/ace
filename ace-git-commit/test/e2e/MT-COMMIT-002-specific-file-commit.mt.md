---
test-id: MT-COMMIT-002
title: Specific File/Path Commit
area: git-commit
package: ace-git-commit
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [git, ace-git-commit]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Specific File/Path Commit

## Objective

Verify that ace-git-commit correctly handles selective staging with path arguments. Tests cover single file commits, directory expansion, and glob patterns.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-ace-git-commit-MT-COMMIT-002"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize test git repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Verify tools are available
echo "=== Tool Verification ==="
which git && git --version
which ace-git-commit && ace-git-commit --version
echo "========================="
```

## Test Data

```bash
# Create initial commit
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Repository
EOF
git add README.md
git commit -m "Initial commit"

# Create directory structure
mkdir -p "$TEST_DIR/lib"
mkdir -p "$TEST_DIR/spec"

# Create multiple files for selective commit tests
cat > "$TEST_DIR/main.rb" << 'EOF'
# frozen_string_literal: true

require_relative "lib/core"

Core.new.run
EOF

cat > "$TEST_DIR/config.rb" << 'EOF'
# frozen_string_literal: true

module Config
  VERSION = "1.0.0"
end
EOF

cat > "$TEST_DIR/lib/core.rb" << 'EOF'
# frozen_string_literal: true

class Core
  def run
    puts "Core running"
  end
end
EOF

cat > "$TEST_DIR/lib/utils.rb" << 'EOF'
# frozen_string_literal: true

module Utils
  def self.log(msg)
    puts "[LOG] #{msg}"
  end
end
EOF

cat > "$TEST_DIR/spec/core_spec.rb" << 'EOF'
# frozen_string_literal: true

describe Core do
  it "runs" do
    expect(Core.new.run).to be_truthy
  end
end
EOF
```

## Test Cases

### TC-001: Commit Single File

**Objective:** Verify that specifying a single file only commits that file, leaving others untracked.

**Steps:**
1. Verify initial state - all files untracked
   ```bash
   git status --porcelain
   ```

2. Commit only main.rb
   ```bash
   ace-git-commit main.rb -m "Add main entry point"
   ```

3. Verify only main.rb was committed
   ```bash
   git show --stat HEAD
   ```

4. Verify other files remain untracked
   ```bash
   git status --porcelain
   ```

**Expected:**
- Exit code: 0
- Commit contains only main.rb
- config.rb, lib/, and spec/ remain untracked
- Commit message is "Add main entry point"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Commit Directory

**Objective:** Verify that specifying a directory expands to include all files within it.

**Steps:**
1. Commit the lib/ directory
   ```bash
   ace-git-commit lib/ -m "Add core library modules"
   ```

2. Verify both lib files were committed
   ```bash
   git show --stat HEAD
   ```

3. Verify files outside lib/ remain untracked
   ```bash
   git status --porcelain
   ```

**Expected:**
- Exit code: 0
- Commit contains lib/core.rb and lib/utils.rb
- config.rb and spec/ remain untracked
- Commit message is "Add core library modules"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Commit with Glob Pattern

**Objective:** Verify that glob patterns correctly match and commit files, including untracked files.

**Note:** Glob patterns now match both git-tracked AND untracked files (excluding gitignored). This allows patterns like `*.rb` to commit new files that haven't been tracked yet.

**Steps:**
1. Commit all remaining .rb files in root using glob
   ```bash
   ace-git-commit "*.rb" -m "Add remaining root-level Ruby files"
   ```

2. Verify correct files were committed
   ```bash
   git show --stat HEAD
   ```

3. Verify spec directory still untracked
   ```bash
   git status --porcelain
   ```

**Expected:**
- Exit code: 0
- Commit contains config.rb (only remaining .rb file in root, even though untracked)
- spec/core_spec.rb remains untracked (glob doesn't match subdirectories)
- Commit message is "Add remaining root-level Ruby files"
- If no files match, a hint suggests using recursive pattern (e.g., `**/*.rb`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Commit Multiple Specific Paths

**Objective:** Verify that multiple path arguments can be specified in a single commit.

**Steps:**
1. Commit the remaining spec file
   ```bash
   ace-git-commit spec/core_spec.rb -m "Add core specifications"
   ```

2. Verify commit
   ```bash
   git show --stat HEAD
   ```

3. Verify working directory is now clean
   ```bash
   git status --porcelain
   ```

**Expected:**
- Exit code: 0
- Commit contains spec/core_spec.rb
- Working directory is clean (all files committed)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Single file commit includes only specified file
- [ ] TC-002: Directory commit expands to all files within
- [ ] TC-003: Glob pattern matches correct files
- [ ] TC-004: Multiple paths can be committed together

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Glob patterns should be quoted to prevent shell expansion
- Directory paths may or may not require trailing slash depending on implementation
- Path arguments are processed after any staging options (-s, --only-staged)
- Glob patterns match both tracked AND untracked files (excluding gitignored files)
- Simple globs like `*.rb` only match at the current directory level
- For recursive matching across subdirectories, use `**/*.rb` syntax
