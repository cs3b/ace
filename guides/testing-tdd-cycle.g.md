# Implementing the Task Cycle

## 1. Introduction

This guide outlines the standard development cycle used for implementing tasks within this project. Following this cycle
ensures consistency, promotes quality through testing, and facilitates effective collaboration, especially when working
with AI agents. It integrates principles of Test-Driven Development (TDD) and emphasizes continuous reflection.

## 2. The Core Cycle Overview

The typical task implementation follows these high-level steps:

1. **Start:** Understand the task and plan the approach.
2. **Test (Red):** Write a failing test that defines the desired outcome.
3. **Code (Green):** Write the minimum code required to make the test pass.
4. **Refactor:** Improve the code's design while ensuring tests still pass.
5. **Verify:** Run all checks (linters, formatters, full test suite).
6. **Commit:** Save the changes with a clear, conventional commit message.
7. **Reflect:** Analyze the process and capture learnings.
8. **Update Status:** Mark the task as complete or note progress.

This cycle (steps 2-4) may be repeated multiple times for a single task as functionality is built incrementally.

## 3. Detailed Steps

Here's a more detailed breakdown of each step, referencing relevant workflow instructions:

### Step 1: Start Task (Understand & Plan)

* **Goal:** Fully understand the task requirements and plan the implementation approach.
* **Actions:**
  * Carefully review the task description (`.md` file) including objectives, scope, and acceptance criteria.
  * Identify relevant existing code, patterns, or documentation.
  * Break down the task into smaller, manageable implementation steps.
  * Outline the required tests based on acceptance criteria.
* **Workflow:** See [`work-on-task.wf.md`](dev-handbook/workflow-instructions/work-on-task.wf.md)

### Step 2: Write Tests (TDD - Red)

* **Goal:** Define the desired behavior or functionality by writing an automated test *before* writing the
  implementation code.
* **Actions:**
  * Create a new test file or add to an existing one.
  * Write a specific test case that captures one aspect of the requirement.
  * Ensure the test clearly describes the expected outcome.
  * Run the test and confirm that it **fails** (this is the "Red" phase).
* **Workflow:** See the testing section in [`work-on-task.wf.md`](dev-handbook/workflow-instructions/work-on-task.wf.md)

### Step 3: Implement Code (TDD - Green)

* **Goal:** Write the simplest, minimum amount of code necessary to make the failing test pass.
* **Actions:**
  * Focus *only* on satisfying the requirements of the current failing test.
  * Avoid adding extra functionality or premature optimizations.
  * Run the test(s) frequently until the target test passes (this is the "Green" phase).

### Step 4: Refactor (TDD - Refactor)

* **Goal:** Improve the design, clarity, and structure of the code *now that it works* (tests are passing).
* **Actions:**
  * Look for opportunities to remove duplication, improve variable names, simplify logic, or adhere better to coding
    standards.
  * Run tests after each small refactoring step to ensure no behavior was broken.
* **Reference:** [Coding Standards](dev-handbook/guides/coding-standards.g.md)

### Step 5: Verify Locally

* **Goal:** Ensure the changes integrate well and meet overall quality standards before committing.
* **Actions:**
  * Run the full test suite (not just the tests for the current change).
  * Run linters and code formatters.
  * Check test coverage if applicable.

### Step 6: Commit Changes

* **Goal:** Save the completed, tested, and verified changes to version control with a meaningful message.
* **Actions:**
  * Stage only the files related to the logical change being committed (atomic commits).
  * Review staged changes (`git diff --staged`).
  * **Critically review any AI-generated code before committing.**
  * Write a commit message following the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    standard.
* **Workflow:** See [`commit.wf.md`](dev-handbook/workflow-instructions/commit.wf.md)
* **Reference:** [Version Control Guide](dev-handbook/guides/version-control-system.g.md)

### Step 7: Self-Reflection

* **Goal:** Analyze the completed work to capture learnings and identify potential improvements.
* **Actions:**
  * Review the implementation process, challenges, and successes.
  * Update documentation (guides, ADRs, comments) if necessary.
  * Identify any follow-up actions (e.g., refactoring needs, process improvements) and create backlog tasks if
    needed.
  * Log the reflection summary using the [`create-reflection-note.wf.md`](dev-handbook/workflow-instructions/create-reflection-note.wf.md) workflow.

### Step 8: Update Task Status

* **Goal:** Keep project tracking up-to-date.
* **Actions:**
  * Update the status field (e.g., to `done`) in the task's `.md` file.
  * Move the task file to the appropriate `done` directory if applicable (refer to project management
    specifics).
* **Reference:** [Project Management Guide](dev-handbook/guides/project-management.g.md)

## 4. Key Principles & Best Practices

* **Test-Driven Development:** Writing tests first drives design and ensures testability.
* **Atomic Commits:** Each commit should represent a single, logical change.
* **Review AI Contributions:** Treat AI-generated code with the same rigor as code from any other source. Verify its
  correctness and adherence to standards.
* **Incremental Progress:** Build functionality in small, testable steps.
* **Continuous Improvement:** Use the self-reflection step to actively improve code and processes.

## 5. Technology-Specific Variations

While the core cycle remains the same, specific commands and tools vary by technology stack. Refer to the relevant
sub-guide for details:

* [Ruby Application](dev-handbook/guides/test-driven-development-cycle/ruby-application.md)
* [Ruby Gem](dev-handbook/guides/test-driven-development-cycle/ruby-gem.md)
* [Rust CLI](dev-handbook/guides/test-driven-development-cycle/rust-cli.md)
* [Rust→Wasm Zed Extension](dev-handbook/guides/test-driven-development-cycle/rust-wasm-zed.md)
* [TypeScript + Vue](dev-handbook/guides/test-driven-development-cycle/typescript-vue.md)
* [TypeScript + Nuxt](dev-handbook/guides/test-driven-development-cycle/typescript-nuxt.md)
* [Meta (Documentation)](dev-handbook/guides/test-driven-development-cycle/meta-documentation.md)

## 6. Related Documentation

* **Workflow Instructions:**
  * [`work-on-task.wf.md`](dev-handbook/workflow-instructions/work-on-task.wf.md) (includes testing guidance)
  * [`commit.wf.md`](dev-handbook/workflow-instructions/commit.wf.md)
  * [`save-session-context.md`](dev-handbook/workflow-instructions/save-session-context.md) (for saving session context)
* **Core Guides:**
  * [Testing Guide](dev-handbook/guides/testing.g.md)
  * [Version Control Guide](dev-handbook/guides/version-control-system.g.md)
  * [Coding Standards](dev-handbook/guides/coding-standards.g.md)
  * [Project Management Guide](dev-handbook/guides/project-management.g.md)
