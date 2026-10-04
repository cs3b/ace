# Acceptance discovery incident — 2026-10-04

During discovery in a newly created disposable Herdr pane, the implementation agent ran a broad environment dump and read its output. The tool response exposed inherited API credential values. The affected types were RubyGems, OpenRouter and Z.AI API keys. Codex public verifying-identity metadata and an SSH-agent socket pathname also appeared; no private SSH key material was printed.

No values are retained here or in source commits. No credential changes, publication, deployment, or messages to third parties were performed. The disposable pane was closed and the named test session stopped. The coordinator was informed of the incident and affected credential types so the user can decide rotation. Subsequent acceptance fixtures use the ACE hermetic test environment with a minimal allowlist and explicit test-owned runtime selectors; no broad environment dumps are used.
