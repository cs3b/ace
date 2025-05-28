# TypeScript Version Control Examples

This file provides TypeScript/Node.js specific examples and considerations related to the main [Version Control Guide](../version-control.md).

* **.gitignore:** Ensure standard Node.js/TypeScript files are ignored (e.g., `node_modules/`, `dist/`, `build/`,
  `.env`, `*.tsbuildinfo`, `coverage/`). Tools like [gitignore.io](https://www.toptal.com/developers/gitignore) can
  generate good starting points.
* **Pre-commit Hooks:** Use tools like `husky` with `lint-staged` to run linters (`ESLint`), formatters (`Prettier`),
  type checkers (`tsc --noEmit`), and tests (`Jest`, `Mocha`) on staged files before committing.
* **Dependency Locking:** Always commit `package-lock.json` (for npm) or `yarn.lock` (for Yarn) to ensure consistent dependencies.
* **Branching Strategy:** Standard Git workflows apply.

```json
// Example .lintstagedrc.json (used with husky)
{
  "*.{js,jsx,ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,yml,yaml}": [
    "prettier --write"
  ],
  "*.ts?(x)": [
    "bash -c 'tsc --noEmit'"
  ]
}
```

```gitignore
# Example additions to .gitignore for a TypeScript/Node project
/node_modules
/dist
/build
/.env*
*.tsbuildinfo
/coverage/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
```

```bash
# Example husky setup command (run once)
npx husky init && npm install
# Add hooks like:
npx husky add .husky/pre-commit "npx lint-staged"
```
