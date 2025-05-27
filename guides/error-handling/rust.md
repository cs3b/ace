# Rust Error Handling Examples

This file provides Rust-specific examples related to the main [Error Handling Guide](../error-handling.md).

* **Mechanisms:** `Result<T, E>` enum for recoverable errors, `panic!` macro for unrecoverable errors.
* **Libraries:** `thiserror`, `anyhow` for custom error types and convenience.

```rust
use std::fmt;

// Example using standard library Result and Box<dyn Error>
fn do_something(input: &str) -> Result<String, Box<dyn std::error::Error>> {
    if input.is_empty() {
        return Err("Input cannot be empty".into()); // Simple error conversion
    }
    // ... potentially complex logic ...
    Ok(format!("Processed {}", input))
}

// Example custom error enum (could use 'thiserror' crate for convenience)
#[derive(Debug)]
enum ProcessingError {
    InvalidInput(String),
    InternalError(String),
}

impl fmt::Display for ProcessingError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            ProcessingError::InvalidInput(msg) => write!(f, "Invalid Input: {}", msg),
            ProcessingError::InternalError(msg) => write!(f, "Internal Error: {}", msg),
        }
    }
}

impl std::error::Error for ProcessingError {}

fn do_something_custom(input: &str) -> Result<String, ProcessingError> {
    if input.is_empty() {
        return Err(ProcessingError::InvalidInput("Input was empty".to_string()));
    }
    // ...
    Ok(format!("Processed {}", input))
}

fn main() {
    match do_something_custom("") {
        Ok(result) => println!("Success: {}", result),
        Err(e) => println!("Error: {}", e),
    }

    // Example of propagating errors with `?` operator
    let result = do_something_custom("valid").expect("Should succeed");
    println!("Result via expect: {}", result);

    // Panics for unrecoverable errors (use sparingly)
    // panic!("This is an unrecoverable error!");
}
```
