# Error Pattern Library

## Intention

Build a comprehensive library of common error patterns, their root causes, and proven solutions. This knowledge base helps developers quickly identify and resolve recurring issues without repeating the same debugging cycles.

## Problem It Solves

**Observed Issues:**
- Same errors encountered repeatedly across sessions
- Time wasted rediscovering solutions to known problems
- Inconsistent error handling approaches
- Missing documentation of failure modes
- No systematic learning from past errors

**Impact:**
- Repeated debugging of identical issues
- Inconsistent solutions to same problems
- Lost institutional knowledge
- Increased onboarding time for new developers
- Preventable errors keep occurring

## Key Patterns from Reflections

Recurring error patterns identified:
- Path normalization/symlink issues on macOS
- Model interface mismatches in tests
- Missing mocks causing cascading test failures
- File placement convention violations
- Tool output format mismatches
- Template location confusion
- Git command vs enhanced tool usage

From multiple sessions:
- "Path comparison failures on macOS due to symlink resolution"
- "Multiple tests failed due to outdated model expectations"
- "Initial confusion about custom git tool availability"
- "Technology mismatch not detected until code review execution"

## Solution Direction

1. **Error Pattern Catalog**: Structured documentation of common errors
2. **Root Cause Analysis**: Document why each error occurs
3. **Solution Playbooks**: Step-by-step resolution guides
4. **Prevention Strategies**: How to avoid each error pattern
5. **Integration Points**: Hook into tools to suggest solutions
6. **Search Capability**: Quickly find relevant error patterns

## Expected Benefits

- Faster error resolution
- Consistent handling of known issues
- Reduced debugging time
- Better onboarding experience
- Proactive error prevention
- Accumulated wisdom preservation