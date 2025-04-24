# Rust Release Process Examples

This file provides Rust-specific examples related to the main [Release Process Guide](../ship-release.md).

*   **Packaging:** `Cargo.toml`
*   **Building:** `cargo build --release` (compiles optimized binary)
*   **Publishing:** `cargo publish` (to crates.io or private registry)
*   **Versioning:** Update version in `Cargo.toml`, `CHANGELOG.md`
*   **Tagging:** `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
*   **Linting/Formatting:** `cargo fmt`, `cargo clippy`

```bash
# Example release workflow steps

# Ensure tests pass
cargo test

# Check formatting and linting
cargo fmt --check
cargo clippy -- -D warnings

# Update version number in Cargo.toml and CHANGELOG.md
# ... manual or script update ...

# Commit version bump
git add Cargo.toml CHANGELOG.md src/ # Add other relevant files
git commit -m "chore(release): Prepare release vX.Y.Z"

# Build the crate (optional, often done by publish)
cargo build --release

# Tag the release
git tag -a vX.Y.Z -m "Release version X.Y.Z"

# Push changes and tags
git push origin main vX.Y.Z

# Publish the crate to crates.io
# cargo login (if needed)
cargo publish
```

**Note:** Tools like `cargo-release` can help automate parts of this process.
