# Phase 3: Execution Loop (Engineer & Tester)

## Goal
To implement the approved `spec.md` and verify it with tests, iterating until success or a retry limit is reached.

## The Loop Logic

This is the core "Resilient Loop" of the Overseer.

### Step 3.1: Engineering (Implementation)
*   **Role**: Engineer Worker.
*   **Input**: `spec.md`, Current Codebase, (Optional) Previous Test Failures.
*   **Action**: Write code, create/modify files.
*   **Goal**: "Implement the spec."

### Step 3.2: Verification (Testing)
*   **Role**: Tester Worker.
*   **Input**: The specific tests defined in the plan or relevant to the changes.
*   **Action**: Run `ace-test` (or specific test command).
*   **Output**: Pass/Fail Report + Error Logs.

### Step 3.3: The Decision (Overseer Logic)
The Overseer evaluates the Tester's Report:

*   **IF PASS**:
    *   Transition to **Phase 4 (Final Review)**.
*   **IF FAIL**:
    *   Check **Retry Count**.
    *   **IF Retries Available**:
        *   Prepare "Feedback Context" (Error logs, specific failure details).
        *   **GOTO Step 3.1** (Call Engineer again to fix).
    *   **IF Retries Exhausted**:
        *   **PAUSE**.
        *   State: `error: max_retries_exceeded`.
        *   Notify User (Coworker).

## Context Hygiene
Critically, between iterations, the Overseer manages what the Engineer sees. The Engineer should see "The Spec" + "The Error", not the entire chat history of the previous 5 failed attempts, to prevent context pollution.
