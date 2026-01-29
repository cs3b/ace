---
test-id: MT-COMMIT-004
title: Split Commit Workflow
area: git-commit
package: ace-git-commit
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [git, ace-git-commit]
  ruby: ">= 3.0"
related-task: 228
last-verified: 2026-01-25
verified-by: codex-gpt-5
---

# Split Commit Workflow

## Objective

Verify that ace-git-commit correctly handles path-based configuration splitting. This test validates the Task 228 implementation of automatic commit splitting when files span multiple configuration scopes.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-ace-git-commit-MT-COMMIT-004"
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
# Create initial structure
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Repository

Multi-package repository for testing split commits.
EOF

git add README.md
git commit -m "Initial commit"

# Create package structure with distributed configs
mkdir -p pkg-a/.ace/git pkg-b/.ace/git

cat > "$TEST_DIR/pkg-a/.ace/git/commit.yml" << 'EOF'
model: glite
EOF

cat > "$TEST_DIR/pkg-b/.ace/git/commit.yml" << 'EOF'
model: gflash
EOF

# Create source files in each package
cat > "$TEST_DIR/pkg-a/service.rb" << 'EOF'
# frozen_string_literal: true

class ServiceA
  def run
    "Running service A"
  end
end
EOF

cat > "$TEST_DIR/pkg-b/service.rb" << 'EOF'
# frozen_string_literal: true

class ServiceB
  def run
    "Running service B"
  end
end
EOF

# Commit the initial package structure
git add .
git commit -m "Add package structure with configs"
```

## Test Cases

### TC-001: Auto-Split When Files Span Multiple Config Scopes

**Objective:** Verify that ace-git-commit automatically creates separate commits when files span multiple configuration scopes.

**Steps:**
1. Make changes in both packages
   ```bash
   cat >> "$TEST_DIR/pkg-a/service.rb" << 'EOF'

  def new_method_a
    "Added to package A"
  end
EOF

   cat >> "$TEST_DIR/pkg-b/service.rb" << 'EOF'

  def new_method_b
    "Added to package B"
  end
EOF
   ```

2. Verify git shows changes in both packages
   ```bash
   git status --porcelain
   ```

3. Run ace-git-commit without --no-split
   ```bash
   ace-git-commit pkg-a/service.rb pkg-b/service.rb -m "Add methods to services"
   ```

4. Verify two separate commits were created
   ```bash
   git log --oneline -3
   ```

5. Verify each commit contains only one package's changes
   ```bash
   echo "=== Commit 1 (HEAD) ==="
   git show --stat HEAD
   echo "=== Commit 2 (HEAD~1) ==="
   git show --stat HEAD~1
   ```

6. Verify files in each commit
   ```bash
   git show --name-only --format="" HEAD | grep -q "pkg-" && echo "PASS: HEAD has package files"
   git show --name-only --format="" HEAD~1 | grep -q "pkg-" && echo "PASS: HEAD~1 has package files"
   ```

**Expected:**
- Exit code: 0
- Two commits created (one per config scope)
- Each commit contains only files from one package
- Commit messages reflect the scope

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Force Single Commit with --no-split

**Objective:** Verify that --no-split flag forces all changes into a single commit regardless of config scopes.

**Steps:**
1. Make changes in both packages
   ```bash
   cat >> "$TEST_DIR/pkg-a/service.rb" << 'EOF'

  def another_method_a
    "Another method in package A"
  end
EOF

   cat >> "$TEST_DIR/pkg-b/service.rb" << 'EOF'

  def another_method_b
    "Another method in package B"
  end
EOF
   ```

2. Verify git shows changes in both packages
   ```bash
   git status --porcelain
   ```

3. Run ace-git-commit with --no-split
   ```bash
   ace-git-commit --no-split pkg-a/service.rb pkg-b/service.rb -m "Add methods to both services"
   ```

4. Verify only one commit was created
   ```bash
   git log --oneline -1
   ```

5. Verify commit contains both packages' changes
   ```bash
   git show --stat HEAD
   ```

6. Verify both files are in the same commit
   ```bash
   git show --name-only --format="" HEAD | grep -c "service.rb"
   # Should show 2
   ```

**Expected:**
- Exit code: 0
- Single commit created
- Commit contains files from both pkg-a and pkg-b

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Path Rules in Project Config

**Objective:** Verify that files are grouped by matching path rules defined in project-level configuration.

**Steps:**
1. Create project-level config with path rules
   ```bash
   mkdir -p "$TEST_DIR/.ace/git"
   cat > "$TEST_DIR/.ace/git/commit.yml" << 'EOF'
