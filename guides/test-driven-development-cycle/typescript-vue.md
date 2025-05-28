# Implementing Task Cycle: TypeScript + Vue

This details specific steps and commands for the task cycle when working on a TypeScript/Vue frontend
application (e.g., bootstrapped with Vite).

* Project likely bootstrapped by Vite.
* Follow the standard [Test -> Code -> Refactor cycle](docs-dev/guides/test-driven-development-cycle.md).
* Use **Vitest** + `@vue/test-utils` for unit tests. citeturn0search6
* Lint with ESLint & Prettier (`npm run lint`).
* CI runs `npm run lint && npm run test`.
