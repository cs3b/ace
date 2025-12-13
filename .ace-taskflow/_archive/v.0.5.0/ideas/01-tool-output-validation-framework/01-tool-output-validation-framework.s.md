# Tool Output Validation Framework

## Intention

Create a systematic approach to validate that development tools produce expected outputs before considering operations complete. This addresses the recurring pattern where tools appear to succeed but produce incomplete or incorrectly formatted results.

## Problem It Solves

**Observed Issues:**
- `reflection-synthesize` tool produces compilation instead of analysis (just concatenates files without synthesis)
- Code review tools sometimes generate wrong report formats or miss files
- Tools place outputs in wrong directories violating project conventions
- Success messages don't guarantee correct output content or structure

**Impact:**
- Wasted time discovering output issues after the fact
- Manual rework to fix incorrectly formatted outputs
- Loss of trust in tool reliability
- Reduced automation effectiveness

## Key Patterns from Reflections

From reflection-synthesis-process-issues:
- Tool executed successfully but output contained no cross-reflection analysis
- File was placed in wrong directory structure
- No validation that synthesis actually occurred

From media-analysis session:
- Initial output used generic placeholders instead of actual analysis
- Required complete restructuring when user validated output

From code review workflow:
- Generated generic review instead of required 11-section structured format
- Missed critical JavaScript files when pattern was too restrictive

## Solution Direction

1. **Output Contract Definition**: Define expected output structure for each tool
2. **Post-Execution Validation**: Automatic checks after tool execution
3. **Quality Gates**: Prevent marking tasks complete until outputs validated
4. **Error Recovery Guidance**: Clear instructions when validation fails

## Expected Benefits

- Catch output issues immediately instead of downstream
- Build confidence in tool automation
- Reduce manual validation overhead
- Prevent propagation of incorrect outputs