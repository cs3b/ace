---
doc-type: workflow
title: Manage Agents Workflow Instruction
purpose: Documentation for ace-handbook/handbook/workflow-instructions/handbook/manage-agents.wf.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Manage Agents Workflow Instruction

## Goal

Create, update, and maintain agent definitions following the standardized agent definition guide. Ensure all agents
follow single-purpose design, have proper response formats, and are correctly integrated with the project structure.

## Prerequisites

* Access to `.claude/agents/` directory
* Understanding of the agent definition guide
* Access to `.claude/agents/` for symlinks
* Ability to update `CLAUDE.md` and `settings.json`

## High-Level Execution Plan

### Planning Steps

* Determine if creating new agent or
  updating existing
* Identify agent's single purpose and
  action keywords
* Plan expected parameters and tool
  requirements
* Consider agent composition needs


### Execution Steps

* Create/update agent file with proper
  .ag.md extension
* Add standardized metadata and response
  format
* Update symlinks in .claude/agents/
* Update CLAUDE.md agent section if
  significant changes
* Update settings.json if new tool
  permissions needed


## Process Steps

### 1. Creating a New Agent

#### Step 1.1: Determine Agent Purpose

* Identify the SINGLE primary purpose
* Choose action-oriented name (avoid -agent suffix)
* Define clear action keywords (FIND, CREATE, LINT, etc.)

#### Step 1.2: Create Agent File

Create file in `.claude/agents/[name].ag.md`:

    ---
    name: agent-name
    description: [ACTION] [specific purpose] - [what it does NOT do]
    expected_params:
      required:
        - param: "Description"
      optional:
        - param: "Description (default: value)"
    last_modified: 'YYYY-MM-DD'
    type: agent
    ---
{: .language-yaml}

#### Step 1.3: Add Agent Instructions

* Write clear, focused instructions
* Include key commands with examples
* Add agent composition section for delegation
* Include response format section

#### Step 1.4: Create Symlink

    cd .claude/agents
    ln -s ../../.claude/agents/[name].ag.md
{: .language-bash}

### 2. Updating Existing Agents

#### Step 2.1: Check Current State

* Review agent's current implementation
* Identify what needs updating
* Check if agent follows current standards

#### Step 2.2: Apply Updates

* Update metadata if needed
* Ensure response format section exists
* Update expected\_params
* Remove tools field (inherit from settings.json)

#### Step 2.3: Verify Symlinks

Ensure symlink exists and points to correct location.

### 3. Update Project Configuration

#### Step 3.1: Update CLAUDE.md

If agent is new or significantly changed, update the Agent Recommendations section:

* Add agent with action description
* Group in appropriate category
* Use consistent format: `**name** - ACTION purpose - details`

#### Step 3.2: Update settings.json

If agent uses new tools, add to permissions.allow:

    "Bash(tool-name*)"
{: .language-json}

### 4. Validate Agent

#### Step 4.1: Check Standards Compliance

* ✓ Uses .ag.md extension
* ✓ Has single purpose
* ✓ No tools field (inherits)
* ✓ Has response format section
* ✓ Has expected\_params
* ✓ Uses action keywords

#### Step 4.2: Test Agent

* Invoke agent with test parameters
* Verify response format
* Check delegation works if applicable

## Embedded Agent Definition Guide

<documents>
<document path="docs/guides/agents-definition.g.md">
# Writing Agent Definitions

This guide outlines best practices for creating and maintaining agent definitions located within the `.claude/agents/` directory.

## File Naming Convention

All agent files must use the `.ag.md` suffix to distinguish them from other documentation types.

### Naming Pattern
- **Format:** `<agent-name>.ag.md`
- **Style:** Use descriptive names that indicate the agent's primary function
- **Examples:**
  - `git-commit.ag.md` (not `git-commit-manager.md`)
  - `task-finder.ag.md` (not `task-manager-agent.md`)
  - `lint-files.ag.md` (not `code-lint-agent.md`)

## Core Principles

### 1. Single Purpose Design
Each agent should have exactly ONE primary purpose.

**Anti-pattern:** Multi-purpose agent
```yaml
name: git-manager
description: Handles commits, reviews, staging, and history
# TOO BROAD - will be used incorrectly
```

