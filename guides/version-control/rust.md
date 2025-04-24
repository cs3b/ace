# Rust Version Control Examples

This file provides Rust-specific examples and considerations related to the main [Version Control Guide](../version-control.md).

*   **.gitignore:** Ensure the standard Rust build directory (`target/`) is ignored. Tools like [gitignore.io](https://www.toptal.com/developers/gitignore) are helpful.
*   **Pre-commit Hooks:** Use tools like `husky` (if in a mixed project or preferred) or simple shell script hooks (`.git/hooks/pre-commit`) to run the formatter (`cargo fmt --check`) and linter (`cargo clippy -- -D warnings`) before committing.
*   **Dependency Locking:** Always commit `Cargo.lock` to ensure reproducible builds and consistent dependencies.
*   **Branching Strategy:** Standard Git workflows apply.

```sh
#!/bin/sh
# Example .git/hooks/pre-commit script for Rust

echo "Running pre-commit hook..."

# Check formatting
cargo fmt --check
if [ $? -ne 0 ]; then
  echo "Code formatting issues found. Run 'cargo fmt' to fix."
  exit 1
fi

# Check linting (deny warnings)
cargo clippy -- -D warnings
if [ $? -ne 0 ]; then
  echo "Clippy issues found. Address them before committing."
  exit 1
fi

# Optionally run tests
# cargo test
# if [ $? -ne 0 ]; then
#   echo "Tests failed. Fix tests before committing."
#   exit 1
# fi

echo "Pre-commit checks passed."
exit 0
```

```gitignore
# Example additions to .gitignore for a Rust project
/target
```

**Note:** Make the pre-commit script executable: `chmod +x .git/hooks/pre-commit`.
