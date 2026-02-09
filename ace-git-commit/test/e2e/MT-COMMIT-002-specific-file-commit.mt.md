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
last-verified: 2026-02-08
verified-by: claude-opus-4-6
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
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Initialize test git repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Verify tools are available
echo "=== Tool Verification ==="
which git && git --version
which ace-git-commit && ace-git-commit --version
echo "========================="

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi
echo "=== ISOLATION VERIFIED ==="
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create initial commit
cat > README.md << 'EOF'
# Test Repository
EOF
git add README.md
git commit -m "Initial commit"

# Create directory structure
mkdir -p lib
mkdir -p spec

# Create multiple files for selective commit tests
cat > main.rb << 'EOF'
# frozen_string_literal: true

require_relative "lib/core"

Core.new.run
EOF

cat > config.rb << 'EOF'
# frozen_string_literal: true

module Config
  VERSION = "1.0.0"
end
EOF

cat > lib/core.rb << 'EOF'
# frozen_string_literal: true

class Core
  def run
    puts "Core running"
  end
end
EOF

cat > lib/utils.rb << 'EOF'
# frozen_string_literal: true

module Utils
  def self.log(msg)
    puts "[LOG] #{msg}"
  end
end
EOF

cat > spec/core_spec.rb << 'EOF'
# frozen_string_literal: true

describe Core do
  it "runs" do
    expect(Core.new.run).to be_truthy
  end
end
EOF
SANDBOX
```

## Test Cases

### TC-001: Commit Single File

**Objective:** Verify that specifying a single file only commits that file, leaving others untracked.

**Steps:**
1. Verify initial state - all files untracked
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

2. Commit only main.rb
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit main.rb -m "Add main entry point"
   ```

3. Verify only main.rb was committed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

4. Verify other files remain untracked
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
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
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit lib/ -m "Add core library modules"
   ```

2. Verify both lib files were committed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

3. Verify files outside lib/ remain untracked
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
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
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit "*.rb" -m "Add remaining root-level Ruby files"
   ```

2. Verify correct files were committed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

3. Verify spec directory still untracked
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
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
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit spec/core_spec.rb -m "Add core specifications"
   ```

2. Verify commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

3. Verify working directory is now clean
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
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
