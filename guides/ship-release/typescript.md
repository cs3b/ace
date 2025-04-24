# TypeScript Release Process Examples

This file provides TypeScript/Node.js specific examples related to the main [Release Process Guide](../ship-release.md).

*   **Packaging:** `package.json`
*   **Building:** `npm run build` or `yarn build` (depends on project setup, often involves `tsc`)
*   **Publishing:** `npm publish` or `yarn publish` (to npm registry or private registry)
*   **Versioning:** `npm version <patch|minor|major>` or `yarn version --<patch|minor|major>`, update `CHANGELOG.md`
*   **Tagging:** `npm version` usually creates tags automatically, or `git tag -a vX.Y.Z -m "Release version X.Y.Z"`

```bash
# Example release workflow steps (using npm)

# Ensure tests pass
npm test

# Run build process
npm run build

# Update version, commit, and tag (npm handles this)
# Choose one: patch, minor, major
npm version patch -m "chore(release): Prepare release %s"

# Push changes and tags
# npm version pushes the tag, but you might need to push the commit
git push origin main --follow-tags

# Publish the package
npm publish
```

**Note:** Tools like `semantic-release` can automate much of this process based on commit messages.
