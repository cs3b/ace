---
id: 8qlvsa
status: pending
title: Reliable fallback for review feedback synthesis
tags: [ace-review, fallback, feedback, ace-llm]
created_at: "2026-03-22 21:11:27"
---

# Reliable fallback for review feedback synthesis

Feedback synthesis needs reliable fallback. Main ace-review execution can keep fallback disabled by design, but synthesis should allow fallback and have a dependable default chain. Default order should prefer claude:sonnet, codex:mini, pi:glm, then gemini:flash, while always removing providers already tried.
