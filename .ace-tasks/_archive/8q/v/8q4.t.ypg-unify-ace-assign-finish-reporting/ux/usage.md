# ace-assign finish --message Flag - Draft Usage

## API Surface
- [x] CLI (user-facing commands)

## Usage Scenarios

### Scenario 1: Inline String Report

**Goal**: Complete a phase with a short inline report without creating a file

```bash
ace-assign finish -m "Done: all tests pass, feature implemented"

# Expected output:
Phase 010 (init) completed
Report saved to: .ace-local/assign/abc123/reports/010-init.r.md
Advancing to phase 020: build
```

### Scenario 2: File Path Report (Auto-Detected)

**Goal**: Complete a phase using an existing report file

```bash
ace-assign finish -m report.md

# Expected output:
Phase 010 (init) completed
Report saved to: .ace-local/assign/abc123/reports/010-init.r.md
Advancing to phase 020: build
```

### Scenario 3: No Input Error

**Goal**: Clear error guidance when no report content is provided

```bash
ace-assign finish

# Expected output:
Error: Missing report input: provide --message <string|file> or pipe stdin.
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
