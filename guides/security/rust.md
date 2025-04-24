# Rust Security Examples

This file provides Rust-specific examples related to the main [Security Guide](../security.md).

*   **Dependency Scanning:** `cargo audit`, GitHub Dependabot
*   **Static Analysis (SAST):** `cargo clippy` (catches some security issues), potentially external SAST tools.
*   **Input Validation:** Using Rust's type system, crates like `validator`.
*   **Secure Configuration:** Environment variables, configuration files with restricted permissions, secrets management services.
*   **Memory Safety:** Rust's core safety features prevent many common vulnerabilities (e.g., buffer overflows, use-after-free).

```rust
use std::path::{Path, PathBuf};
use std::fs;
use std::io;

// Example: Secure file path handling
fn get_safe_path(base_dir: &Path, user_input: &str) -> io::Result<PathBuf> {
    let joined_path = base_dir.join(user_input);
    // Canonicalize resolves '..' and symlinks
    let canonical_path = fs::canonicalize(&joined_path)?;

    // Ensure the canonical path is still within the base directory
    if canonical_path.starts_with(base_dir) {
        Ok(canonical_path)
    } else {
        Err(io::Error::new(
            io::ErrorKind::PermissionDenied,
            format!("Path traversal attempt detected: {}", user_input),
        ))
    }
}

fn main() -> io::Result<()> {
    let base = PathBuf::from("/safe/base/path");
    // Simulate creating the directory if it doesn't exist for the example
    // fs::create_dir_all(&base)?;

    let user_input = "safe_file.txt";
    match get_safe_path(&base, user_input) {
        Ok(path) => println!("Accessing safe path: {:?}", path),
        Err(e) => eprintln!("Error: {}", e),
    }

    let malicious_input = "../outside_file.txt";
    match get_safe_path(&base, malicious_input) {
        Ok(path) => println!("Accessing malicious path: {:?}", path),
        Err(e) => eprintln!("Error: {}", e), // Should print PermissionDenied error
    }
    Ok(())
}
```
