---
name: tdd-typescript-vue
description: Task cycle for TypeScript Vue application development
doc-type: guide
purpose: TDD workflow for Vue apps
search_keywords:
  - typescript
  - vue
  - tdd
  - vitest
  - vite
update:
  frequency: on-change
  last-updated: '2026-01-23'
---

# Implementing Task Cycle: TypeScript + Vue

This details specific steps and commands for the task cycle when working on a TypeScript/Vue frontend
application (e.g., bootstrapped with Vite).

* Project likely bootstrapped by Vite.
* Follow the standard [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md).
* Use **Vitest** + `@vue/test-utils` for unit tests.
* Lint with ESLint & Prettier (`npm run lint`).
* CI runs `npm run lint && npm run test`.