**Good pattern:** Focused agents
```yaml
name: git-fast-commit
description: FAST direct commit execution - NO analysis

name: git-review-commit  
description: ANALYZE and REVIEW changes before committing
```

### 2. Agent Naming and Description Guidelines

**Action-First Names:**
- `fast-commit` - Immediate execution
- `review-commit` - Analysis first
- `fix-tests` - Direct action

**Description Format:**
```
[ACTION_KEYWORD] [specific purpose] - [what it does NOT do]
```

Examples:
- "FAST direct commit execution - NO analysis or review"
- "ANALYZE and REVIEW changes - does NOT auto-commit"
- "FIX failing tests immediately - NO investigation"

### 3. Agent Format Specification

```markdown
---
# Core metadata (required for all agents)
name: agent-name
description: When to use this agent (clear, specific triggers)
expected_params:  # Document expected inputs
  required:
    - param_name: "Description of required parameter"
  optional:
    - param_name: "Description of optional parameter"
last_modified: 'YYYY-MM-DD'
type: agent
---

# Agent Instructions

Natural language instructions for the agent...

## Response Format

### Success Response
```markdown
## Summary
[Brief overview of what was accomplished]

## Results
[Key findings or actions taken]

## Next Steps
[Suggested follow-up actions or agent delegations]
```

### Error Response
```markdown
## Summary
[What went wrong]

## Issue
[Specific error details]

## Suggested Solution
[How to resolve the issue]
```

## Context Definition

```yaml
commands:
  - command-to-execute
format: markdown-xml
```
```

### 4. Tool Access and Permissions

**Best Practice:** Omit the `tools:` field entirely
- Agent inherits all permissions from settings.json
- Ensures wrapper tools are used
- Provides security through permission boundaries

Update settings.json to control tool access:
```json
{
  "permissions": {
    "allow": [
      "Bash(task-manager*)",
      "Bash(code-lint*)"
    ]
  }
}
```

### 5. Agent Composition

Agents should delegate to other agents for tasks outside their purpose:

```markdown
## Agent Composition

When user needs [other purpose], delegate using:
Task tool with subagent_type: [agent-name]
```

## Best Practices Summary

1. **Single Purpose**: One agent, one job
2. **Action Keywords**: Use FAST, CREATE, FIND, etc.
3. **No Tools Field**: Inherit from settings.json
4. **Response Format**: Always include standardized responses
5. **Expected Params**: Document all inputs
6. **Composition**: Delegate to other agents
7. **File Extension**: Always use .ag.md
8. **Symlinks**: Maintain in .claude/agents/
9. **Update CLAUDE.md**: Keep agent list current
10. **Test**: Validate before deployment
</document>
</documents>

## Success Criteria

- Agent follows single-purpose design principle
- Has standardized response format section
- Uses proper .ag.md file extension
- Symlink exists in .claude/agents/
- CLAUDE.md reflects current agent capabilities
- settings.json has necessary permissions
- Agent delegates appropriately to other agents

## Common Patterns

### Research Agent Pattern
```yaml
expected_params:
  required:
    - area: "What to research"
  optional:
    - depth: "How deep to go"
    - output_path: "Where to save results"
```

### Execution Agent Pattern
```yaml
expected_params:
  required:
    - target: "What to execute on"
  optional:
    - dry_run: "Test mode"
    - force: "Override safety checks"
```

### Analysis Agent Pattern
```yaml
expected_params:
  required:
    - input: "What to analyze"
  optional:
    - format: "Output format"
    - verbosity: "Detail level"
```

## When to Update CLAUDE.md

Update the Agent Recommendations section when:
- Creating a new agent
- Significantly changing agent purpose
- Renaming an agent
- Removing an agent
- Adding new agent category

## Verification Commands

```bash
# Check all agents have proper extension
ls .claude/agents/*.ag.md

# Verify symlinks
ls -la .claude/agents/

# Check for tools field (should be minimal)
grep "^tools:" .claude/agents/*.ag.md

# Verify response format sections
grep -l "## Response Format" .claude/agents/*.ag.md
```

## Usage Example

> "Create a new agent for database migrations"

1. Create `db-migrate.ag.md` with single purpose
2. Add response format and expected_params
3. Create symlink in .claude/agents/
4. Add to CLAUDE.md under Development Tools
5. Update settings.json if needed
6. Test the agent
</agent-name></document></documents>

