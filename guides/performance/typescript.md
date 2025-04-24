# TypeScript Performance Examples

This file provides TypeScript-specific examples related to the main [Performance Guide](../performance.md).

*   **Benchmarking:** `console.time`/`console.timeEnd`, `performance.now()` (Node.js/Browser), libraries like `benchmark.js`.
*   **Profiling:** Node.js inspector (`node --inspect`), Chrome DevTools profiler.
*   **Memory Analysis:** Node.js inspector, Chrome DevTools memory tab.

```typescript
// Simple benchmarking using console.time
const iterations = 100000;

console.time('Array Push');
const arr1: number[] = [];
for (let i = 0; i < iterations; i++) {
  arr1.push(i);
}
console.timeEnd('Array Push');

console.time('Array Pre-alloc');
const arr2: number[] = new Array(iterations);
for (let i = 0; i < iterations; i++) {
  arr2[i] = i;
}
console.timeEnd('Array Pre-alloc');

// Using performance.now() (more precise, available in Node and Browsers)
const start = performance.now();
// Code to measure
const end = performance.now();
console.log(`Execution time: ${end - start} ms`);
```
