---
title: Enhance ace-support-timestamp with Granular and High-Precision Formats
filename_suggestion: feat-timestamp-format-precision
enhanced_at: 2026-01-18 01:12:17.000000000 +00:00
location: done
task_id: v.0.9.0+task.225
llm_model: gflash
id: 8oilpn
status: done
tags: []
created_at: '2026-01-19 14:28:29'
---

# Enhance ace-support-timestamp with Granular and High-Precision Formats

## Problem
ACE relies on deterministic, consistent time representations for internal operations such as cache key generation (`ace-bundle`), session tracking (`PromptCacheManager`), and task slug creation (`ace-taskflow`). The current standard timestamp utilities often lack the specific granularity or custom formats required for advanced workflows (e.g., fiscal week tracking or microsecond-level performance logging).

We need a robust, configurable utility that provides various deterministic time formats optimized for both human readability (DX) and agent parsing (AX).

## Solution
Enhance the `ace-support-timestamp` gem to provide a suite of configurable time formats and precision levels via the `ace-timestamp` CLI tool. This includes:

1.  **Granular Date Components**: Support for outputting months (two-digit), days (1-31), and various week numbering schemes (ISO standard and custom internal formats).
2.  **High-Precision Numeric Timestamp**: Implement a default numeric timestamp with high precision (e.g., 1.85 second precision, typically microsecond or nanosecond epoch time) for use in performance metrics and unique identifier generation.

## Implementation Approach

1.  **ATOM Architecture**: The core logic for calculating and formatting these specific time components (e.g., custom week numbers, high-precision epoch time) will be implemented as pure **Atoms** within `ace-support-timestamp/lib/ace/support/timestamp/atoms/`.
2.  **CLI Interface**: Extend the `ace-timestamp` CLI command to accept format flags (e.g., `--format month`, `--format week-custom`) and a precision option (e.g., `--precision 6` for microseconds).
3.  **Configuration**: Define sensible defaults in `.ace-defaults/timestamp/config.yml`. Allow users to override the default precision or custom week definitions via the Configuration Cascade (`.ace/timestamp/config.yml`).
4.  **Integration**: Update `Ace::Core::Molecules::PromptCacheManager` and potentially `ace-bundle`'s caching mechanisms to optionally utilize the new high-precision timestamp for generating unique, deterministic session directories and cache keys.

## Considerations
-   **Custom Week Logic**: The custom week numbering (e.g., 32-36) must be clearly documented and configurable to ensure determinism and project-specific alignment.
-   **Locale Independence**: All date/time calculations must be locale-independent to adhere to the 'Predictable, deterministic behavior' principle (Core Principle 2: AX).
-   **Backward Compatibility**: Ensure the default `ace-timestamp` output remains compatible with existing tools unless a specific format flag is provided.

## Benefits
-   **Enhanced AX**: Agents can reliably generate and parse timestamps with the exact required granularity, improving scripting reliability.
-   **Improved Debugging**: High-precision timestamps allow for better performance tracking and debugging of multi-step agent workflows.
-   **Flexible Workflows**: Supports complex internal tracking needs (like custom release cycles or reporting periods) within `ace-taskflow` and other reporting tools.

---

## Original Idea

```
ace-support-timestamp - add suport for months (first two), weeks (3, but the third one use 32-36 as week numbers, iso week numbers (we don't need them for days), days ( 3-rd one is 1-31 ), hours, and the default one 1.85 second precision timestamp ) 

lets conver 218 to child of self - so we have base for subtasks

and move all the subtask that we have created as subtask of 218

218 should be bring back from the archive

next add task to review all the adrs and decisions docs - to also do the improvements there
```