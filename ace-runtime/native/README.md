# Native worker bootstrap (retired from the file-based flow)

The `ace-runtime` gem still ships `native/worker_gate.c` and
`native/build-worker-gate` from the replaced protected model. They are not part
of the current file-based flow: no command, task, assignment, or local
documentation requires the native gate, its authority file, or its admission
checks.

Do not treat this directory as an owner of execution state. The supported
`ace-runtime` surface is the terminal intent contract described in the
[README](../README.md) and [usage](../docs/usage.md). Removal or redesign of the
native bootstrap is tracked with the L1/L2 cleanup; this note keeps the
historical source discoverable without presenting it as a requirement.
