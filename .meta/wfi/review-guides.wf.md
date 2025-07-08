# Review Guides

## Goal

Systematically review multiple development guide files for compliance with standards, consistency, conceptual focus, and quality. This meta-workflow provides batch review capabilities for handbook maintainers to ensure guides follow established patterns and maintain coherent coverage of development principles and standards.

## Prerequisites

* Understanding of guide definition principles and standards
* Access to dev-handbook/.meta/gds/ definition files
* Knowledge of existing guide patterns and organization
* List of guide files to review (or intent to review all)

## Project Context Loading

* Load guide standards: `dev-handbook/.meta/gds/guides-definition.g.md`
* Load markdown standards: `dev-handbook/.meta/gds/markdown-definition.g.md`
* Load guide organization: `dev-handbook/guides/README.md`
* Load example guide: `dev-handbook/guides/project-management.g.md`
* Load project structure: `docs/blueprint.md`
* Load available tools: `docs/tools.md`

## Process Steps

1. **Define Review Scope:**
   * Determine which guides to review:
     - All guides in `dev-handbook/guides/`
     - Specific subset based on criteria (category, recent changes, specific domain)
     - Individual guides provided by user
   * Identify review objectives:
     - Standards compliance and conceptual focus
     - Language modularity implementation
     - Cross-reference integrity
     - Content gaps and coverage analysis

2. **Gather Guide Inventory:**
   * List all guide files to review:

     ```bash
     find dev-handbook/guides -name "*.g.md" -type f
     ```

   * Identify language-specific sub-guides:

     ```bash
     find dev-handbook/guides -name "*.md" -not -name "*.g.md" -type f
     ```

   * Group guides by category (Core Process, Standards, Technical, etc.)
   * Note file relationships and cross-references

3. **Initialize Review Process:**
   * Create review session directory:

     ```bash
     mkdir -p dev-taskflow/current/v.X.Y.Z-release/guide-review/$(date +%Y%m%d)
     ```

   * Create review summary template:

     ```markdown
     # Guide Review Session - [Date]
     
     ## Review Scope
     * Total guides reviewed: [N main guides]
     * Language sub-guides reviewed: [N sub-guides]
     * Review criteria: [Conceptual focus, standards compliance, consistency]
     
     ## Coverage Analysis
     * Core development processes: [Status]
     * Standards and best practices: [Status]
     * Technical implementation guides: [Status]
     * Meta and documentation guides: [Status]
     
     ## Summary Results
     * ✅ Compliant guides: [N]
     * ⚠️ Guides needing minor improvements: [N]
     * ❌ Guides needing major revision: [N]
     * 📝 Content gaps identified: [N]
     
     ## Detailed Findings
     [Individual guide assessments]
     
     ## Recommended Actions
     [Prioritized improvement tasks]
     ```

4. **Review Each Guide Systematically:**
   
   For each guide file, assess the following areas:

   **Conceptual Focus Compliance:**
   * ✅ Focuses on "why" (principles, concepts, standards)
   * ✅ Explains rationale behind recommendations
   * ✅ Avoids step-by-step procedures (leaves those to workflows)
   * ✅ Provides decision-making context

   **Structure and Organization:**
   * ✅ Uses proper `.g.md` naming convention
   * ✅ Follows noun-phrase naming pattern
   * ✅ Has clear, scannable structure with headings
   * ✅ Organized logically for quick reference

   **Language Modularity:**
   * ✅ Main guide is language-agnostic (if applicable)
   * ✅ Language-specific details extracted to sub-guides
   * ✅ Proper subdirectory structure for language variants
   * ✅ Clear navigation between main and sub-guides

   **Content Quality:**
   * ✅ Information is accurate and up-to-date
   * ✅ Examples illustrate concepts (not procedures)
   * ✅ Terminology is consistent with project standards
   * ✅ Cross-references are accurate and helpful

5. **Analyze Language Modularity Implementation:**
   
   For guides with language-specific content:

   **Main Guide Assessment:**
   * Does it contain language-specific implementation details?
   * Are general principles clearly separated from specifics?
   * Does it properly reference language sub-guides?

   **Sub-Guide Assessment:**
   * Are language-specific guides appropriately focused?
   * Do they follow the `[topic]/[language].md` pattern?
   * Do they integrate well with main guide principles?
   * Are they consistent across different languages?

   **Cross-Reference Validation:**
   * Are links between main and sub-guides accurate?
   * Do sub-guides reference back to main principles?
   * Are external references to guides correct?

6. **Document Review Findings:**
   
   For each guide, create a standardized assessment:

   ```markdown
   ### [Guide Name] - [filename.g.md]
   
   **Overall Status:** ✅ Compliant | ⚠️ Minor Issues | ❌ Major Issues
   **Category:** [Core Process | Standards | Technical | Meta]
   
   **Conceptual Focus Assessment:**
   * Principle-based content: ✅/❌
   * Avoids procedures: ✅/❌
   * Provides decision context: ✅/❌
   
   **Structure Assessment:**
   * Naming convention: ✅/❌
   * Scannable organization: ✅/❌
   * Logical flow: ✅/❌
   
   **Language Modularity Assessment:**
   * Main guide language-agnostic: ✅/❌/N/A
   * Sub-guides properly structured: ✅/❌/N/A
   * Clear navigation: ✅/❌/N/A
   
   **Content Quality Assessment:**
   * Accuracy: ✅ Current | ⚠️ Minor issues | ❌ Outdated
   * Consistency: ✅ Consistent | ⚠️ Some issues | ❌ Inconsistent
   * Completeness: ✅ Complete | ⚠️ Minor gaps | ❌ Major gaps
   
   **Cross-Reference Assessment:**
   * Internal links: ✅ Working | ⚠️ Some broken | ❌ Many broken
   * External references: ✅ Accurate | ⚠️ Some issues | ❌ Incorrect
   
   **Issues Identified:**
   * [Specific issue 1]
   * [Specific issue 2]
   
   **Recommended Actions:**
   * [Priority level] [Specific action needed]
   ```

