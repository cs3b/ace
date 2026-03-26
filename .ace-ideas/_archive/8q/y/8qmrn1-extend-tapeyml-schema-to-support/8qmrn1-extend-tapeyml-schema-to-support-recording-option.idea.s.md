---
id: 8qmrn1
status: done
title: Extend tape.yml schema to support recording option
tags: [ace-demo, dx, tape-format]
created_at: "2026-03-23 18:25:37"
---

# Extend tape.yml schema to support recording option

Extend tape.yml schema to support recording options currently only available via CLI flags. Allow per-tape configuration of: playback_speed (e.g. 4x), output file path, and retime-only output mode (where the original recording stays in .ace-local and only the retimed file goes to the specified output path). This would eliminate the need to pass --playback-speed, --output on every ace-demo record invocation when the tape already knows where its output should go.
