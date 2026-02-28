---
id: resear
status: done
title: Researches
tags: []
created_at: '2026-02-28 20:24:51'
---

🔑 Key Summary (3–5 Sentences):
Yogendra Miraje from FactSet outlines a practical approach to building agentic workflows—AI agents capable of dynamic, goal-driven task execution—without sacrificing control. He distinguishes between static workflow agents and dynamic agentic workflows, advocating for the latter in complex enterprise environments. Central to his methodology are blueprints, subgoal planning, modular tool design based on microservices, and strong eval frameworks to ensure reliability and interpretability. The core message: enterprises can achieve scalable autonomy by balancing planning, feedback, and control through thoughtful architecture and tooling.

⸻

🧠 Detailed Breakdown & Analysis:

1. Core Definitions & Distinctions
	•	Workflow = Predefined sequence + Augmented LLMs (tools + memory).
	•	Workflow Agent = Agent executing a static workflow.
	•	Agentic Workflow = Agent dynamically planning and executing workflow.
	•	Agentic System Spectrum = From low-autonomy (workflow agents) to high-autonomy (agentic workflows).

Bias alert: The speaker favors agentic workflows over traditional agents, assuming enterprise flexibility and adaptability are always prioritized over control and predictability.

2. Why Agentic Workflows Matter
	•	Better scalability in enterprise automation.
	•	Leverages existing enterprise microservices, avoiding rebuilding.
	•	Enhances control, reliability, and autonomy simultaneously.

3. Architecture & Components

Miraje presents a modular system inspired by the LLM compiler architecture, comprising:
	•	Blueprint Generator: Converts goals into high-level natural language tasks.
	•	Planner: Breaks blueprints into executable tasks.
	•	Executor: Carries out tasks via tools.
	•	Joiner: Aggregates results and handles replanning.

📌 The blueprint is the critical innovation: it eases cognitive load on the planner, limits tool context, improves interpretability, and helps collaborate with non-technical stakeholders.

4. Tooling Strategy
	•	Tools are built around existing microservices, not one-to-one mapped.
	•	Follows the MCP pattern: Modular, Contractual, Purposeful.
	•	Tools must have: Purpose, Description, Input/Output Contracts, and Validation Checks (to enforce agent control).

5. Practical Example

Use case: Preparing for NVIDIA’s earnings call.
	•	Blueprint breaks task into: summarization → data retrieval → reasoning → reporting.
	•	This modularity allows structured and interpretable output, contrasting with generic responses.

6. Evaluation Strategy

Miraje emphasizes evals as a “first-class citizen”:
	•	Combine component-based and end-to-end evals.
	•	Use LLMs as judges for subjective metrics, like blueprint correctness.
	•	For deterministic checks (e.g. tool selection), use code-based evals.
	•	For formatting or nuance, apply human-in-the-loop.

7. When Not to Use Agentic Workflows
	•	Repetitive/fixed tasks → Use ETL pipelines.
	•	Strict compliance or safety-critical use cases → Prefer deterministic systems.
	•	Cost/latency-sensitive environments → Avoid agentic overhead.

8. Final Takeaways
	•	Start simple with blueprints and evolve complexity.
	•	Use blueprints to reduce in-context complexity for the planner.
	•	Tools must be intuitive from the agent’s POV.
	•	Incorporate observability, safety, and eval rigor.

⸻

🧭 Author Bias & Perspective
	•	Bias toward enterprise use cases: The speaker frames everything in terms of scaling automation in large organizations, favoring flexibility over determinism.
	•	Pro-agentic: He implies that agentic workflows are the future, possibly overlooking the full spectrum of practical constraints (e.g. smaller orgs, budget constraints).
	•	Tool-centric view: Emphasizes microservice integration and tool design as the primary axis of agent success.

⸻

🔧 Actionable Insights
	•	Adopt blueprint planning for task decomposition.
	•	Design tools with agent-first documentation and structure.
	•	Invest in eval infrastructure from the start.
	•	Use LangGraph or similar frameworks for orchestration.
	•	Avoid agentic systems in environments requiring low cost, high speed, or deterministic output.