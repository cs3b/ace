---
name: ace-review-package
description: Review Package - Comprehensive code, docs, UX/DX review with recommendations
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-git:*)
  - Bash(gh:*)
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - TodoWrite
  - Skill
argument-hint: [package-name]
last_modified: 2026-01-10
source: custom
---

# Package Review Workflow

You will conduct a comprehensive review of the specified package and create actionable recommendations.

## Arguments

- **package-name**: Name of the package to review (e.g., "ace-bundle", "ace-git-diff")

## Workflow Steps

### 1. Load Project Context

First, load the project context for the package to understand its structure:

```
Use SlashCommand tool to run: /ace-bundle [package-name]/project
```

If the preset doesn't exist, manually explore the package structure:
- Read package README
- Read gemspec file
- Explore lib/ directory structure
- Check documentation in docs/
- Review test structure

### 2. Conduct Comprehensive Review

Review the following aspects of the package:

#### A. Code Quality & Architecture (Target: 9/10)
- **Architecture Pattern**: Check for clean separation (atoms/molecules/organisms, MVC, etc.)
- **File Organization**: Logical structure, clear responsibilities
- **Code Size**: Check for large files (>800 lines may need refactoring)
- **Dependencies**: Clean dependency management, no unnecessary deps
- **Error Handling**: Graceful degradation, clear error messages
- **Code Duplication**: DRY principle adherence
- **Key Access Patterns**: Consistent symbol/string hash access
- **Comments & Documentation**: Code-level documentation quality

Files to examine:
- `lib/**/*.rb` - All library files
- `[package-name].gemspec` - Dependencies and metadata
- Check total LOC: `find lib -name "*.rb" -exec wc -l {} + | tail -1`

#### B. Documentation Quality (Target: 9.5/10)
- **README.md**: Clear overview, installation, usage examples
- **docs/**: Comprehensive guides (usage, configuration, API)
- **CHANGELOG.md**: Well-maintained change history
- **API Documentation**: Method-level documentation with @param, @return
- **Examples**: Practical, copy-paste ready examples
- **Architecture Docs**: Component relationships explained

Files to review:
- `README.md`
- `docs/**/*.md`
- `CHANGELOG.md`
- Inline code documentation

#### C. CLI UX (Target: 8/10)
If package has CLI:
- **Help Text**: Clear, comprehensive `--help` output
- **Options**: Intuitive flags, short forms available
- **Auto-detection**: Smart input type detection
- **Error Messages**: Helpful errors with suggestions
- **Output Modes**: Flexible output options
- **Progress Feedback**: For long operations
- **Exit Codes**: Documented and implemented

Files to examine:
- `exe/[package-name]` - Main CLI executable
- Option parsing logic

#### D. API DX (Developer Experience) (Target: 9/10)
- **API Design**: Intuitive, consistent method names
- **Return Types**: Predictable, well-documented
- **Builder Patterns**: Available for complex scenarios
- **Error Handling**: Errors vs exceptions appropriately used
- **Extensibility**: Easy to extend or customize
- **Metadata Access**: Consistent metadata keys

Files to review:
- `lib/[package-name].rb` - Main API entry point
- Public API methods

#### E. Test Coverage (Target: 8.5/10)
- **Test Structure**: Mirrors library structure
- **Test Types**: Unit, integration, end-to-end tests
- **Test Quality**: Clear, maintainable tests
- **Coverage**: Comprehensive feature coverage
- **Edge Cases**: Error cases well-tested
- **Performance Tests**: For critical paths

Files to check:
- `test/**/*_test.rb` or `spec/**/*_spec.rb`
- Count: `find test -name "*.rb" -type f | wc -l`
- LOC: `find test -name "*.rb" -exec wc -l {} + | tail -1`

### 3. Calculate Scores

Assign scores (0-10) for each category:
- Code Quality & Architecture
- Documentation Quality
- CLI UX (if applicable)
- API DX
- Test Coverage

Calculate overall rating (average of category scores).

### 4. Identify Improvements

Organize recommendations into three priority levels:

#### High Priority (Next Release)
- Critical refactoring needs
- Major UX/DX issues
- Blocking technical debt
- Target: 2-3 high-impact items

#### Medium Priority (Following Release)
- Nice-to-have improvements
- Documentation enhancements
- Performance optimizations
- Target: 3-4 medium-impact items

#### Low Priority (Future Releases)
- Polish and refinements
- Additional features
- Developer convenience
- Target: 3-4 low-impact items

For each recommendation, include:
- **Issue**: What's the problem?
- **Solution**: Specific fix or improvement
- **Files Affected**: Which files need changes
- **Impact**: Why it matters

### 5. Create Taskflow Idea

Create a comprehensive idea file in `.ace-ideas/`:

```bash
# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Create idea file
cat > .ace-ideas/${TIMESTAMP}-[package-name]-comprehensive-review-improvements.s.md <<'EOF'
# Idea

