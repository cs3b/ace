# Capture Application Features

## Goal

Document application features from a user perspective to ensure clarity for developers, product managers, QA engineers, and content editors.

## Prerequisites

* Understanding of the application's user interface and functionality
* Access to the application or its design documentation
* Knowledge of user interaction patterns and workflows
* Familiarity with tracking and analytics requirements

## Project Context Loading

* Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
* Load template embedding guide: `dev-handbook/.meta/gds/template-embedding.g.md`
* Review existing feature documentation patterns if available

## Process Steps

1. **Identify the Feature or Section:**
   * Name the feature or page section (e.g., Hero Banner, Blog List, User Dashboard)
   * Write a one-line purpose statement describing its value to users
   * Note technical dependencies (CMS fields, APIs, static assets, databases)
   
   **Validation:**
   * Feature name is clear and consistent with existing nomenclature
   * Purpose statement answers "what value does this provide to users?"

2. **Document Structure and Components:**
   * List all UI components and subsections within the feature
   * Mark each component as required or optional
   * Include field types, data sources, and display conditions
   * Document responsive behavior across device types
   
   **Example Format:**
   ```markdown
   **Components:**
   - Header text (required) - CMS field: `hero_title`
   - Subheading (optional) - CMS field: `hero_subtitle`
   - Background image (required) - Asset: `hero_background`
   - CTA button (optional) - Links to: `cta_url`
   ```

3. **Capture User Interactions:**
   * Document all interactive elements using action → reaction format
   * Include state changes and feedback mechanisms
   * Note any conditional logic or personalization rules
   
   **Interaction Pattern:**
   ```markdown
   - Click "Learn More" button → Navigate to detailed page
   - Hover over image → Display caption overlay
   - Submit form → Show success message and redirect
   ```

4. **Define Tracking and Analytics:**
   * Specify all tracking events using consistent naming (snake_case)
   * Include event parameters and data attributes
   * Document when each event fires
   
   **Tracking Format:**
   ```markdown
   **Tracking Events:**
   - `hero_cta_clicked` — User clicks main CTA [section_id, cta_text]
   - `blog_article_viewed` — Article enters viewport [article_id, position]
   - `form_submission_started` — User begins form [form_id, source]
   ```

5. **Document States and Variations:**
   * Identify all possible states for the feature
   * Describe expected behavior in each state
   * Include error handling and edge cases
   
   **State Documentation:**
   ```markdown
   **States:**
   - Loading: Display skeleton loader with animations
   - Empty: Show helpful message with action suggestions
   - Error: Display error message with retry option
   - Success: Show confirmation with next steps
   ```

6. **Capture Business Rules:**
   * Document any conditional display logic
   * Note permission requirements or user role restrictions
   * Include time-based or geographic variations
   
   **Example Rules:**
   ```markdown
   **Display Rules:**
   - Show only to logged-in users with active subscription
   - Display between 9 AM - 5 PM user's local time
   - Hide on mobile devices under 375px width
   ```

7. **Create Feature Documentation:**
   * Use the embedded template structure below
   * Save in appropriate documentation location
   * Include screenshots or mockups if available
   * Cross-reference with technical implementation docs

## Embedded Templates and Examples

<templates>
<template path="feature-documentation-template.md">
# Feature: [Feature Name]

## Overview
**Purpose:** [One sentence describing the feature's value to users]
**Location:** [Where in the application this appears]
**User Types:** [Which users see/use this feature]

## Structure

### Components
- **[Component Name]** ([required/optional])
  - Type: [text/image/button/form/etc.]
  - Source: [CMS field/API/static]
  - Description: [What it displays or does]

### Layout
[Describe the visual arrangement and responsive behavior]

## User Interactions

| Action | System Response | Notes |
|--------|----------------|-------|
| [User action] | [What happens] | [Additional context] |

## Tracking & Analytics

### Events
| Event Name | Trigger | Parameters |
|------------|---------|------------|
| `[event_name]` | [When it fires] | [Data sent] |

### Metrics
- [Key metric 1]: [How measured]
- [Key metric 2]: [How measured]

## States & Variations

### States
- **Default:** [Normal display state]
- **Loading:** [What shows while loading]
- **Empty:** [No data available]
- **Error:** [Error handling]

### Variations
- **[Variation name]:** [When shown and differences]

## Business Rules
- [Rule 1]: [Condition and behavior]
- [Rule 2]: [Condition and behavior]

## Technical Notes
- **Dependencies:** [Required services/data]
- **Performance:** [Loading considerations]
- **Accessibility:** [WCAG compliance notes]

## Examples

### Scenario 1: [Common Use Case]
[Step-by-step user journey]

### Scenario 2: [Edge Case]
[How system handles unusual situation]

## Related Documentation
- [Link to design specs]
- [Link to API docs]
- [Link to implementation guide]
</template>

<template path="quick-feature-capture.md">
### Section: [Name]
**Purpose:** [one sentence describing user value]

**Components:**
- [component 1] (required/optional) - [source/type]
- [component 2] (required/optional) - [source/type]

**User Interactions:**
- [action] → [reaction]
- [action] → [reaction]

**Tracking Events:**
- `[event_name]` — [trigger] [parameters]

**States:**
- [state]: [description]
- [state]: [description]
</template>
</templates>

## Success Criteria

* Feature documentation captures all user-facing aspects
* Interactive elements and their behaviors are clearly defined
* Tracking events follow consistent naming conventions
* All states and error conditions are documented
* Business rules and display logic are explicit
* Documentation is accessible to both technical and non-technical stakeholders
* Cross-references to implementation details are included

## Error Handling

**Missing Information:**
* **Symptoms:** Unable to determine feature behavior or requirements
* **Solution:** Interview stakeholders, review designs, or test the live feature

**Inconsistent Naming:**
* **Symptoms:** Same feature called different names in different contexts
* **Solution:** Establish naming conventions and update all references

**Unclear User Value:**
* **Symptoms:** Cannot articulate why users need this feature
* **Solution:** Conduct user research or review product requirements

## Usage Example

> "Document the blog listing page that shows articles from our CMS, including the hero section, article cards, pagination, and newsletter signup."

Following this workflow would produce:

1. Identify each section (hero, article list, pagination, newsletter)
2. Document components (titles, images, buttons, forms)
3. Map interactions (click to read, page navigation, form submission)
4. Define tracking (article_clicked, page_viewed, newsletter_subscribed)
5. Document states (loading articles, no results, pagination limits)
6. Capture rules (articles per page, sort order, filtering)
7. Create comprehensive feature documentation using the template