# TypeScript (Bun) Testing Guide

This guide outlines testing best practices when using TypeScript with the Bun runtime.

## 1. Test Framework

Use `bun test` with built-in expect API.

## 2. Directory Structure

```
project-root/
└── tests/
    └── utils.test.ts
```

Use `.test.ts` naming convention.

## 3. Assertions & Mocks

- Use Bun’s built-in `mockModule` for mocking imports.
- Prefer `vi.fn()` equivalents for spies (coming soon in Bun).

## 4. Coverage

`bun test --coverage` generates LCOV.

## 5. Running Tests

```bash
bun test
```

Use `--watch` during development.

## 6. CI Integration

Ensure installing bun and running `bun test --coverage`.