# [package-name] - Comprehensive Review Improvements

## Description

Based on comprehensive code review of [package-name] v[VERSION], implement priority improvements to enhance code quality, DX, UX, and maintainability. Overall package rating: [X.X]/10, with specific areas identified for enhancement.

## Implementation Approach

### High Priority (Target: v[NEXT_VERSION])

[List high priority improvements with details]

### Medium Priority (Target: v[AFTER_NEXT])

[List medium priority improvements]

### Low Priority (Target: v[FUTURE])

[List low priority improvements]

## Technical Considerations

### Code Quality Improvements
[Details on code quality issues and solutions]

### Breaking Changes
[Potential breaking changes and migration paths]

### Performance Implications
[Performance impact analysis]

### Security Considerations
[Security aspects to consider]

## Success Metrics

### Code Quality Metrics
[Measurable quality improvements]

### Developer Experience Metrics
[DX improvement measurements]

### User Experience Metrics
[UX improvement measurements]

## Context

- Package: [package-name] v[VERSION]
- Review Date: $(date +"%Y-%m-%d")
- Overall Rating: [X.X]/10
- Location: active
- Priority: High (foundation improvements for ecosystem)
- Effort: [ESTIMATE]

## Review Findings Summary

### Strengths (Keep These)
[List key strengths with checkmarks]

### Areas for Improvement (This Idea)
[List improvement areas with warning symbols]

---
Captured: $(date +"%Y-%m-%d %H:%M:%S")
Reviewer: Claude Code (Session: [SESSION_ID])
EOF
```

Use actual findings from your review to populate the template.

### 6. Commit and Push Changes

Commit the idea file with a descriptive message:

```bash
git add .ace-ideas/[TIMESTAMP]-[package-name]-comprehensive-review-improvements.s.md

git commit -m "feat(review): Add comprehensive [package-name] package review with improvement recommendations

Created detailed review findings and recommendations for [package-name] v[VERSION]:

Overall Rating: [X.X]/10

High Priority Improvements (v[NEXT]):
- [Item 1]
- [Item 2]
- [Item 3]

Medium Priority (v[AFTER_NEXT]):
- [Item 1]
- [Item 2]
- [Item 3]

Low Priority (v[FUTURE]):
- [Item 1]
- [Item 2]
- [Item 3]

Strengths Identified:
✅ [Strength 1]
✅ [Strength 2]
✅ [Strength 3]

Review conducted on $(date +"%Y-%m-%d") covering:
- Code quality and architecture ([SCORE]/10)
- Documentation completeness ([SCORE]/10)
- CLI UX ([SCORE]/10)
- API DX ([SCORE]/10)
- Test coverage ([SCORE]/10)"
```

Push to current branch:

```bash
git push -u origin $(git branch --show-current)
```

If push fails with network error, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s).

### 7. Output Summary

Provide a summary to the user:

```
## ✅ Package Review Completed: [package-name]

**Overall Rating: [X.X]/10** - [Quality assessment]

### Category Scores
- Code Quality & Architecture: [SCORE]/10
- Documentation: [SCORE]/10
- CLI UX: [SCORE]/10
- API DX: [SCORE]/10
- Test Coverage: [SCORE]/10

### Key Findings
[Bullet points of main findings]

### Recommendations Created
📁 .ace-ideas/[TIMESTAMP]-[package-name]-comprehensive-review-improvements.s.md

Contains:
- [X] prioritized improvement recommendations
- [X] release targets (v[VERSIONS])
- Success metrics and implementation approach
- Full review findings summary

### Git Status
- Branch: $(git branch --show-current)
- Commit: [HASH]
- Status: Pushed to remote ✅

### Create Pull Request
You can create the PR manually using this URL:
https://github.com/cs3b/ace-meta/pull/new/$(git branch --show-current)

Or run:
gh pr create --title "Review: [package-name] comprehensive review with improvement recommendations" --body-file [PR_BODY_FILE]
```

## Best Practices

1. **Be Thorough**: Review all aspects of the package systematically
2. **Be Specific**: Provide file names, line numbers, and concrete examples
3. **Be Constructive**: Focus on improvements, not just problems
4. **Be Practical**: Prioritize based on impact and effort
5. **Be Consistent**: Use the same scoring criteria across packages
6. **Be Honest**: Don't inflate scores; honest feedback helps improve quality

## Example Scoring Guidelines

- **9-10**: Excellent, minor improvements possible
- **7-8**: Good, some notable improvements needed
- **5-6**: Adequate, significant improvements needed
- **3-4**: Below average, major work required
- **1-2**: Poor, complete overhaul needed

## Notes

- If package doesn't have CLI, skip CLI UX section and adjust overall calculation
- For libraries without API (pure CLI tools), skip API DX section
- Adjust priorities based on package maturity and usage
- Consider breaking changes impact when prioritizing recommendations
- Document all assumptions and limitations in the review

---

Run this workflow with: `/ace-review-package [package-name]`
