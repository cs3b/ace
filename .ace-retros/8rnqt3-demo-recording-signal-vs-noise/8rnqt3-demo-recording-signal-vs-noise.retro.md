---
id: 8rnqt3
title: demo-recording-signal-vs-noise
type: standard
tags: [demo, ux, recording]
created_at: "2026-04-24 17:52:20"
status: active
---

# demo-recording-signal-vs-noise

## What Went Well
- The recording pipeline was strict enough to catch correctness failures first, so the published GIF at least reflects a technically valid flow instead of a broken tape.
- Watching the final artifact made the presentation defect obvious: the problem is not subtle, and it is now concrete enough to improve systematically.
- The current tape still proves the underlying behavior that matters: syncing from a subdirectory creates root bootstrap files and the starter guidance contains ACE provenance plus refresh instructions.

## What Could Be Improved
- The demo optimizes for command correctness instead of viewer comprehension. The visible recording includes setup and environment churn that does not help a reviewer understand the feature.
- Environment preparation is leaking into the visible artifact. `git init` prints branch-name hints, and sandbox setup work appears in the recording even though it is not part of the user-facing behavior being demonstrated.
- The main sync step emits a large delegation document, so the recording spends most of its time showing documentation noise instead of the root-file effect the tape is supposed to prove.
- The proof step is too verbose and too slow. Showing `sed -n '1,20p' AGENTS.md` plus long fixed sleeps creates dead time and makes the key lines hard to spot.
- The recording shell and terminal presentation are poor. The cast runs under `bash --noprofile --norc -i` with a `dumb` terminal, which throws away the user’s configured fish environment, colors, and readability.
- The demo has no in-band framing. Scene names exist in the tape YAML, but the rendered GIF gives the viewer no caption or overlay explaining what is being shown or what to look for.

## Action Items
- Add a demo-authoring rule: environment and sandbox setup should run outside the visible typed recording unless the setup itself is the behavior under review.
- Add support for hidden pre-scene commands or setup commands in `ace-demo` so authors can prepare repos/sandboxes without recording that noise into the cast.
- Add support for rendered captions or scene labels in demo output so viewers know the intent of each visible step.
- Add support for choosing the recording shell/profile explicitly, including a path that preserves the user’s configured fish environment and terminal styling when desired.
- Tighten tape guidance so proof steps show only the minimum output needed to validate the contract, with shorter pauses and shorter excerpts.
- Add a review checkpoint for demo artifacts that asks one question before PR attachment: “Can a reviewer understand the behavior in a few seconds, or is this mostly terminal noise?”

## Key Learnings
- A demo can be technically correct and still fail as communication. Passing verification is not enough if the artifact does not help a reviewer see the product behavior quickly.
- Demo tapes need a stronger distinction between setup-time mechanics and user-visible proof. If those concerns are mixed together, the artifact turns into a terminal log instead of a demonstration.
- Readability is part of the product surface for demos. Shell choice, terminal profile, color, font rendering, pacing, and framing materially affect whether a recording has review value.
- The current `ace-demo` model is missing presentation controls that matter in practice: hidden setup, captions, and explicit shell/theme selection.

## Tool Proposals

### Enhancement Requests
- Existing tool: `ace-demo`
  Enhancement: support hidden setup or pre-scene commands that execute but are omitted from the visible cast
  Use case: prepare sandbox directories, initialize git state, or copy fixtures without wasting viewer attention
  Workaround: encode setup as typed commands and accept noisy output in the final GIF
- Existing tool: `ace-demo`
  Enhancement: support captions or scene-title overlays in rendered GIF/webm output
  Use case: explain what each scene is proving without relying on PR prose outside the artifact
  Workaround: rely on YAML scene names that are not visible in the rendered recording
- Existing tool: `ace-demo`
  Enhancement: support recording with an explicit shell/profile/theme choice, including fish-based sessions
  Use case: preserve the user’s configured terminal readability and avoid the current `bash` + `dumb` look
  Workaround: accept the default recording shell and lower-quality visual presentation

## Additional Context
- Trigger artifact: `ace-support-config/.ace-local/demo/ace-config-bootstrap-root-files.cast`
- Source tape: `ace-support-config/docs/demo/ace-config-bootstrap-root-files.tape.yml`
- Related PR: `#302`
