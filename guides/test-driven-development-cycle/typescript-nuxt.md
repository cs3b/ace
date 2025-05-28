# Implementing Task Cycle: TypeScript + Nuxt

This details specific steps and commands for the task cycle when working on a TypeScript/Nuxt application.

* Follow the standard [Test -> Code -> Refactor cycle](docs-dev/guides/test-driven-development-cycle.md).
* Use `@nuxt/test-utils`. Opt‑in to Nuxt runtime tests with `.nuxt.spec.ts` file names or
  `@vitest-environment nuxt` directive. citeturn0search7
* Lint with ESLint/Prettier (`npm run lint`).
* Universal build (`nitro`) verified in CI; deployment handled by separate release pipeline.
