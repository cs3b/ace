# Question: Worker Interface Protocol

## The Problem
The Overseer needs to "call" a worker (e.g., an LLM agent, a script, or a human). This call must be standardized so the Overseer doesn't need to know *who* is doing the work, just *what* needs to be done.

## Proposed Solution: File-Based IO

A "Function Call" to a worker consists of preparing a directory with inputs and reading outputs.

### Input
*   `instruction.md`: The specific prompt or task.
*   `context/`: A folder containing necessary files (read-only for the worker).

### Invocation
```bash
# Example
ace-worker run --role architect --input ./input-dir --output ./output-dir
```

### Output
*   `report.md`: A summary of what was done.
*   `artifacts/`: Generated files (e.g., `spec.md`).
*   `exit_code`: 0 for success, non-zero for failure.

## Questions to Answer
1.  **Tool Access**: Does the worker have access to the full file system, or is it sandboxed? (Likely full FS access for "Engineer", but maybe restricted for "Architect").
2.  **Streaming**: Do we need to stream logs from the worker to the Overseer (and then to the Coworker UI)?