7. **Analyze Guide Coverage and Organization:**
   
   **Coverage Assessment:**
   * Are all major development areas covered?
   * Are there gaps in standards or best practices?
   * Do guides complement each other effectively?
   * Are there overlaps that could be consolidated?

   **Organization Assessment:**
   * Is the categorization in README.md logical?
   * Are related guides clearly connected?
   * Is the progression from basic to advanced clear?
   * Are cross-references helping navigation?

8. **Check Cross-Reference Integrity:**
   * Verify all internal links work correctly
   * Check references to workflow instructions
   * Validate external links and references
   * Ensure bi-directional references where appropriate

9. **Prioritize Improvement Actions:**
   
   **Critical Issues (Fix Immediately):**
   * Guides that are procedural instead of conceptual
   * Broken cross-references or navigation
   * Serious inaccuracies or outdated information
   * Major structural problems

   **High Priority Issues (Fix Soon):**
   * Language modularity violations
   * Inconsistent terminology usage
   * Missing cross-references
   * Content gaps in important areas

   **Medium Priority Issues (Plan for Fix):**
   * Minor accuracy updates
   * Improved examples or explanations
   * Better organization or structure
   * Enhanced scanability

   **Low Priority Issues (Nice to Have):**
   * Additional examples
   * Minor formatting improvements
   * Enhanced cross-references

10. **Generate Comprehensive Review Report:**
    * Compile complete assessment of guide collection
    * Include coverage analysis and gap identification
    * Document cross-reference integrity status
    * Provide actionable improvement roadmap
    * Suggest organizational improvements

## Review Criteria and Standards

### Conceptual Focus Requirements
* Explains principles and rationale ("why")
* Avoids step-by-step procedures ("how")
* Provides decision-making context
* Links to workflows for implementation

### Structure Standards
* Uses `.g.md` naming convention
* Follows noun-phrase naming pattern
* Organized with clear, scannable headings
* Logical flow from concepts to specifics

### Language Modularity Standards
* Main guides are language-agnostic
* Language-specific content in sub-guides
* Sub-guide pattern: `[topic]/[language].md`
* Clear navigation between variants

### Content Quality Standards
* Information is accurate and current
* Examples illustrate concepts, not procedures
* Terminology matches project standards
* Cross-references are accurate and helpful

## Automated Review Checks

### Basic Compliance Checks
```bash
# Check for proper .g.md naming
find dev-handbook/guides -name "*.md" -not -name "*.g.md" -not -path "*/guides/*/" -type f

# Check for procedural language in guides
grep -r "step.*:" dev-handbook/guides/*.g.md
grep -r "first.*then" dev-handbook/guides/*.g.md

# Check for broken internal links
grep -r "](\./" dev-handbook/guides/ --include="*.md"
```

### Language Modularity Checks
```bash
# Find guides with potential language-specific content
grep -r "ruby\|python\|javascript\|typescript" dev-handbook/guides/*.g.md

# Check sub-guide organization
find dev-handbook/guides -mindepth 2 -name "*.md" -type f
```

### Cross-Reference Validation
```bash
# Check for broken README references
grep -f <(find dev-handbook/guides -name "*.g.md" -exec basename {} \;) dev-handbook/guides/README.md

# Validate workflow references
grep -r "workflow-instructions/" dev-handbook/guides/ --include="*.md"
```

## Success Criteria

* All targeted guides systematically reviewed
* Conceptual focus compliance assessed for each guide
* Language modularity implementation validated
* Cross-reference integrity verified
* Coverage gaps and organizational issues identified
* Prioritized improvement plan created
* Review session documented with actionable recommendations

## Common Review Patterns

### New Guide Review
* Verify conceptual focus from start
* Check proper naming and structure
* Validate language modularity decisions
* Ensure integration with existing guides

### Existing Guide Maintenance
* Update for current standards and practices
* Check for procedural drift
* Validate cross-references still accurate
* Consider language modularity improvements

### Collection-Wide Analysis
* Identify coverage gaps and overlaps
* Analyze organizational effectiveness
* Plan systematic improvements
* Consider consolidation opportunities

## Error Handling

**Guide contains procedural content:**
* Identify specific procedural sections
* Determine if content should move to workflow instructions
* Plan refactoring to maintain conceptual focus

**Language modularity violations found:**
* Extract language-specific content to sub-guides
* Refactor main guide to be language-agnostic
* Create clear navigation between variants

**Significant coverage gaps identified:**
* Document gaps with priority assessment
* Plan new guide creation or existing guide expansion
* Consider impact on overall guide organization

## Usage Example

> "Review all development guides in dev-handbook/guides/ for conceptual focus compliance, language modularity implementation, and identify any coverage gaps in our development standards"