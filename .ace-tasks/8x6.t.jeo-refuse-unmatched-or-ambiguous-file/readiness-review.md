# Readiness review — 2026-10-08

Independent reviewer review_lab_bootstrap approved the spec and UX at 3ef6123de after checking LineNumberResolver, CommandBuilder, InProcessRunner and SmartTestExecutor. No blocking product questions remain.

Implementation must build a shared pre-load selection plan using real Ruby syntax/token ranges and static class/module identities. Both backends must enforce exact class/method/source identities, including inherited and same-name cases; unsupported dynamic or ambiguous identities refuse. All selectors validate before selected-file loading or subprocess creation. Mixed plain/line invocations may explicitly refuse as the accepted contract permits. After loading, verify exact expected identities/source locations before any test body; dynamic DSL mismatch cannot become zero-test success.

Required verification includes both execution backends, actual CLI, pre-load markers, nested blocks/heredocs, multiline literal test DSL, malformed source, duplicate/reopened classes, inherited methods, and mixed valid/invalid input. Existing complete package discovery behavior remains unchanged. This fixes test selection, not native Lab acceptance.

Task promoted through ace-task update and subsequently marked in-progress for implementation; implementation plan command is running. No success criteria are marked complete.