model: glite
path_rules:
  - glob: "docs/**"
    model: gflash
  - glob: "test/**"
    model: glite
EOF
   ```

2. Create files matching different path rules
   ```bash
   mkdir -p "$TEST_DIR/docs" "$TEST_DIR/test"

   cat > "$TEST_DIR/docs/guide.md" << 'EOF'
# Guide

Documentation file.
EOF

   cat > "$TEST_DIR/test/service_test.rb" << 'EOF'
# frozen_string_literal: true

class ServiceTest
  def test_run
    assert true
  end
end
EOF
   ```

3. Commit setup
   ```bash
   git add .
   git commit -m "Add config with path rules and initial files"
   ```

4. Modify both files
   ```bash
   cat >> "$TEST_DIR/docs/guide.md" << 'EOF'

## Additional Section

More documentation content.
EOF

   cat >> "$TEST_DIR/test/service_test.rb" << 'EOF'

  def test_another
    assert_equal 1, 1
  end
EOF
   ```

5. Run ace-git-commit without --no-split
   ```bash
   ace-git-commit docs/guide.md test/service_test.rb -m "Update docs and tests"
   ```

6. Verify files were grouped by path rules
   ```bash
   git log --oneline -3
   git show --stat HEAD
   git show --stat HEAD~1
   ```

**Expected:**
- Exit code: 0
- Files grouped according to path rule globs
- docs/guide.md in one commit (gflash scope)
- test/service_test.rb in another commit (glite scope)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Dry-Run Shows Split Plan

**Objective:** Verify that dry-run mode displays the planned commit groups without actually committing.

**Steps:**
1. Make changes in multiple scopes
   ```bash
   cat >> "$TEST_DIR/pkg-a/service.rb" << 'EOF'

  def dry_run_method_a
    "Testing dry run"
  end
EOF

   cat >> "$TEST_DIR/pkg-b/service.rb" << 'EOF'

  def dry_run_method_b
    "Testing dry run"
  end
EOF
   ```

2. Capture initial HEAD commit
   ```bash
   INITIAL_HEAD=$(git rev-parse HEAD)
   echo "Initial HEAD: $INITIAL_HEAD"
   ```

3. Run ace-git-commit in dry-run mode
   ```bash
   ace-git-commit -n pkg-a/service.rb pkg-b/service.rb -m "Dry run test"
   ```

4. Verify no commits were created
   ```bash
   CURRENT_HEAD=$(git rev-parse HEAD)
   [ "$INITIAL_HEAD" = "$CURRENT_HEAD" ] && echo "PASS: No commits created" || echo "FAIL: Commits were created"
   ```

5. Verify files remain modified
   ```bash
   git status --porcelain | grep -q "pkg-a/service.rb" && echo "PASS: pkg-a changes remain"
   git status --porcelain | grep -q "pkg-b/service.rb" && echo "PASS: pkg-b changes remain"
   ```

**Expected:**
- Exit code: 0
- Output shows planned commit groups
- No actual commits created (HEAD unchanged)
- Modified files remain in working directory

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Single Config Scope Does Not Split

**Objective:** Verify that files within a single config scope are committed together without splitting.

**Steps:**
1. Create additional file in pkg-a
   ```bash
   cat > "$TEST_DIR/pkg-a/helper.rb" << 'EOF'
# frozen_string_literal: true

class HelperA
  def assist
    "Helper in package A"
  end
end
EOF
   git add pkg-a/helper.rb
   git commit -m "Add helper file"
   ```

2. Modify multiple files in the same package
   ```bash
   cat >> "$TEST_DIR/pkg-a/service.rb" << 'EOF'

  def single_scope_method
    "Same scope test"
  end
EOF

   cat >> "$TEST_DIR/pkg-a/helper.rb" << 'EOF'

  def additional_help
    "More help"
  end
EOF
   ```

3. Run ace-git-commit
   ```bash
   ace-git-commit pkg-a/service.rb pkg-a/helper.rb -m "Update pkg-a files"
   ```

4. Verify only one commit was created
   ```bash
   git log --oneline -1
   ```

5. Verify both files are in the same commit
   ```bash
   git show --stat HEAD
   git show --name-only --format="" HEAD | wc -l
   # Should show 2 files
   ```

**Expected:**
- Exit code: 0
- Single commit created (no splitting)
- Both pkg-a files in the same commit

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Config Cascade with Gem Defaults (Compound Source Path)

**Objective:** Verify that scope derivation works correctly when config sources include cascade paths (e.g., `pkg/.ace/git/commit.yml -> .ace-defaults/git/commit.yml`). This tests the fix for the compound source path bug where `.ace-defaults` in the cascade caused incorrect scope names.

**Background:** When FileConfigResolver resolves configs, it creates cascade paths like:
```
/project/pkg-a/.ace/git/commit.yml -> /gem/.ace-defaults/git/commit.yml
```
The scope derivation must extract only the PRIMARY source (before " -> ") to determine the package name.

**Steps:**
1. Create a mock .ace-defaults directory to simulate gem defaults cascade
   ```bash
   mkdir -p "$TEST_DIR/.ace-defaults/git"
   cat > "$TEST_DIR/.ace-defaults/git/commit.yml" << 'EOF'
