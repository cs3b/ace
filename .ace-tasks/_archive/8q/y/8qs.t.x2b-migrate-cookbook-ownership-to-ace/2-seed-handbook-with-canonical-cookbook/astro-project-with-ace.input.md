---
repo: cs3b/ace
title: "Recipe: Starting an Astro project with ACE"
labels: documentation, recipe
status: draft
---

# Recipe: Starting an Astro project with ACE

## Context

Lessons learned from building lesnykacik.pl — a single-page static site with Astro + Tailwind CSS + Firebase Hosting, fully orchestrated through ACE (12 tasks, batch assignment, 3 review cycles). This recipe captures what worked, what to avoid, and the optimal task ordering.

## Prerequisites

- Node.js (via mise)
- ACE gems installed (`bundle install`)
- Git repo initialized with remote configured (verify before assignment creation!)

## Step 1: Initialize project

```bash
npm create astro@latest -- --template minimal
npm install tailwindcss @tailwindcss/vite
```

Add to `astro.config.mjs`:

```js
import tailwindcss from '@tailwindcss/vite';
export default defineConfig({
  vite: { plugins: [tailwindcss()] }
});
```

Add to `src/styles/global.css`:

```css
@import "tailwindcss";
```

## Step 2: Set up ACE

```bash
ace-handbook init
```

Create CLAUDE.md with project-specific conventions:

- Commit scopes relevant to the project
- Design system reference
- Key facts (address, phone, coordinates, etc.)

## Step 3: Plan tasks — design tokens FIRST

Critical learning: **design tokens must be the first task**. All subsequent component tasks depend on consistent colors, fonts, and spacing.

Recommended task order for a single-page site:

1. Configure design tokens (colors, fonts, spacing, utilities)
2. Header/nav component
3. Hero section
4. Content sections (rooms, reviews, amenities, etc.)
5. Contact/CTA section
6. Footer + floating CTA
7. Image processing pipeline
8. Firebase hosting setup (mark as **manual** — requires interactive auth)

## Step 4: Create assignment

```bash
/as-assign-create work-on-task --taskref <refs>
```

### Preflight checklist (before creating)

- [ ] `git remote -v` returns configured remote
- [ ] External auth verified (Firebase, cloud) — flag interactive tasks as manual
- [ ] Design token task is first in sequence

### Assignment tuning for Astro/static sites

- **Review cycles**: Use 2 (valid + fit). Skip shine — diminishing returns on HTML/CSS.
- **Per-task ceremony**: For MVP/initial build, skip per-task retros and changelogs. One release at the end.
- **Fork execution**: Works well for independent sections. Each component is self-contained.

## Step 5: Drive the assignment

```bash
/as-assign-drive
```

Fork subtrees handle each task autonomously. Sequential execution (not parallel) for static sites — components build on each other.

## Step 6: Post-build polish

After the assignment completes, expect a manual feedback round:

- Mobile responsive testing (especially iOS Safari)
- Design review with stakeholder
- Social sharing optimization (OG tags + JPG image)

### iOS Safari gotchas (learned the hard way)

| Issue | Cause | Fix |
| --- | --- | --- |
| Mobile menu not covering full screen | `position: fixed` child inside `position: fixed` parent | Move menu div outside parent element |
| `overflow: hidden` on body doesn't prevent scroll | iOS Safari ignores overflow on body | Use `position: fixed` + save/restore scroll position |
| Tailwind opacity modifiers on custom colors | Safari doesn't always honor `/98` syntax | Use inline `style` with explicit `rgba()` |
| `backdrop-filter` not working | Missing `-webkit-` prefix | Add `-webkit-backdrop-filter` alongside |

**Protocol**: Always web-search the specific browser issue before trying CSS fixes. Explain the root cause, don't iterate blindly.

## Step 7: Deploy

Firebase Hosting requires interactive auth:

```bash
firebase login        # Interactive — can't run in fork/batch
firebase deploy --only hosting
```

This step must be manual. Don't include it in fork-executed assignments.

## Step 8: Social sharing

Create OG image (social platforms often don't support WebP):

```bash
node -e "
const sharp = require('sharp');
sharp('public/images/hero/hero-01.webp')
  .resize(1200, 630, { fit: 'cover' })
  .jpeg({ quality: 85 })
  .toFile('public/og-image.jpg');
"
```

Add to Layout:

```html
<meta property="og:image" content="https://yourdomain.com/og-image.jpg" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta name="twitter:card" content="summary_large_image" />
```

## What worked well

- **Design tokens first** — all components used consistent styling without rework
- **Fork execution for independent sections** — 11/12 completed without intervention
- **Build verification in every fork** — `npm run build` after each task, no accumulated breakage
- **Review cycles caught real UX bugs** — Hero CTA linking desktop to phone dialer, dead buttons, duplicate landmarks

## What to avoid

- **Don't batch interactive-auth tasks** — Firebase deploy, cloud login
- **Don't run 3 review cycles on static sites** — 2 is enough (valid + fit)
- **Don't assume CSS works on iOS Safari** — research first, fix second
- **Don't create PR steps without verifying remote exists**
- **Don't use `position: fixed` inside `position: fixed`** on mobile

## Metrics from lesnykacik.pl build

| Metric | Value |
| --- | --- |
| Tasks | 12 (+ 1 init) |
| Fork subtrees | 12 (11 autonomous, 1 retry) |
| Total commits | 47 (could be reduced to ~20 with MVP ceremony skip) |
| Build time | ~700ms |
| Review cycles | 3 (recommend 2) |
| Valid cycle fixes | 5 |
| Fit cycle fixes | 7 |
| Shine cycle fixes | 0 |
| Images processed | 99 -> 7 groups |
| Page weight (HTML) | 1 page |
