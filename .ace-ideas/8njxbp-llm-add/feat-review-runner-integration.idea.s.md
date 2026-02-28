---

title: Standardized Review Runner Integration for ace-review
filename_suggestion: feat-review-runner-integration
enhanced_at: 2025-12-20 22:13:04
location: active
llm_model: gflash
source: "taskflow:v.0.9.0"
---


# Standardized Review Runner Integration for ace-review

## Problem
Currently, `ace-review` is primarily focused on LLM-powered analysis, limiting its ability to incorporate deterministic, rule-based findings from specialized tools like linters. Integrating external tools requires ad-hoc scripting, violating the ACE principle of modularity and tool delegation. Specifically, we need a structured way to run static analysis (like Ruby linting via `standardb` executed through `ace-lint`) and merge those findings into the final review report.

## Solution
Refactor `ace-review` to introduce a pluggable Runner Orchestration layer. This layer will manage the execution of various review sources (LLM, Lint, Test Coverage, etc.). We will implement a dedicated `LintRunner` that delegates static analysis execution to `ace-lint` and transforms its deterministic output into a standardized `ReviewFinding` model before synthesis.

## Implementation Approach
1. **Model Definition (`ace-review/models/ReviewFinding`)**: Define a common data structure (Model) to represent all findings, including fields for `source` (e.g., 'LLM', 'Lint', 'Standardb'), `file_path`, `line_number`, `severity`, and `message`.
2. **Tool Delegation (`ace-review/molecules/LintRunner`)**: Create a Molecule that executes `ace-lint` with a deterministic output format (e.g., JSON). This molecule is responsible for parsing `ace-lint`'s output and mapping it to the `ReviewFinding` model, adhering to the Tool Delegation Principle.
3. **Orchestration (`ace-review/organisms/ReviewOrchestrator`)**: Implement an Organism that coordinates the execution of the `LLMRunner` and the new `LintRunner`. It collects all findings and passes them to a synthesis step.
4. **CLI Integration**: Add a `--lint` flag to the `ace-review` CLI command to easily enable the `LintRunner` via the configuration cascade.
5. **`ace-lint` Extension**: Ensure `ace-lint` can execute external tools like `standardb` and provide a standardized, machine-readable output (JSON/YAML) that is easy for `ace-review` to consume.

## Considerations
- **Integration with existing ace-lint**: The `LintRunner` must rely solely on `ace-lint`'s CLI interface for execution, avoiding internal code coupling, thus maintaining modularity.
- **Configuration cascade implications**: Configuration in `.ace/review/config.yml` should allow users to specify which runners are active and provide tool-specific parameters (e.g., `standardb` configuration).
- **CLI interface design**: The `--lint` flag should be intuitive, and the final report synthesis must clearly distinguish between deterministic lint errors and subjective LLM suggestions.
- **Synthesis Logic**: The synthesis Organism must handle potential overlaps, ensuring that deterministic errors are highlighted prominently.

## Benefits
- **Comprehensive Review**: Provides a unified report combining deterministic static analysis with subjective LLM insights.
- **Modularity and Delegation**: Enforces the ACE principle of delegating specialized tasks (linting) to dedicated gems (`ace-lint`).
- **AI-Native Determinism**: Increases the reliability of the review process by incorporating verifiable, rule-based findings.
- **Extensibility**: Creates a robust architecture for integrating future review runners (e.g., vulnerability scanners, performance metrics) into `ace-review`.

---

## Original Idea

```
ace-review - start using ace-lint (with standardb) as another source of review --lint, and then combine into single report on synthesis all of them). Rethink how to add aditional runners others then llm models for the review
```