# Gem defaults - simulates ace-git-commit/.ace-defaults
model: glite
conventions:
  format: conventional
EOF
   ```

2. Create two packages with minimal configs that will cascade with defaults
   ```bash
   mkdir -p "$TEST_DIR/pkg-alpha/.ace/git" "$TEST_DIR/pkg-beta/.ace/git"

   # Minimal config - will cascade with .ace-defaults
   cat > "$TEST_DIR/pkg-alpha/.ace/git/commit.yml" << 'EOF'
model: gflash
EOF

   cat > "$TEST_DIR/pkg-beta/.ace/git/commit.yml" << 'EOF'
model: gpro
EOF
   ```

3. Create source files in each package
   ```bash
   cat > "$TEST_DIR/pkg-alpha/main.rb" << 'EOF'
# frozen_string_literal: true

class AlphaMain
  def run
    "Alpha package"
  end
end
EOF

   cat > "$TEST_DIR/pkg-beta/main.rb" << 'EOF'
# frozen_string_literal: true

class BetaMain
  def run
    "Beta package"
  end
end
EOF
   ```

4. Commit initial structure
   ```bash
   git add .
   git commit -m "Add packages with cascade configs"
   ```

5. Modify files in both packages
   ```bash
   cat >> "$TEST_DIR/pkg-alpha/main.rb" << 'EOF'

  def cascade_test
    "Testing config cascade"
  end
EOF

   cat >> "$TEST_DIR/pkg-beta/main.rb" << 'EOF'

  def cascade_test
    "Testing config cascade"
  end
EOF
   ```

6. Run ace-git-commit (should auto-split by package)
   ```bash
   ace-git-commit pkg-alpha/main.rb pkg-beta/main.rb -m "Test cascade config"
   ```

7. Verify two separate commits were created with correct scope names
   ```bash
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Commit 1 (HEAD) scope check ==="
   git show --stat HEAD
   git show --name-only --format="" HEAD | head -1

   echo "=== Commit 2 (HEAD~1) scope check ==="
   git show --stat HEAD~1
   git show --name-only --format="" HEAD~1 | head -1
   ```

8. Verify scope names are package names (not "project default")
   ```bash
   # Check that commits reference the correct packages
   COMMIT1_FILE=$(git show --name-only --format="" HEAD | head -1)
   COMMIT2_FILE=$(git show --name-only --format="" HEAD~1 | head -1)

   echo "Commit 1 contains: $COMMIT1_FILE"
   echo "Commit 2 contains: $COMMIT2_FILE"

   # Files should be in different packages
   [ "$COMMIT1_FILE" != "$COMMIT2_FILE" ] && echo "PASS: Files in separate commits" || echo "FAIL: Same file in both"
   ```

**Expected:**
- Exit code: 0
- Two commits created (one per package)
- Each commit contains only files from one package (pkg-alpha or pkg-beta)
- Scope names derived from package path, NOT "project default"
- Config cascade with .ace-defaults does not interfere with scope derivation

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: File Moves and Deletions Across Config Scopes

**Objective:** Verify that ace-git-commit correctly picks up file moves (renames) and deletions when they span multiple config scopes. This validates the --no-renames fix that ensures git's rename detection doesn't hide deleted files.

**Background:** When files are moved or directories are renamed, git detects these as renames by default. Without `--no-renames`, `git diff --cached --name-only` collapses a move into just the new path, causing the deleted source path to be excluded from commits.

**Steps:**
1. Create files in both packages
   ```bash
   cat > "$TEST_DIR/pkg-a/to_move.rb" << 'EOF'
# frozen_string_literal: true

class ToMove
  def location
    "Originally in pkg-a"
  end
end
EOF

   cat > "$TEST_DIR/pkg-b/to_delete.rb" << 'EOF'
# frozen_string_literal: true

class ToDelete
  def status
    "Will be deleted"
  end
