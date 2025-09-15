# Workflow Prerequisites Checker

## Intention

Create a mechanism to validate workflow prerequisites before execution begins, preventing failures due to missing dependencies, incorrect tool versions, or invalid parameters. This proactive validation saves time and reduces frustration from late-stage failures.

## Problem It Solves

**Observed Issues:**
- Embedded test commands in tasks reference non-existent flags or tools
- Reflection synthesis requires minimum files but fails after processing
- Workflows assume tool capabilities that don't exist
- Missing context or templates discovered during execution
- File placement conventions violated due to unclear requirements

**Impact:**
- Wasted time executing workflows that will fail
- Frustration from preventable failures
- Reduced confidence in workflow automation
- Manual intervention required mid-workflow

## Key Patterns from Reflections

From synthesis workflow implementation:
- "reflection-synthesize tool requires minimum 2 reflection notes"
- "Some embedded test commands in tasks are aspirational rather than implemented"
- "Test command validation failures and reduced confidence"

From fix-tests workflow:
- "Embedded test commands in task definitions don't match actual CLI capabilities"
- "Gap between task expectations and actual tooling implementation"

From git toolbox usage:
- "Initial confusion about custom git tool availability required context loading"
- "User had to interrupt process twice to provide tool context"

## Solution Direction

1. **Prerequisite Declaration**: Workflows declare requirements upfront
2. **Pre-flight Validation**: Check all prerequisites before starting
3. **Tool Capability Registry**: Maintain registry of available tool features
4. **Context Verification**: Ensure required files/templates exist
5. **Clear Error Messages**: Explain what's missing and how to fix

## Expected Benefits

- Fail fast with clear guidance
- Reduce workflow interruptions
- Build confidence in automation
- Enable self-service troubleshooting
- Prevent cascading failures