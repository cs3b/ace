---
title: Automated Feature Demo Recording Agent
filename_suggestion: feat-test-demo-recording
enhanced_at: 2025-11-16 16:53:18.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-09 01:02:51.000000000 +00:00
id: 8mfpbp
tags: []
created_at: '2025-11-16 16:52:59'
---

# Automated Feature Demo Recording Agent

## Problem
While `ace-test` provides robust unit and integration testing, and `ace-review` offers LLM-powered code analysis, there remains a gap in visually demonstrating the end-to-end functionality of newly implemented features. Manual demo creation is time-consuming, inconsistent, and doesn't scale with AI-assisted development. AI agents, in particular, need a mechanism to provide tangible, visual proof of their work beyond passing tests, especially when submitting pull requests. This lack of automated visual validation hinders efficient review processes and clear communication of feature impact.

## Solution
Introduce a new capability, potentially as an extension to `ace-test` or `ace-taskflow`, or as a dedicated `ace-demo` gem, that automates the setup, execution, and recording of feature demonstrations. This agent will orchestrate the provisioning of an isolated environment (e.g., a VM or container), deploy the feature, execute a predefined demo script, record the screen output, and then attach the resulting video/GIF artifact to the relevant GitHub Pull Request. This provides a clear, consistent, and automated visual validation of the feature's functionality.

## Implementation Approach
This capability would likely be implemented as a new `ace-*` gem (e.g., `ace-demo`) or as a significant extension to `ace-test` or `ace-taskflow`, adhering to the ATOM architecture pattern:

*   **Organisms**: A `DemoOrchestrator` organism would manage the entire lifecycle: environment provisioning, feature deployment, script execution, recording, and artifact upload.
*   **Molecules**: 
    *   `EnvironmentProvisioner`: Utilizes tools like Docker or Vagrant to create and configure isolated environments, leveraging `ace-context` for environment-specific configurations.
    *   `FeatureDeployer`: Handles the deployment of the newly implemented feature into the provisioned environment.
    *   `DemoScriptRunner`: Executes predefined, deterministic demo scripts (e.g., shell scripts, CLI commands) within the environment.
    *   `ScreenRecorder`: Captures screen activity and relevant output, potentially using external tools like `ffmpeg`.
    *   `ArtifactUploader`: Integrates with GitHub API to attach the recorded demo to a PR.
*   **Atoms**: Low-level functions for file operations, process execution, video encoding, and API interactions.
*   **Models**: Data structures for `DemoConfiguration`, `EnvironmentSpec`, and `RecordingArtifact`.

An `ace-demo` CLI command (e.g., `ace-demo record <feature_id> --pr <pr_number>`) would trigger the process. The agent would be defined as a `workflow-instruction` (`.wf.md`) or a complex `agent` (`.ag.md`) within the gem's `handbook/` directory, detailing the steps for environment setup, script execution, and recording.

## Considerations
-   **Environment Isolation**: Ensuring reliable and reproducible environment setups (VMs, containers) for consistent demo execution.
-   **Recording Fidelity**: Selecting appropriate screen recording tools and formats (e.g., MP4, GIF) that balance quality and file size.
-   **Demo Scripting**: Defining a clear, declarative format for demo scripts that can be executed deterministically by the agent.
-   **PR Integration**: Seamless integration with GitHub's API for attaching artifacts and updating PR status.
-   **Security**: Mitigating risks associated with running arbitrary scripts in a potentially privileged environment.
-   **Resource Management**: Managing computational resources for environment provisioning and video encoding.
-   **Configuration Cascade**: Utilizing `ace-support-core` for managing demo-specific configurations (e.g., environment templates, recording parameters).

## Benefits
-   **Automated Visual Validation**: Provides immediate, visual proof of feature functionality, enhancing confidence in AI-generated code.
-   **Improved PR Reviews**: Streamlines the review process by offering a clear, concise demonstration of changes, reducing reviewer effort.
-   **Consistency**: Ensures all feature demos follow a standardized process and environment, leading to consistent quality.
-   **Efficiency**: Significantly reduces the manual effort and time required to create and update feature demonstrations.
-   **Enhanced Trust**: Builds greater trust in the capabilities of AI agents by showcasing their work in an easily digestible format.
-   **Extended Testing**: Augments traditional testing with a user-centric, end-to-end visual validation layer.

---

## Original Idea

```
agent that will setup and record demo of the feature that was just implemented, setup the vm, setup the env - and record short demo that it works - soemthing beyond tests / integration tests. And attach this to the PR
```