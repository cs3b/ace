# Ruby Release Process Examples

This file provides Ruby-specific examples related to the main [Release Process Guide](../ship-release.md).

*   **Packaging:** Gemspec (`.gemspec` file)
*   **Building:** `gem build <your_gem>.gemspec`
*   **Publishing:** `gem push <your_gem>-<version>.gem` (to RubyGems.org or private gem server)
*   **Versioning:** Update version in `lib/<your_gem>/version.rb`, `CHANGELOG.md`
*   **Tagging:** `git tag -a vX.Y.Z -m "Release version X.Y.Z"`

```bash
# Example release workflow steps

# Ensure tests pass
bundle exec rake test

# Update version number (e.g., in version.rb and CHANGELOG)
# ... manual or script update ...

# Commit version bump
git add lib/<your_gem>/version.rb CHANGELOG.md
git commit -m "chore(release): Prepare release vX.Y.Z"

# Build the gem
gem build <your_gem>.gemspec

# Tag the release
git tag -a vX.Y.Z -m "Release version X.Y.Z"

# Push changes and tags
git push origin main vX.Y.Z

# Push the gem
gem push <your_gem>-X.Y.Z.gem
```
