# TypeScript Quality Assurance Examples

This file provides TypeScript-specific examples related to the main [Quality Assurance Guide](../quality-assurance.md).

*   **Linters/Formatters:** `eslint` (with `@typescript-eslint/parser`), `prettier`
*   **Static Analysis:** TypeScript compiler (`tsc --noEmit`), `sonarjs` (plugin for ESLint)
*   **Test Coverage:** `istanbul` (often via `jest` or `vitest`)
*   **CI Configuration:** Examples for GitHub Actions, GitLab CI using Node.js/TypeScript setup actions.

**Example `.eslintrc.js` (ESLint with TypeScript):**
```javascript
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: [
    '@typescript-eslint',
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier', // Make sure prettier is last
  ],
  rules: {
    // Add custom rules here
  },
};
```

**Example Jest config for coverage (`jest.config.js`):**
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  // Coverage thresholds (optional)
  // coverageThreshold: {
  //   global: {
  //     branches: 80,
  //     functions: 80,
  //     lines: 80,
  //     statements: -10,
  //   },
  // },
};
```
