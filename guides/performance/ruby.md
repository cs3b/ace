# Ruby Performance Examples

This file provides Ruby-specific examples related to the main [Performance Guide](../performance.md).

*   **Benchmarking:** `Benchmark` standard library module.
*   **Profiling:** `stackprof`, `ruby-prof` gems.
*   **Memory Analysis:** `memory_profiler` gem.

```ruby
require 'benchmark'

iterations = 100_000

Benchmark.bm(7) do |x|
  x.report("String Interpolation:") { iterations.times do; "User ID: #{123}"; end }
  x.report("String Concat:")      { iterations.times do; 'User ID: ' + 123.to_s; end }
end

# Example using stackprof (conceptual)
# require 'stackprof'
# StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu.dump') do
#   # Code to profile
#   1000.times { perform_complex_operation }
# end
```
