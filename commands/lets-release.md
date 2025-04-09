# Let's Release Command

This command helps create a new release following project guidelines.

## Essential Reading

First review these key documents:
- [Release Guide](../guides/ship-release.md)
- [Project Management](../project/01-project-management.md)
- [Version Control](../guides/version-control.md)

## Process Steps

1. Review Changes:
   - Review commits since last release
   - Check current version in version.rb
   - Identify breaking changes

2. Prepare Documentation:
   - Update CHANGELOG
   - Generate release documentation
   - Follow [Documentation Guide](../guides/documentation.md)

3. Version Update:
   - Follow semantic versioning from [Project Management](../project/01-project-management.md)
   - Update version.rb
   - Update gemspec

4. Release Validation:
   - Run test suite
   - Check documentation
   - Verify examples
   - Review CHANGELOG

5. Create Release:
   - Create git tag
   - Push to repository
   - Publish gem

## Directory Structure

Release artifacts should be organized as:
```
docs-dev/
└── guides/
    └── prepare-release/
        └── v.x.x.x/
            ├── docs/
            ├── decisions/
            ├── test-cases/
            └── v.x.x.x-codename.md
```

## Reference Documentation

- [Release Process](../guides/ship-release.md)
- [Documentation Standards](../guides/documentation.md)
- [Version Control](../guides/version-control.md)

## Success Criteria

1. Documentation Complete:
   - CHANGELOG updated
   - Release notes prepared
   - API documentation current

2. Quality Checks:
   - All tests passing
   - Documentation verified
   - Examples working

3. Release Artifacts:
   - Git tag created
   - Gem published
   - Documentation deployed