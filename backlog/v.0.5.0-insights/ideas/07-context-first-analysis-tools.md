# Context-First Analysis Tools

## Intention

Develop tools that prioritize discovering and leveraging existing context (files, documentation, transcripts) before attempting analysis or generation. This approach produces more authentic and valuable outputs by building on actual project content rather than making assumptions.

## Problem It Solves

**Observed Issues:**
- Generic file mapping produced instead of content-aware analysis
- Placeholders and assumptions instead of real data extraction
- Missing valuable context from .txt, .srt, and metadata files
- Tools default to generic approaches when rich context available
- Late discovery of context sources after initial implementation

**Impact:**
- Poor quality initial outputs requiring rework
- Missed opportunities for authentic categorization
- Time wasted on generic solutions
- User dissatisfaction with placeholder content
- Significant restructuring needed after context discovery

## Key Patterns from Reflections

From media analysis enhancement session:
- "Initially placed files in separate data/ directory instead of following project conventions"
- "Could have analyzed available context files earlier in the process"
- "Context files and transcripts provide dramatically better categorization"
- "Parsing actual content produces authentic categories vs generic placeholders"

Key insight: "Context Files Are Gold" - Real context files and transcripts provide dramatically better results than generated assumptions.

## Solution Direction

1. **Context Discovery Phase**: Always start by cataloging available context
2. **Context Analysis Tools**: Extract meaningful data from various file types
3. **Content-Aware Generation**: Use discovered context to inform outputs
4. **Context Priority Rules**: Define which sources to prioritize
5. **Fallback Strategies**: Clear approach when context is limited

## Expected Benefits

- Higher quality initial outputs
- Reduced rework and iterations
- More authentic and valuable results
- Better alignment with project reality
- Faster path to user satisfaction