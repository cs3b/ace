# The Master Loop for ACE (Coworker / Overseer)

## 1. Executive Summary

The "Master Loop" in ACE is a hierarchical system designed to orchestrate autonomous engineering work. It separates the concerns of **Environment Management** (`ace-coworker`), **Supervision & Logic** (`ace-overseer`), and **Execution** (`ace-worker` roles).

This architecture ensures that the "Brain" (Overseer) is decoupled from the "Hands" (Workers) and the "Office" (Coworker), allowing for resilient, stateful, and observable autonomous workflows.

## 2. System Taxonomy

### 2.1 `ace-coworker`: The Session Manager (The Office)
*   **Role**: Container & Environment Manager.
*   **Responsibility**:
    *   **Session Lifecycle**: Creates, lists, and destroys sessions.
    *   **Isolation**: Spawns and manages Git Worktrees (`.ace/coworker/<id>`).
    *   **Dashboard**: Provides the TUI (User Interface) to view all active sessions.
    *   **Identity**: "I am the platform you interact with."

### 2.2 `ace-overseer`: The Supervisor (The Brain)
*   **Role**: State Machine & Orchestrator.
*   **Responsibility**:
    *   **Hands-Off Supervision**: It *never* touches the code directly. It sits "far from the work."
    *   **The Loop**: It is the persistent process that monitors the state.
    *   **Decision Making**:
        *   Accepts reports from Workers (e.g., "Tests failed", "Spec Ready").
        *   Decides the next move (e.g., "Restart Step 2", "Promote to Review").
        *   Restarts the workflow if a worker crashes.
    *   **Identity**: "I am the manager who ensures the job gets done."

### 2.3 `ace-worker` (Roles): The Executors (The Hands)
*   **Role**: Specialized Agents & Tools.
*   **Responsibility**:
    *   **Execution**: Performing the actual work defined by the Overseer.
    *   **Polymorphism**: This is not a single binary, but a **Role**. It can be filled by:
        *   *The Engineer*: Writes code.
        *   *The Tester*: Runs `rspec` or `pytest`.
        *   *The Manual Tester*: A human verifying UI.
        *   *Existing Tools*: `ankb`, `claude`, or shell scripts.
    *   **Reporting**: Must report status back to the Overseer.

## 3. Architecture

### 3.1 Component Diagram
```mermaid
graph TD
    User((User)) -->|CLI: ace-coworker| Coworker[ace-coworker]
    Coworker -->|Spawns| Worktree[Git Worktree (.ace/coworker/ID)]
    
    subgraph "Isolated Session"
        Worktree -->|Runs| Overseer[ace-overseer]
        
        Overseer -->|Dispatches| Worker1[Worker: Architect]
        Overseer -->|Dispatches| Worker2[Worker: Engineer]
        Overseer -->|Dispatches| Worker3[Worker: Tester]
        
        Worker1 -->|Report| Overseer
        Worker2 -->|Report| Overseer
        Worker3 -->|Report| Overseer
    end
    
    Overseer -->|Persists| State[state.json]
    State -->|Reads| Coworker
```

## 4. The `ace-overseer` State Machine

The Overseer implements a resilient loop that drives the session through specific phases.

1.  **PLANNING**:
    *   Overseer calls **Architect Worker**.
    *   Goal: Generate `spec.md`.
    *   Wait for: `spec.md` to exist and be valid.
2.  **GATE: PLAN_REVIEW**:
    *   Overseer pauses.
    *   Wait for: Human signal (`ace-coworker approve <id>`).
3.  **EXECUTION (Iterative)**:
    *   Overseer calls **Engineer Worker**.
    *   Goal: Implement `spec.md`.
    *   Overseer calls **Tester Worker**.
    *   Goal: Verify implementation.
    *   *Loop*: If Tester fails, Overseer orders Engineer to retry (up to N times).
4.  **GATE: CODE_REVIEW**:
    *   Overseer pauses.
    *   Wait for: Human signal.
5.  **MERGE**:
    *   Overseer signals Coworker to merge the worktree.

## 5. Implementation Strategy

### 5.1 Tech Stack
*   **Coworker (CLI)**: Ruby (`thor` or `optparse`) + Git plumbing.
*   **Overseer (Logic)**: Ruby State Machine. Robust error handling is key.
*   **Worker (Interface)**: Standardized Shell Interface.
    *   Input: Environment variables / Context files.
    *   Output: Exit codes / Report files.

### 5.2 Next Steps
1.  **Scaffold `ace-overseer`**: Define the State Machine class and the "Report" interface.
2.  **Define Worker Interface**: How does the Overseer "call" a worker? (Likely `system()` calls to wrapper scripts).
3.  **Integrate**: Connect `ace-coworker` to spawn `ace-overseer`.
