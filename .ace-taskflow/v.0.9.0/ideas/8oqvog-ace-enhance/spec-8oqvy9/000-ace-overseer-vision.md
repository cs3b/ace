# ACE Overseer: High-Level Vision & Value

## Core Value Proposition

The **ACE Overseer** solves the "Context Fragility" and "Lost State" problems in autonomous agent workflows.

Currently, long-running agentic tasks suffer from:
1.  **Context Pollution**: A failure in step 5 of 10 contaminates the chat history for step 6.
2.  **Lack of Resilience**: Agents cannot effectively "cleanly retry" a specific step without restarting the entire interaction.
3.  **Role Confusion**: The "Engineer" agent tries to be the "Architect" and "Tester" simultaneously, leading to suboptimal code.

**The Value:**
By decoupling **Supervision** (Overseer), **Environment** (Coworker), and **Execution** (Workers), we achieve a system where:
*   **Reliability increases**: The loop can persist across crashes or interruptions.
*   **Quality improves**: Specialized "Workers" (Architect, Engineer, Tester) operate with clean, focused context.
*   **Observability**: The state of the work is saved in a structured format (`state.json`), not buried in a chat log.

## Final Outcome

A hierarchical system implementing a **"Master Loop"**:

1.  **ace-coworker (The Office)**: Manages the physical session (Git Worktrees, TUI dashboard). It is the container.
2.  **ace-overseer (The Supervisor)**: A state machine that drives the process (Plan -> Review -> Execute -> Verify). It holds the memory.
3.  **ace-workers (The Hands)**: Ephemeral, specialized agents (or tools) invoked by the Overseer to perform discrete tasks.

This transformation moves ACE from "a collection of tools" to "an autonomous engineering system" where the user acts as the **Director**, approving plans and reviewing final outcomes, while the Overseer manages the minute-to-minute workflow.
