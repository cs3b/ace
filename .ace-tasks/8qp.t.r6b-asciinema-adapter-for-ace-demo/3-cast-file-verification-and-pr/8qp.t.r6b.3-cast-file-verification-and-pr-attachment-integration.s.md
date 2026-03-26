---
id: 8qp.t.r6b.3
status: draft
priority: medium
created_at: "2026-03-26 22:33:06"
estimate: TBD
dependencies: ["8qp.t.r6b.2"]
tags: [ace-demo, verification, cast, pr-attachment]
parent: 8qp.t.r6b
bundle:
  presets: ["project"]
  files:
    - ace-demo/lib/ace/demo/organisms/demo_recorder.rb
    - ace-demo/lib/ace/demo/organisms/demo_attacher.rb
    - ace-demo/lib/ace/demo/molecules/gh_asset_uploader.rb
    - ace-demo/lib/ace/demo/molecules/demo_comment_poster.rb
    - ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb
    - ace-demo/lib/ace/demo/atoms/demo_comment_formatter.rb
  commands: []
---

# Cast File Verification and PR Attachment Integration

## Objective

Enable programmatic verification of `.cast` recordings — confirming that commands ran and produced expected output — and update the PR attachment workflow to support the asciinema-first pipeline (`.cast` → agg → gif → attach to PR).

## Behavioral Specification

### User Experience

- **Input**: `.cast` file from asciinema recording + tape.yml spec defining expected commands
- **Process**: Parser extracts events from `.cast`, verifier checks commands executed and output is valid
- **Output**: Verification pass/fail result; gif attached to PR via existing attachment workflow

### Expected Behavior

**Cast File Verification**:
1. `CastFileParser` (atom) reads `.cast` file, extracts structured events
   - Header: version, width, height, timestamp, env
   - Events: `[timestamp, event_type, data]` tuples — "i" (input) and "o" (output)
2. `CastVerifier` (molecule) compares extracted events against tape.yml commands
   - For each command in tape.yml scenes: verify it appears in input events
   - For each command's output: verify non-empty output events follow
   - Reports: which commands ran, which produced output, any missing/unexpected
3. Verification result: pass (all commands ran + valid output) or fail (with details)

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
3. Verification result available for CI gates (exit code)

### Interface Contract

```ruby
# CastFileParser (atom)
CastFileParser.parse(cast_path)
# => CastRecording(header:, events: [CastEvent(time:, type:, data:)])

# CastVerifier (molecule)
verifier = CastVerifier.new
result = verifier.verify(cast_path:, tape_spec:)
# => VerificationResult(success:, commands_found: [], commands_missing: [], details:)
```

```bash
# Verification integrated into record flow
ace-demo record my-tape
# => Records .cast, converts to gif, verifies commands + output
# => Exit 0 if all good, warning if verification finds issues

# Attach with asciinema source
ace-demo attach my-tape --pr 123
# => Converts .cast to gif (if needed), uploads gif, posts comment
```

Error Handling:
- Invalid `.cast` file (not JSON, wrong format) → `CastParseError` with details
- Verification failure → warning with list of missing commands (not a hard error for recording)
- agg conversion failure during attach → `AggExecutionError` (blocks attachment)

Edge Cases:
- `.cast` with no output events (commands that produce no output) → pass if command input found
- Commands with shell expansion/variables → verify the expanded form in `.cast`
- Very long recordings → parser handles large files efficiently (streaming JSON lines)

### Success Criteria

- [ ] CastFileParser parses asciinema v2 `.cast` files into structured events
- [ ] CastVerifier confirms all tape.yml commands appear in `.cast` input events
- [ ] CastVerifier confirms commands produced output (non-empty output events)
- [ ] Verification integrated into `ace-demo record` flow (automatic, non-blocking)
- [ ] PR attachment works with asciinema pipeline: .cast → agg → gif → upload → comment
- [ ] Verification result includes actionable details on failures
- [ ] New models: CastRecording, CastEvent, VerificationResult

## Vertical Slice Decomposition

Single subtask — verification and PR attachment are tightly coupled (both depend on `.cast` pipeline).

- **Slice**: Cast verification + asciinema-aware PR attachment
- **Advisory size**: Medium
- **Context**: Depends on integrated asciinema pipeline from .2

## Verification Plan

### Unit/Component Validation
- [ ] CastFileParser: parses valid .cast file, extracts header and events
- [ ] CastFileParser: raises CastParseError on invalid/malformed .cast
- [ ] CastVerifier: passes when all commands found with output
- [ ] CastVerifier: fails with details when command missing
- [ ] CastVerifier: fails with details when command has no output

### Integration Validation
- [ ] Full flow: record tape.yml → .cast → verify → convert → attach to PR
- [ ] Verification runs automatically after asciinema recording

### Failure Path Validation
- [ ] Invalid .cast file → CastParseError with actionable message
- [ ] Missing commands → verification warning with command list
- [ ] agg failure during attach → AggExecutionError, attachment blocked

### Verification Commands
- [ ] `ace-demo record sample-tape` → .cast + gif + verification pass
- [ ] `ace-demo attach sample-tape --pr NNN` → gif uploaded, comment posted
- [ ] `ace-test` in ace-demo passes all existing + new tests
