# Template Architecture Evolution

## Intention

Evolve the template system to better support technology-specific configurations while maintaining simplicity. This includes improving template discovery, reducing duplication, and ensuring templates are configured during project initialization rather than discovered during execution.

## Problem It Solves

**Observed Issues:**
- System prompt mismatches discovered late (during code review, not setup)
- Manual template creation required for each technology stack
- Technology-specific content mixed into generic templates
- No guided process for template customization
- Templates in multiple locations causing confusion
- Missing templates for common operations (reflection creation)

**Impact:**
- Delayed reviews while creating appropriate templates
- Duplicated effort across projects with same tech stack
- Confusion about which templates apply where
- Increased setup friction for new projects

## Key Patterns from Reflections

From system prompt initialization workflow:
- "System prompt mismatch was discovered during code review execution rather than project initialization"
- "Creating project-specific system prompts required manual research and adaptation"
- "No clear mechanism to identify when default templates need customization"

From technology-specific template refactoring:
- "Technology-specific content mixed with generic templates"
- "Project config in `.claude/commands/` controls template selection"

From reflection synthesis issues:
- "create-path tool couldn't find template for reflection files"

## Solution Direction

1. **Project Init Workflow**: Add template configuration to project bootstrap
2. **Technology Template Library**: Pre-built templates for common stacks
3. **Template Discovery Tool**: Identify needed templates based on project
4. **Template Inheritance**: Generic base with technology-specific overrides
5. **Template Validation**: Ensure templates exist before operations need them

## Expected Benefits

- Projects start with correct templates configured
- Reduced manual template creation effort
- Clear template organization and discovery
- Faster project onboarding
- Consistent quality across technology stacks