end
EOF
   git add .
   git commit -m "Add files for move/delete test"
   ```

2. Move file from pkg-a to pkg-b and delete a file from pkg-a
   ```bash
   # Move file (creates deletion in pkg-a, addition in pkg-b)
   git mv pkg-a/to_move.rb pkg-b/moved_file.rb

   # Delete file from pkg-b
   git rm pkg-b/to_delete.rb

   # Also modify an existing file in pkg-a to ensure we have changes in both scopes
   cat >> "$TEST_DIR/pkg-a/service.rb" << 'EOF'

  def move_delete_test
    "Testing move and delete"
  end
EOF
   git add pkg-a/service.rb
   ```

3. Verify git status shows all changes (move shown as rename + delete)
   ```bash
   echo "=== Git status ==="
   git status --porcelain

   echo "=== Staged files (no rename detection) ==="
   git diff --cached --name-only --no-renames
   ```

4. Run ace-git-commit in dry-run to see grouping
   ```bash
   ace-git-commit -n -m "Test move and delete handling"
   ```

5. Run ace-git-commit (should create commits in multiple scopes)
   ```bash
   ace-git-commit -m "Refactor: move file and clean up"
   ```

6. Verify commits include both moved file paths
   ```bash
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Check for deletion of pkg-a/to_move.rb ==="
   git log --all --full-history -- pkg-a/to_move.rb | head -5

   echo "=== Check for addition of pkg-b/moved_file.rb ==="
   git log --all --full-history -- pkg-b/moved_file.rb | head -5

   echo "=== Check for deletion of pkg-b/to_delete.rb ==="
   git log --all --full-history -- pkg-b/to_delete.rb | head -5
   ```

7. Verify file deletion was committed (not lost)
   ```bash
   # Verify files no longer exist
   [ ! -f "$TEST_DIR/pkg-a/to_move.rb" ] && echo "PASS: Source file removed" || echo "FAIL: Source still exists"
   [ ! -f "$TEST_DIR/pkg-b/to_delete.rb" ] && echo "PASS: Deleted file removed" || echo "FAIL: Deleted file still exists"
   [ -f "$TEST_DIR/pkg-b/moved_file.rb" ] && echo "PASS: Moved file exists at destination" || echo "FAIL: Moved file missing"

   # Verify no uncommitted changes remain
   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: All changes committed" || echo "FAIL: Uncommitted changes: $UNCOMMITTED"
   ```

**Expected:**
- Exit code: 0
- All file changes committed (no silently dropped files):
  - pkg-a/to_move.rb deletion committed
  - pkg-b/moved_file.rb addition committed
  - pkg-b/to_delete.rb deletion committed
  - pkg-a/service.rb modification committed
- Changes split across config scopes appropriately
- Working directory clean after commit

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Glob Array Groups .ace Folders Across Packages

**Objective:** Verify that a path rule with glob ARRAY correctly groups all `.ace/**` files from multiple packages into a single "ace-config" commit. This tests the glob array feature (Task 228.04) that enables simplified configuration grouping.

**Background:** In monorepos, `.ace` folders exist in:
- Root: `.ace/git/commit.yml`
- Packages: `pkg-a/.ace/git/commit.yml`, `pkg-b/.ace/git/commit.yml`, etc.

Without glob arrays, each package's `.ace` folder would create a separate commit. With glob arrays, all `.ace/**` files are grouped together.

**Steps:**
1. Create project config with glob ARRAY for ace-config
   ```bash
   mkdir -p "$TEST_DIR/.ace/git"
   cat > "$TEST_DIR/.ace/git/commit.yml" << 'EOF'
model: glite
paths:
  ace-config:
    glob:
      - ".ace/**"
      - "*/.ace/**"
    type_hint: chore
    description: "All ACE configuration files"
EOF
   ```

2. Create .ace folders in multiple packages
   ```bash
   mkdir -p "$TEST_DIR/pkg-a/.ace/git" "$TEST_DIR/pkg-b/.ace/git" "$TEST_DIR/pkg-c/.ace/git"

   cat > "$TEST_DIR/pkg-a/.ace/git/commit.yml" << 'EOF'
model: gflash
EOF

   cat > "$TEST_DIR/pkg-b/.ace/git/commit.yml" << 'EOF'
model: gpro
EOF

   cat > "$TEST_DIR/pkg-c/.ace/git/commit.yml" << 'EOF'
model: glite
EOF
   ```

3. Create source files in packages (non-.ace files)
   ```bash
   cat > "$TEST_DIR/pkg-a/lib.rb" << 'EOF'
# frozen_string_literal: true
class LibA; end
EOF

   cat > "$TEST_DIR/pkg-b/lib.rb" << 'EOF'
# frozen_string_literal: true
class LibB; end
EOF
   ```

4. Commit initial structure
   ```bash
   git add .
   git commit -m "Add packages with .ace configs"
   ```

5. Modify .ace config files in multiple packages AND root
   ```bash
   # Modify root .ace config
   cat >> "$TEST_DIR/.ace/git/commit.yml" << 'EOF'

# Updated configuration
generation:
  temperature: 0.8
EOF

   # Modify pkg-a .ace config
   cat >> "$TEST_DIR/pkg-a/.ace/git/commit.yml" << 'EOF'

# Package A specific settings
conventions:
  format: simple
EOF

   # Modify pkg-b .ace config
   cat >> "$TEST_DIR/pkg-b/.ace/git/commit.yml" << 'EOF'

# Package B specific settings
conventions:
  format: conventional
EOF

   # Modify pkg-c .ace config
   cat >> "$TEST_DIR/pkg-c/.ace/git/commit.yml" << 'EOF'

# Package C specific settings
type_hint: docs
EOF
   ```

6. Also modify a non-.ace file to verify separation
   ```bash
   cat >> "$TEST_DIR/pkg-a/lib.rb" << 'EOF'

  def glob_array_test
    "Testing glob arrays"
  end
EOF
   ```

7. Verify git shows changes in multiple .ace folders
   ```bash
   echo "=== Changed files ==="
   git status --porcelain
   echo "=== .ace files specifically ==="
   git status --porcelain | grep "\.ace/"
   ```

8. Run ace-git-commit (should auto-split)
   ```bash
   ace-git-commit -m "Update configurations"
   ```

9. Verify commit grouping
   ```bash
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Files in HEAD commit ==="
   git show --name-only --format="" HEAD

   echo "=== Files in HEAD~1 commit ==="
   git show --name-only --format="" HEAD~1
   ```

10. Verify all .ace files are in ONE commit (ace-config scope)
    ```bash
    # Count .ace files in HEAD commit
    ACE_FILES_HEAD=$(git show --name-only --format="" HEAD | grep -c "\.ace/" || echo 0)

    # Count .ace files in HEAD~1 commit
    ACE_FILES_PREV=$(git show --name-only --format="" HEAD~1 | grep -c "\.ace/" || echo 0)

    echo "HEAD has $ACE_FILES_HEAD .ace files"
    echo "HEAD~1 has $ACE_FILES_PREV .ace files"

    # One commit should have ALL .ace files (4 total), other should have 0
    if [ "$ACE_FILES_HEAD" -eq 4 ] || [ "$ACE_FILES_PREV" -eq 4 ]; then
      echo "PASS: All .ace files grouped in single commit"
    else
      echo "FAIL: .ace files split across commits"
    fi
    ```

11. Verify non-.ace file is in separate commit
    ```bash
    # The lib.rb file should be in a different commit than .ace files
    LIB_IN_HEAD=$(git show --name-only --format="" HEAD | grep -c "lib.rb" || echo 0)
    ACE_IN_HEAD=$(git show --name-only --format="" HEAD | grep -c "\.ace/" || echo 0)

    if [ "$LIB_IN_HEAD" -gt 0 ] && [ "$ACE_IN_HEAD" -eq 0 ]; then
      echo "PASS: lib.rb correctly separated from .ace files"
    elif [ "$LIB_IN_HEAD" -eq 0 ] && [ "$ACE_IN_HEAD" -gt 0 ]; then
      echo "PASS: .ace files correctly separated from lib.rb"
    else
      echo "FAIL: lib.rb and .ace files mixed in same commit"
    fi
    ```

**Expected:**
- Exit code: 0
- Two commits created:
  1. "ace-config" scope: Contains ALL 4 .ace files (root + pkg-a + pkg-b + pkg-c)
  2. Package scope: Contains pkg-a/lib.rb
- Glob array `[".ace/**", "*/.ace/**"]` matches all .ace folders
- No .ace files split across multiple commits

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

- [ ] TC-001: Auto-split creates separate commits for different config scopes
- [ ] TC-002: --no-split forces single commit across scopes
- [ ] TC-003: Path rules correctly group files by glob patterns
- [ ] TC-004: Dry-run shows split plan without committing
- [ ] TC-005: Single scope files commit together without splitting
- [ ] TC-006: Config cascade with .ace-defaults derives correct scope names
- [ ] TC-007: File moves and deletions correctly picked up across scopes
- [ ] TC-008: Glob array groups all .ace folders into single ace-config commit

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Task 228 implements path-based configuration splitting
- Split behavior is automatic when files span multiple config scopes
- Use --no-split to force single commit behavior
- Path rules in config files define grouping by glob patterns
- Dry-run mode (-n) should display planned groups for verification
