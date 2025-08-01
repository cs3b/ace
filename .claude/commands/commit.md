# Goal

Ensure all changes you have made in the current session, or what user point to are commit in git.

# PLAN

1. Ensure you commit (using `git-commit`) all changes that you have modified / created / deleted in this session (if user not ask differently). e.g.: git-commit item1/path/to item2/path/to item3/path/to ... --intention "write a intention of changes in the session" => `git-commit dev-tools/src/main.rb dev-tools/spec/test.rb dev-handbook/tpl/dotfiles/path.yml --intention "fix authentication bug"`

2. Run `git-status` to check if everything you modified have beedn commited.

# Supplementary Inforatiom about Git toolbox

1. **Check current status**: Run `git-status` to see all changes across repositories
2. **Commit with intention**:
   - **Specific files**: `git-commit path/1/file path/2/file --intention "why we commit"`
     - Use full paths from project root (works with submodules): `dev-tools/lib/main.rb dev-handbook/guide.md`
     - Or local paths from current directory: `lib/main.rb spec/test.rb`
   - **All changes**: `git-commit --intention "why we commit"` (only when everything in the repos should be commited)

**Examples:**
```bash
# Commit specific files with intention (local paths)
git-commit src/main.rb spec/test.rb --intention "fix authentication bug"

# Commit files across submodules (full paths from project root)
git-commit dev-tools/lib/main.rb dev-handbook/guides/setup.md --intention "update setup documentation"

# Commit all changes
git-commit --intention "update documentation"
```

The enhanced git-commit tool automatically generates appropriate commit messages based on changes and intention.
