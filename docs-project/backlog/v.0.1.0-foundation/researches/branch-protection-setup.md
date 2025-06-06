# Branch Protection Setup for GitHub Repository

## Overview

This document outlines the required branch protection settings for the main branch of the Coding Agent Tools repository to ensure CI/CD pipeline integrity and code quality.

## Required Branch Protection Rules

### Main Branch Protection Settings

**Branch Name Pattern:** `main`

### Required Status Checks

The following status checks must pass before merging:

1. **CI / Ruby 3.2**
   - Status check name: `test (3.2)`
   - Required for merge: ✅ Yes
   - Dismiss stale reviews: ✅ Yes

2. **CI / Ruby 3.3** 
   - Status check name: `test (3.3)`
   - Required for merge: ✅ Yes
   - Dismiss stale reviews: ✅ Yes

3. **CI / Ruby 3.4**
   - Status check name: `test (3.4)`
   - Required for merge: ✅ Yes
   - Dismiss stale reviews: ✅ Yes

4. **Build Gem**
   - Status check name: `build`
   - Required for merge: ✅ Yes
   - Dismiss stale reviews: ✅ Yes

### Additional Protection Settings

**Require branches to be up to date before merging:**
- ✅ Enabled
- This ensures the branch includes the latest changes from main

**Require pull request reviews before merging:**
- ✅ Enabled 
- Required number of reviewers: 1
- Dismiss stale PR reviews when new commits are pushed: ✅ Enabled
- Require review from code owners: ⚠️ Optional (when CODEOWNERS file exists)

**Restrict pushes that create files larger than 100 MB:**
- ✅ Enabled

**Require signed commits:**
- ⚠️ Optional (recommended for security)

**Require linear history:**
- ✅ Enabled (prevents merge commits, enforces rebase/squash)

**Allow force pushes:**
- ❌ Disabled

**Allow deletions:**
- ❌ Disabled

## Setup Instructions

### Via GitHub Web Interface

1. Navigate to repository Settings
2. Go to "Branches" section
3. Click "Add rule" for main branch
4. Configure settings as outlined above
5. Save the branch protection rule

### Via GitHub CLI (if authenticated)

```bash
# Create branch protection rule
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test (3.2)","test (3.3)","test (3.4)","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

### Verification

After setup, verify protection rules by:

1. Attempting to push directly to main (should fail)
2. Creating a test PR without CI passing (should not be mergeable)
3. Checking that CI must complete before merge button is enabled

## Expected Workflow

1. Developer creates feature branch from main
2. Developer pushes commits to feature branch
3. Developer opens PR against main
4. CI pipeline runs automatically on PR
5. All status checks must pass:
   - Ruby 3.2 tests and linting
   - Ruby 3.3 tests and linting  
   - Ruby 3.4 tests and linting
   - Gem build success
6. Code review required (if review rules enabled)
7. Branch must be up-to-date with main
8. Merge is allowed only when all conditions are met

## Troubleshooting

**Common Issues:**

1. **Status checks not appearing:**
   - Ensure CI workflow has run at least once
   - Check workflow file syntax with `actionlint`
   - Verify workflow triggers include `pull_request`

2. **Cannot merge despite passing CI:**
   - Check if branch is up-to-date with main
   - Verify all required status checks are listed correctly
   - Ensure required reviews are provided

3. **Status check names mismatch:**
   - Check actual job names in GitHub Actions logs
   - Update protection rules to match exact job names
   - Case-sensitive matching required

## Maintenance

**Regular Tasks:**

- Review status check requirements when CI workflow changes
- Update protection rules if new required checks are added
- Monitor for any bypassed protection rules in audit logs
- Verify settings remain effective after repository configuration changes

## Security Considerations

- Branch protection rules should not be bypassable by administrators in production
- Regular audit of who has admin access to modify these rules
- Monitor for any force pushes or protection rule modifications
- Consider requiring signed commits for additional security

## Integration with CI/CD Pipeline

These protection rules work in conjunction with:
- `.github/workflows/ci.yml` workflow file
- Required status checks that match CI job names
- Automated testing and linting processes
- Pull request review workflows

The protection rules ensure that no code reaches main without proper validation through the complete CI/CD pipeline.