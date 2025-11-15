# Raw Idea (Enhanced Version Failed)

**Enhancement Error:** LLM enhancement failed after 4 attempts. Last error: Error: uninitialized constant CodingAgentTools::Molecules::ProviderModelParser
Use --debug flag for more information
Error: uninitialized constant CodingAgentTools::Molecules::ProviderModelParser
Use --debug flag for more information


## Original Idea

Based on our work improving the task-manager agent, I want to document techniques for creating better agents in general.

What we did with task-manager agent:
1. Started with a context that loaded too much data (all task file contents)
2. Discovered through usage that we only needed file-level metadata
3. Used dynamic discovery (release-manager) instead of hard-coded paths
4. Analyzed actual usage patterns from research to understand real workflows
5. Created minimal context (just 6 commands total)
6. Added common workflows section based on usage
7. Emphasized canonical location (.ace/handbook) over duplicates

Key learnings for agent creation:
- Start minimal - agents don't need all data, just enough to make decisions
- Use dynamic discovery over hard-coded values
- Work at metadata level when possible (file lists vs content)
- Research actual usage patterns before designing
- Create reusable context templates
- Document common workflows not just commands
- Keep context loading efficient (commands over files)
- Single source of truth for agent definitions

Techniques that could help:
- Usage recorder: Automatically capture command patterns
- Agent template generator: Standard structure for new agents
- Context optimizer: Analyze what data agent actually uses
- Workflow extractor: Convert usage patterns to workflow sections
- Agent validator: Check for common issues (hard-coded paths, excessive data loading)
- Self-hydration patterns: Agents that can load their own context
- Progressive enhancement: Start simple, add complexity based on usage

> SOURCE

```text
Based on our work improving the task-manager agent, I want to document techniques for creating better agents in general.

What we did with task-manager agent:
1. Started with a context that loaded too much data (all task file contents)
2. Discovered through usage that we only needed file-level metadata
3. Used dynamic discovery (release-manager) instead of hard-coded paths
4. Analyzed actual usage patterns from research to understand real workflows
5. Created minimal context (just 6 commands total)
6. Added common workflows section based on usage
7. Emphasized canonical location (.ace/handbook) over duplicates

Key learnings for agent creation:
- Start minimal - agents don't need all data, just enough to make decisions
- Use dynamic discovery over hard-coded values
- Work at metadata level when possible (file lists vs content)
- Research actual usage patterns before designing
- Create reusable context templates
- Document common workflows not just commands
- Keep context loading efficient (commands over files)
- Single source of truth for agent definitions

Techniques that could help:
- Usage recorder: Automatically capture command patterns
- Agent template generator: Standard structure for new agents
- Context optimizer: Analyze what data agent actually uses
- Workflow extractor: Convert usage patterns to workflow sections
- Agent validator: Check for common issues (hard-coded paths, excessive data loading)
- Self-hydration patterns: Agents that can load their own context
- Progressive enhancement: Start simple, add complexity based on usage
```
