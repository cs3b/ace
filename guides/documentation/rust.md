# Rust Documentation Examples

This file provides Rust-specific examples related to the main [Documentation Standards Guide](../documentation.md).

*   **Tools:** `cargo doc`, `rustdoc`
*   **Conventions:** Markdown within `///` or `//!` comments.

```rust
/// Creates a new user.
///
/// # Arguments
///
/// * `name` - A string slice that holds the name of the user.
///
/// # Returns
///
/// A `User` object.
///
/// # Errors
///
/// Returns an error if the name is invalid.
///
/// # Examples
///
/// ```
/// let user = create_user("Alice").unwrap();
/// ```
pub fn create_user(name: &str) -> Result<User, Error> {
    // ... implementation ...
    unimplemented!() // Placeholder
}

struct User { /* ... */ }
struct Error { /* ... */ }
```
