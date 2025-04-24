# Rust Performance Examples

This file provides Rust-specific examples related to the main [Performance Guide](../performance.md).

*   **Benchmarking:** `cargo bench` (requires nightly toolchain or stable with `criterion` crate), `std::time::Instant`.
*   **Profiling:** `perf` (Linux), Instruments (macOS), `cargo flamegraph`, `pprof` crate.
*   **Memory Analysis:** Valgrind (with caution), `dhat` crate, platform-specific tools.

```rust
use std::time::Instant;

// Simple timing using std::time::Instant
fn main() {
    let start = Instant::now();

    // Code to measure
    let mut sum = 0;
    for i in 0..1_000_000 {
        sum += i;
    }

    let duration = start.elapsed();

    println!("Time elapsed in expensive_function() is: {:?}", duration);
    println!("Sum: {}", sum); // Prevent optimization from removing the loop
}

// For proper benchmarking, use `cargo bench` with `criterion` crate
// Example (in benches/my_benchmark.rs):
/*
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n-1) + fibonacci(n-2),
    }
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(black_box(20))));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
*/
```
