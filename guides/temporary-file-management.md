# AI Agent Temporary File Management Guidelines

This document outlines the guidelines for how the AI agent should create, use, and manage temporary files during its
operations. Adherence to these guidelines ensures a clean working environment, prevents data remnants, and maintains
operational predictability.

## 1. Use Temporary Files Judiciously

Temporary files should be used sparingly and only when necessary. Appropriate scenarios include:

- **Intermediate States:** Storing intermediate results during complex, multi-stage operations (e.g., multi-file
  refactoring, code transformations).
- **Staging Content:** Creating a temporary copy of a file to modify before overwriting the original, especially for
  critical project files. This can help ensure atomicity or provide a simple rollback point for the current operation.
- **Large Data Handling:** Managing data sets that are too large to comfortably fit in memory during processing.
- **Caching:** Storing the results of computationally expensive operations that are likely to be reused within the
  scope of the current task execution.

Avoid using temporary files for small data or simple operations where in-memory handling is sufficient and more
efficient.

## 2. Standard Temporary File Location

- All temporary files and directories created by the AI agent **MUST** be placed within a dedicated sub-directory: `<project_root>/tmp/agent/`.
  - The agent should ensure this directory exists, creating it if necessary.
- If a temporary file is an intermediate version of an existing project file, its path within `tmp/agent/` **SHOULD**
  mirror the original file's path relative to the project root.
  - **Example:** If the agent is working on `<project_root>/src/components/MyComponent.js`, a temporary version should
    be stored as `<project_root>/tmp/agent/src/components/MyComponent.js`.
- For temporary files that do not directly correspond to a specific project file (e.g., a patch file, an aggregated log,
  intermediate calculation results), use a descriptive name directly within the `tmp/agent/` directory or a logically
  named subdirectory therein.
  - **Example:** `tmp/agent/refactor_summary.log`, `tmp/agent/image_processing_stage1/output.dat`.

## 3. Agent Responsibility for Cleanup

- The AI agent is **SOLELY** responsible for the cleanup (i.e., deletion) of any temporary files and directories it
  creates within `tmp/agent/`.
- Temporary files **SHOULD** be deleted as soon as they are no longer needed for the current operation or sub-task.
- All temporary files and directories created during a task **MUST** be cleaned up by the end of that task's execution,
  irrespective of whether the task completed successfully or encountered an error.
  - Implementation of operations that use temporary files should include robust cleanup mechanisms (e.g.,
    `try...finally` blocks or equivalent patterns) to ensure deletion even in error scenarios.

## 4. Naming Conventions for Temporary Files

- **Mirroring Project Files:**
  - When a temporary file directly corresponds to a project file, its name within the mirrored path (see Guideline 2)
    should ideally be the same as the original file.
  - If multiple intermediate versions of the same file are needed sequentially, consider using suffixes (e.g.,
    `filename_tmp_step1.ext`, `filename_backup_timestamp.ext`) or distinct subdirectories within `tmp/agent/` that
    represent stages (e.g., `tmp/agent/stage1/path/to/file.ext`, `tmp/agent/stage2/path/to/file.ext`).
- **Other Temporary Files:**
  - Names should be descriptive of their content, purpose, or the operation that generated them (e.g.,
    `user_input_sanitized.txt`, `api_response_cache.json`, `generated_diff.patch`).
  - Avoid generic names like `temp.txt` or `file1.dat` unless their scope is extremely limited and immediately
    obvious.

## 5. Avoid Sensitive Data

- **DO NOT** store sensitive information (e.g., API keys, passwords, private user data, proprietary configurations) in
  temporary files unless it is absolutely unavoidable.
- If temporary storage of sensitive data is deemed essential:
  - Ensure file permissions are as restrictive as possible.
  - Employ secure deletion methods if available and appropriate for the data's sensitivity.
  - Prioritize in-memory handling or secure, encrypted vaults/environment variables for such data over plaintext
    temporary files.

## 6. Transparency (Optional but Recommended)

- For operations involving significant use of temporary files (e.g., large files, numerous files, or files that persist
  for a noticeable duration), the agent can optionally inform the user about:
  - The creation of temporary files and their purpose.
  - The location of these temporary files.
  - Confirmation of their cleanup upon completion or termination of the operation.
- This is not a strict requirement for every temporary file but can enhance user trust and understanding of the agent's
  actions, especially during complex or lengthy tasks.

## 7. Error Handling and Orphaned Files

- The primary goal is to prevent any orphaned temporary files.
- If, despite best efforts, an error prevents cleanup, subsequent agent runs or a dedicated cleanup utility might be
  needed. However, the agent's design should strive to make this an exceptional case.
- Logging the creation and intended deletion of temporary files can aid in debugging orphaned file scenarios.
