# Ruby Troubleshooting

Specific tools and techniques for debugging Ruby applications.

### Core tools & tips

* **Read the stack trace first** – top line shows the crash site, lower lines show the call chain.  
* **Interactive debuggers**  
  * `binding.pry` for a REPL‑style breakpoint.  
  * `byebug` (Ruby ≤ 3.0) or `debug` (Ruby ≥ 3.1) for GDB‑like stepping, breakpoints, watch expressions.  
* **Rails specifics**  
  * Tune log levels (`config.log_level`) and stream to STDOUT when needed.  
  * Use view helpers (`debug`, `inspect`) to dump vars in templates during UI bugs.  
* **Memory leaks** – Valgrind & gems like `memory_profiler`, `derailed_benchmarks`.

### Quick diagnostic checklist

1. Re‑run failing test with `--backtrace` for full context.  
2. Drop `binding.pry` at suspect line, inspect locals, call `ls` to list methods.  
3. If timing‑related, add `Rails.logger.debug` statements and compare dev vs prod logs.  
4. For gem/environment discrepancies, reproduce in a pristine `bundle exec` shell.
