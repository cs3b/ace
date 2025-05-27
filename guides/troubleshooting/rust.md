# Rust Troubleshooting

Specific tools and techniques for debugging Rust applications.

### Core tools & tips

* **Turn on backtraces**: `RUST_BACKTRACE=1 cargo run` prints a full panic trace.  
* **Native debuggers**  
  * `rust-gdb` for GNU Debugger workflow with Rust pretty‑printers.  
  * `rust-lldb` (LLVM) for macOS or LLDB fans.  
* **IDE integration** – VS Code `code-lldb` or CLion give graphical breakpoints & variable views.  
* **Build in debug mode** (`cargo build`) to keep symbols; switch to `--release` only after reproducing.  
* **Common probes**: `dbg!()` macro, `println!("{:?}", var)`; run unit tests with `cargo test -- --nocapture`.

### Quick diagnostic checklist

1. Run failing binary with `RUST_BACKTRACE=full`.  
2. In LLDB: `break set -n function_name`, `run`, `frame variable`, `next`.  
3. Suspect UB? Compile with address sanitizer (`-Zsanitizer=address`) or use Clippy’s `pedantic` lints.  
4. Threading issues – `cargo flamegraph` or `tokio-console` for async bottlenecks.
