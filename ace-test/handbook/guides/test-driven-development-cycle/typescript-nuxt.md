---
name: tdd-typescript-nuxt
description: Task cycle for TypeScript Nuxt application development
doc-type: guide
purpose: TDD workflow for Nuxt apps
search_keywords:
  - typescript
  - nuxt
  - tdd
  - vitest
  - nitro
update:
  frequency: on-change
  last-updated: '2026-01-23'
---

# Implementing Task Cycle: TypeScript + Nuxt

This details specific steps and commands for the task cycle when working on a TypeScript/Nuxt application.

* Follow the standard [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md).
* Use `@nuxt/test-utils`. Opt‑in to Nuxt runtime tests with `.nuxt.spec.ts` file names or
  `@vitest-environment nuxt` directive.
* Lint with ESLint/Prettier (`npm run lint`).
* Universal build (`nitro`) verified in CI; deployment handled by separate release pipeline.
