---
title: Implement ace-support-timestamp for Precise Sequential Timestamps
filename_suggestion: feat-core-precise-seq-ts
enhanced_at: 2026-01-19 14:28:30
location: active
llm_model: gflash
---

# Implement ace-support-timestamp for Precise Sequential Timestamps

## Problem
ACE tools (like `ace-lint` for report generation, `ace-taskflow` for task IDs, and `ace-bundle` for session caching) require highly deterministic, precise, and consistently formatted timestamps. Standard Ruby time utilities often lack the necessary precision (down to microseconds or nanoseconds) and the ability to generate sequential identifiers starting from a specific point. This leads to inconsistent timestamp implementation across different ACE gems, hindering reliable sorting and agent processing of time-sensitive data.

## Solution
Introduce the `ace-support-timestamp` gem, an infrastructure component providing a robust, configurable utility for generating high-precision, deterministic timestamps. This gem will expose a CLI (`ace-timestamp`) that supports custom formatting optimized for file system sorting and agent consumption, as well as the critical ability to generate a sequence of future timestamps.

## Implementation Approach

1.  **Gem Structure:** Follow the `ace-support-*` pattern (`docs/ace-gems.g.md`) for infrastructure, with the CLI binary named `ace-timestamp`.
2.  **ATOM Architecture:**
    *   **Atoms:** Implement pure functions for calculating custom date/time components (e.g., specific week/month formats as requested in the idea) and handling high-precision time formatting (e.g., 1.85 second precision implies microsecond or nanosecond formatting).
    *   **Molecules:** A `SequentialTimestampGenerator` molecule responsible for taking a base time, applying the configured format, and calculating the next N sequential timestamps.
3.  **CLI Interface:** The `ace-timestamp` CLI will support:
    *   Default output: `ace-timestamp` (outputs current high-precision timestamp).
    *   Sequential output: `ace-timestamp --next 5 [--start-time YYYYMMDD-HHMMSS]` (outputs the next 5 timestamps based on the smallest unit of precision in the format).
4.  **Configuration:** Use the Configuration Cascade (ADR-022) to allow users to define default formats and precision levels via `.ace/timestamp/config.yml`.

## Considerations
- **Precision:** Define a standard format that guarantees uniqueness within a short time window (e.g., `YYYYMMDD-HHMMSS.uuuuuu`).
- **Custom Formats:** Ensure the custom month/week/day formats are clearly documented and deterministic for agent use.
- **Integration:** Update gems like `ace-lint` and `ace-taskflow` to utilize `ace-timestamp` for session/task ID generation, replacing existing ad-hoc timestamp logic.

## Benefits
- **Consistency:** Standardizes timestamp generation across the entire ACE ecosystem.
- **Determinism:** Provides predictable, sortable identifiers crucial for agent workflows and file system management.
- **Agent Utility:** The `--next N` feature is highly valuable for agents planning sequential operations or generating batches of task IDs.

---

## Original Idea

```
ace-support-timestamp - add suport for months (first two), weeks (3, but the third one use 32-36 as week numbers, iso week numbers (we don't need them for days), days ( 3-rd one is 1-31 ), hours, and the default one 1.85 second precision timestamp ) - also add abilityt to generate next tokeks starting from (the passed date) --next 5 

* e671dd352 feat(ace-lint): add JSON report generation with timestamped directories
* 8dd21f6fc refactor(ace-lint): add thread-safety to ConfigLocator cache
* 5b9da0354 style(ace-lint): update code to RuboCop modern Ruby syntax
* 159714a2d style(ace-lint): update require paths and dependencies for consistency
* d2844612b feat(lint): extract BaseRunner and improve Ruby linter support
```