Why a Wrapper Script?

  1. Caching Functionality

  The context tool outputs to stdout, but we need to:
  - Save the output to a specific cache location (docs/context/cached/)
  - Overwrite previous cache files
  - Return the path to the cached file

> we should implement this to context tool
> - context --preset project
> configuration should be in .coding-agent/context.yml
>   - presets should be defined (path to config file and to cache file)
>   - limit of size of the file
>   -


  2. Automatic Chunking

  For Claude Code's file size limits (~150K lines), the wrapper:
  - Checks output size
  - Splits large contexts into chunks automatically
  - Creates an index file with chunk references

> as above - we should have this by default in context (we use it in other parts too)

  3. Simplified Interface

  Instead of:
  context --yaml docs/context/project.md --format markdown-xml > docs/context/cached/project.md  # [Legacy syntax - now: context docs/context/project.md]

  We can just use:
  bin/load-context project

> as feedback to point 1. we can use it as context --preset project

  4. Project-Specific Logic

  - Automatically finds the project root
  - Creates cache directories if needed
  - Provides helpful error messages for missing contexts
  - Lists available contexts when one isn't found

> in dev-tools we have already a logic to reuse (for project root, file create, and yes we should error message and also tests for this cases)

  5. Standardized Workflow

  The wrapper ensures:
  - Consistent output location
  - Same chunking behavior across all uses
  - Clear reporting of what was generated

> use the @docs/architecture-atom.md and redesign the solution

  Could We Use Context Tool Directly?

  Yes, we could! But users would need to:
  1. Remember the full path to context definitions
  2. Manually redirect output to cache files
  3. Handle large file chunking themselves
  4. Create cache directories manually

  The wrapper makes it a one-command operation with all the benefits handled automatically. It's essentially a convenience layer that uses the context
  tool underneath but adds project-specific conventions and safety features.

  Would you prefer to use the context tool directly instead? We could update the workflow to show the full commands if that's more transparent.
