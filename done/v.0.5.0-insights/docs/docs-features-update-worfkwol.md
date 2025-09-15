I see you’ve uploaded workflow-instructions-definition.g.md 👍

Since you want to create a workflow instruction based on the CMS page documentation guide we just discussed, I suggest we define it as a step-by-step procedure so that anyone (dev, PM, QA, content editor) can consistently document features.

Here’s a draft you could integrate into your workflow file:

⸻

📝 Workflow: Documenting CMS Page Features

Purpose

Provide a consistent process for describing sections of a CMS-driven page, ensuring clarity for developers, product managers, QA, and content editors.

⸻

Steps

1. Identify the Section
	•	Name the section (e.g., Hero, Blog List, CTA).
	•	Write one-line purpose of the section.
	•	Note dependencies (CMS fields, API, static assets).

⸻

2. List Subsections / Components
	•	Enumerate all UI components in the section.
	•	Mark each as required or optional.
	•	Include details like fields, images, or dynamic data.

⸻

3. Define User Interactions
	•	Describe what action the user takes and what the system does in response.
	•	Use action → reaction format.
	•	Example: Click CTA button → navigate to signup page

⸻

4. Specify Tracking & Analytics
	•	Define which events are logged.
	•	Use consistent naming (snake_case).
	•	For each event, include:
	•	Event name
	•	Key parameters (e.g., article_id, page_number)
	•	When it is triggered

⸻

5. Document Variations / States
	•	Note possible alternative states:
	•	Empty state
	•	Loading state
	•	Error state
	•	Describe expected behavior in each state.

⸻

Output Format (Markdown Template)

### Section: <Name>
**Purpose:** <one sentence>

**Subsections:**
- <component 1> (required/optional)
- <component 2> ...

**User Interactions:**
- <action> → <reaction>
- ...

**Tracking Events:**
- `<event_name>` — <trigger> [parameters]

**Variations:**
- <state>: <description>


⸻

⚡ This way, documenting a CMS page becomes a repeatable workflow:
Identify → Break down → Describe interactions → Define tracking → Note states.

⸻

Would you like me to insert this workflow directly into your workflow-instructions-definition.g.md file in the right place, so it becomes part of your official documentation?
