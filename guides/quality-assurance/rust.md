# Rust Quality Assurance Examples

This file provides Rust-specific examples related to the main [Quality Assurance Guide](../quality-assurance.md).

* **Linters/Formatters:** `rustfmt`, `clippy` (run via `cargo fmt` and `cargo clippy`)
* **Static Analysis:** Rust compiler itself catches many issues; `cargo audit` for security vulnerabilities in dependencies.
* **Test Coverage:** `cargo-tarpaulin`, `grcov`
* **CI Configuration:** Examples for GitHub Actions, GitLab CI using Rust toolchain setup actions.

**Example `rustfmt.toml` (Configuration for rustfmt):**

```toml
# Example rustfmt configuration
max_width = 100
use_small_heuristics = "Max"
# imports_granularity = "Crate"
```

**Example `clippy.toml` (Configuration for clippy):**

```toml
# Example clippy configuration
# Disallow specific lints globally
disallowed-methods = [
    # Example: discourage Option::unwrap
    # "std::option::Option::unwrap",
]

# Set complexity limits
cyclomatic-complexity-threshold = 30
```

**Example CI step for checking formatting and linting:**

```yaml
- name: Check Formatting
  run: cargo fmt --all -- --check

- name: Check Lints
  run: cargo clippy --all-targets -- -D warnings # Fail on warnings
```
