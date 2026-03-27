---
id: 8qp.t.r6b.3
status: done
priority: medium
created_at: "2026-03-26 22:33:06"
estimate: TBD
dependencies: [8qp.t.r6b.2]
tags: [ace-demo, verification, cast, pr-attachment]
parent: 8qp.t.r6b
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/organisms/demo_attacher.rb, ace-demo/lib/ace/demo/molecules/gh_asset_uploader.rb, ace-demo/lib/ace/demo/molecules/demo_comment_poster.rb, ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb, ace-demo/lib/ace/demo/atoms/demo_comment_formatter.rb, ace-demo/lib/ace/demo/cli/commands/attach.rb, ace-demo/docs/usage.md, .ace-tasks/8qp.t.r6b-asciinema-adapter-for-ace-demo/2-integrate-asciinema-as-default-recording/ux-usage.md]
  commands: []
needs_review: false
---

# Cast File Verification and PR Attachment Integration

## Objective

Enable programmatic verification of `.cast` recordings by confirming that expected commands were recorded, and update the PR attachment workflow to support the asciinema-first pipeline (`.cast` → agg → GIF → attach to PR) while keeping `attach` file-path based.

## Behavioral Specification

### User Experience

- **Input**: `.cast` file from asciinema recording + tape.yml spec defining expected commands
- **Process**: Parser extracts events from `.cast`, verifier checks whether expected commands were recorded, and `attach` converts `.cast` to GIF before upload when needed
- **Output**: Verification pass/warn result; GIF attached to PR via existing attachment workflow

### Expected Behavior

**Cast File Verification**:
1. `CastFileParser` (atom) reads `.cast` file, extracts structured events
   - Header: version, width, height, timestamp, env
   - Events: `[timestamp, event_type, data]` tuples — "i" (input) and "o" (output)
2. `CastVerifier` (molecule) compares extracted events against tape.yml commands
   - For each command in tape.yml scenes: verify it appears in input events
   - Output events may be included in details, but are not required for a successful verification result in this task
   - Reports: which commands were found, which were missing, and any parse/ordering anomalies
3. Verification result: pass when command presence is confirmed; warn/fail-details when commands are missing or the cast is malformed

**PR Attachment Integration**:
1. `ace-demo attach` workflow updated for asciinema-first pipeline
2. When attaching an asciinema recording to a PR:
   - If only `.cast` exists, convert to gif via agg first
   - Upload gif to GitHub release assets (existing GhAssetUploader)
   - Post comment with embedded gif (existing DemoCommentPoster)
3. The `.cast` file itself is NOT uploaded to PR (gif is the visual artifact)

**Verification in record-demo workflow**:
1. After asciinema recording completes, verification runs automatically
2. If verification fails, recording still succeeds but warning is emitted
3. Verification result is returned in recording metadata / CLI output, but does not change the record command's exit code in this task

### Interface Contract

```ruby
# CastFileParser (atom)
CastFileParser.parse(cast_path)
# => CastRecording(header:, events: [CastEvent(time:, type:, data:)])

# CastVerifier (molecule)
verifier = CastVerifier.new
result = verifier.verify(cast_path:, tape_spec:)
# => VerificationResult(success:, status:, commands_found: [], commands_missing: [], details:)
```

```bash
# Verification integrated into record flow
ace-demo record my-tape
# => Records .cast, converts to gif, verifies command presence
# => Exit 0 if all good, warning if verification finds issues

# Attach with asciinema source
ace-demo attach .ace-local/demo/my-tape.cast --pr 123
# => Converts .cast to gif (if needed), uploads gif, posts comment
```

Error Handling:
- Invalid `.cast` file (not JSON, wrong format) → `CastParseError` with details
- Verification failure → warning with list of missing commands (not a hard error for recording)
- agg conversion failure during attach → `AggExecutionError` (blocks attachment)

Edge Cases:
- `.cast` with no output events (commands that produce no output) → pass if command input found
- Commands with shell expansion/variables → verify the actual command text recorded in cast input events
- Very long recordings → parser handles large files efficiently (streaming JSON lines)
- `attach` invoked with a visual file path → upload directly without reconversion

### Success Criteria

- [x] CastFileParser parses asciinema v2 `.cast` files into structured events
- [x] CastVerifier confirms all tape.yml commands appear in `.cast` input events
- [x] Verification integrated into `ace-demo record` flow (automatic, non-blocking)
- [x] PR attachment works with asciinema pipeline: .cast → agg → gif → upload → comment
- [x] Verification result includes actionable details on failures
- [x] New models: CastRecording, CastEvent, VerificationResult
- [x] `ace-demo attach` remains file-path based and accepts `.cast` inputs

## Vertical Slice Decomposition

Single subtask — verification and PR attachment are tightly coupled (both depend on `.cast` pipeline).

- **Slice**: Cast verification + asciinema-aware PR attachment
- **Advisory size**: Medium
- **Context**: Depends on integrated asciinema pipeline from .2

## Verification Plan

### Unit/Component Validation
- [x] CastFileParser: parses valid .cast file, extracts header and events
- [x] CastFileParser: raises CastParseError on invalid/malformed .cast
- [x] CastVerifier: passes when all expected commands are found in input events
- [x] CastVerifier: fails with details when command missing
- [x] DemoAttacher / attach flow converts `.cast` input to GIF before upload

### Integration Validation
- [x] Full flow: record tape.yml → .cast → verify → convert → attach to PR
- [x] Verification runs automatically after asciinema recording

### Failure Path Validation
- [x] Invalid .cast file → CastParseError with actionable message
- [x] Missing commands → verification warning with command list
- [x] agg failure during attach → AggExecutionError, attachment blocked
- [x] Verification warnings leave `ace-demo record` exit status successful

### Verification Commands
- [x] `ace-demo record sample-tape` → .cast + gif + verification pass
- [x] `ace-demo attach .ace-local/demo/sample-tape.cast --pr NNN` → gif uploaded, comment posted
- [x] `ace-demo attach .ace-local/demo/sample-tape.gif --pr NNN` → gif uploaded, comment posted without reconversion
- [x] `ace-test` in ace-demo passes all existing + new tests
