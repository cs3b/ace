---
id: v.0.3.0+task.17
status: pending
priority: high
estimate: 12h
dependencies: ["v.0.3.0+task.13"]
---

# Implement Self-Contained Git Command Wrappers in `bin/`

## 0. Directory Audit ✅

_Command run (illustrative, run before starting work):_

```bash
ls -1 bin/
ls -1 coding-agent-workflow-toolkit-meta/dev-tools/exe-old/_binstubs/ # Check for relevant binstubs
# tree -L 2 fish/ # To understand structure of source Fish scripts
```

_Expected Result Excerpt (after v.0.3.x-13):_

```sh
bin/
build
lint
run
test

coding-agent-workflow-toolkit-meta/dev-tools/exe-old/_binstubs/
build
lint
run
test
tn
tr
tree
```

_Source Fish scripts to analyze:_

- `fish/functions-cs3b/gc-llm.fish`
- `fish/functions-cs3b/gemini-query.fish`
- `fish/functions-cs3b/lms-query.fish`
- `fish/aliases-cs3b/git.fish` (for `gllc`, `gp`, `gsv`, `gss` aliases)

## Objective

To make common Git operations (`commit`, `log`, `push`, `status`) self-contained within the project by creating
portable POSIX-compliant shell scripts in the project's `bin/` directory. These scripts will replace reliance on
user-specific Fish shell functions and aliases, ensuring that core Git workflows are consistently available to all
contributors and AI agents, regardless of their local shell setup. The `commit` script (`bin/gc`) should retain the
capability to generate commit messages using LLMs.

## Scope of Work

- Analyze the provided Fish scripts (`gc-llm.fish`, `gemini-query.fish`, `lms-query.fish`, `git.fish`) to extract
  the core logic for Git commands and LLM interactions.
- Create the following executable POSIX shell scripts in the project's `bin/` directory:
  - `bin/gs`: Wrapper for `git status`. Should aim to replicate `git status --short` or `git status --verbose`
    (e.g., default to short, with a flag for verbose).
  - `bin/gl`: Wrapper for `git log`. Should aim to replicate `git log --oneline --decorate --color`.
  - `bin/gp`: Wrapper for `git push`. Should pass arguments directly to `git push`.
  - `bin/gc`: Wrapper for `git commit`. This is the most complex script and needs to:
    - Accept file paths as arguments to stage, or stage all changes if no paths are given (similar to `gaa && gcm`).
    - Handle an `-i` or `--intention` flag to capture user's intent for the commit message.
    - Generate a diff of staged changes.
    - Construct a prompt for an LLM, incorporating the diff and any provided intention.
    - **LLM Interaction:**
      - Provide a mechanism to call LLMs for commit message generation. This will likely involve creating two helper
        scripts in `dev-tools/exe-old/` (e.g., `dev-tools/exe-old/llm_query_gemini.sh` and
        `dev-tools/exe-old/llm_query_lms.sh`) that encapsulate the `curl` calls and API key
        handling logic from `gemini-query.fish` and `lms-query.fish`.
      - `bin/gc` will call one of these scripts based on a flag (e.g., `--local` for LM Studio, default to Gemini
        or configurable).
      - API keys (e.g., `GEMINI_API_KEY`) should be read from environment variables. The helper scripts should
        provide clear error messages if keys are missing.
    - Clean the LLM-generated commit message (remove markdown code blocks, trim whitespace).
    - Allow the user to edit the generated commit message by default (invoking `git commit --edit -m "<message>"`).
    - Support a `--no-edit` flag to commit directly using the generated message (`git commit -m "<message>"`).
- Ensure all created scripts are POSIX-compliant and executable.
- Document the new `bin/` scripts in the project's main `README.md`.

### Deliverables

#### Create

- `bin/gs` (executable shell script)
- `bin/gl` (executable shell script)
- `bin/gp` (executable shell script)
- `bin/gc` (executable shell script)
- `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_gemini.sh` (executable helper script for Gemini API
  calls)
- `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_lms.sh` (executable helper script for LM Studio API
  calls)
- `coding-agent-workflow-toolkit-meta/dev-handbook/prompts/gc_llm_commits.guide.md` (copy or adapt from
  `fish/functions-cs3b/prompts/gc-llm-commits.guide.md` if it exists, or create based on `gc-llm.fish`'s
  embedded guide)

#### Modify

- `README.md` to document the new `bin/gs`, `bin/gl`, `bin/gp`, `bin/gc` commands.
- Potentially update `.gitignore` if helper scripts or their configurations produce temporary files (unlikely if
  API keys are via env vars).

## Phases

1. **Analysis & Design (LLM Interaction):**
    - Thoroughly analyze `gc-llm.fish`, `gemini-query.fish`, and `lms-query.fish`.
    - Design the structure and arguments for `llm_query_gemini.sh` and `llm_query_lms.sh`.
    - Determine how `bin/gc` will select and invoke these helper scripts.
    - Confirm API key management strategy (environment variables).
    - Ensure the commit message generation prompt and guide (`gc_llm_commits.guide.md`) are properly handled.
2. **Implementation (Helper LLM Scripts):**
    - Create `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_gemini.sh`.
    - Create `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_lms.sh`.
    - Create/copy `coding-agent-workflow-toolkit-meta/dev-handbook/prompts/gc_llm_commits.guide.md`.
    - Test these scripts independently with sample API calls.
3. **Implementation (Simple Git Wrappers):**
    - Create and test `bin/gs`.
    - Create and test `bin/gl`.
    - Create and test `bin/gp`.
4. **Implementation (`bin/gc`):**
    - Implement argument parsing (`files`, `--intention`, `--no-edit`, LLM choice flag like `--local`).
    - Implement `git add` logic.
    - Implement `git diff --staged` logic.
    - Implement prompt construction using the diff, intention, and `gc_llm_commits.guide.md`.
    - Implement logic to call the appropriate LLM helper script.
    - Implement commit message cleaning.
    - Implement `git commit` execution with and without `--edit`.
5. **Testing & Refinement:**
    - Test all `bin/` scripts thoroughly with various scenarios and arguments.
    - Ensure POSIX compliance and error handling.
6. **Documentation:**
    - Update `README.md` with usage instructions for the new scripts.

## Implementation Plan

- [ ] **Phase 1: Analysis & Design (LLM Interaction)**
  - [ ] Review `gc-llm.fish`:
    - [ ] Identify argument parsing (`-n-no-edit`, `-i-intention=`, `-l-local`, `files`).
    - [ ] Note `git add` logic.
    - [ ] Note `git diff --staged` usage.
    - [ ] Extract prompt construction logic, including use of `gc-llm-commits.guide.md` and
      intention.
    - [ ] Note calls to `lms-query` and `gemini-query`.
    - [ ] Note commit message cleaning steps (`sed`, `string trim`, `string collect`).
    - [ ] Note `git commit` logic (`--edit` vs. direct `-m`).
  - [ ] Review `gemini-query.fish`:
    - [ ] Note API key handling (`GEMINI_API_KEY` from `.env` or env).
    - [ ] Note system message and model selection.
    - [ ] Note `curl` command structure, URL, and JSON payload (especially
      `systemInstruction`).
    - [ ] Note response parsing (`jq`).
  - [ ] Review `lms-query.fish`:
    - [ ] Note system message (including XML loading, though this might be simplified to text for shell
      script) and model selection.
    - [ ] Note `curl` command structure for LM Studio (localhost).
    - [ ] Note response parsing (`jq`).
  - [ ] Design `llm_query_gemini.sh`:
    - [ ] Plan arguments: system prompt, user prompt, model (optional).
    - [ ] Plan `GEMINI_API_KEY` environment variable check.
    - [ ] Plan `curl` command and JSON payload construction.
  - [ ] Design `llm_query_lms.sh`:
    - [ ] Plan arguments: system prompt, user prompt, model (optional).
    - [ ] Plan `curl` command for LM Studio.
  - [ ] Plan how `bin/gc` will pass the commit guide content as the system prompt to these helper
    scripts.
- [ ] **Phase 2: Implementation (Helper LLM Scripts & Guide)**
  - [ ] Create `coding-agent-workflow-toolkit-meta/dev-handbook/prompts/gc_llm_commits.guide.md` by copying content
    from `fish/functions-cs3b/prompts/gc-llm-commits.guide.md` (if it exists and is accessible) or by
    reconstructing its essence from `gc-llm.fish`.
  - [ ] Implement `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_gemini.sh`:
    - [ ] Add shebang `#!/bin/sh`.
    - [ ] Implement argument parsing (e.g., using `getopts` or simple positional).
    - [ ] Check for `GEMINI_API_KEY`.
    - [ ] Construct and execute `curl` command for Gemini API.
    - [ ] Parse response using `jq` (ensure `jq` is a documented prerequisite or handle its absence gracefully).
    - [ ] `chmod +x`.
  - [ ] Implement `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_lms.sh`:
    - [ ] Add shebang `#!/bin/sh`.
    - [ ] Implement argument parsing.
    - [ ] Construct and execute `curl` command for LM Studio.
    - [ ] Parse response using `jq`.
    - [ ] `chmod +x`.
  - [ ] Test helper scripts with sample inputs.
- [ ] **Phase 3: Implementation (Simple Git Wrappers)**
  - [ ] Create `bin/gs`:
    - [ ] Shebang `#!/bin/sh`, `set -e`.
    - [ ] Implement `git status --short "$@"` by default.
    - [ ] Add option (e.g., `-v` or `--verbose`) for `git status --verbose "$@"`.
    - [ ] `chmod +x bin/gs`.
  - [ ] Create `bin/gl`:
    - [ ] Shebang `#!/bin/sh`, `set -e`.
    - [ ] Implement `git log --oneline --decorate --color "$@"`.
    - [ ] `chmod +x bin/gl`.
  - [ ] Create `bin/gp`:
    - [ ] Shebang `#!/bin/sh`, `set -e`.
    - [ ] Implement `git push "$@"`.
    - [ ] `chmod +x bin/gp`.
  - [ ] Test `bin/gs`, `bin/gl`, `bin/gp`.
- [ ] **Phase 4: Implementation (`bin/gc`)**
  - [ ] Shebang `#!/bin/sh`, `set -e`.
  - [ ] Implement argument parsing for files, `--intention`, `--no-edit`, `--local` (or similar for LLM choice).
  - [ ] If files are provided, `git add \"$@\" (files)`. If no files, consider `git add -A` or `git add -u`
    (decide and document).
  - [ ] `COMMIT_INTENTION=""`, `NO_EDIT_FLAG=false`, `USE_LOCAL_LLM=false`. Parse flags.
  - [ ] `DIFF_OUTPUT=$(git diff --staged)`. Check if empty.
  - [ ] Read `COMMIT_GUIDE_CONTENT` from
    `coding-agent-workflow-toolkit-meta/dev-handbook/prompts/gc_llm_commits.guide.md`.
  - [ ] Construct `SYSTEM_PROMPT` (from guide) and `USER_PROMPT` (from diff and intention).
  - [ ] Conditional call to LLM helper:
    - If `USE_LOCAL_LLM` is true,
      `RAW_COMMIT_MSG=$(./coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_lms.sh -s \"$SYSTEM_PROMPT\" \"$USER_PROMPT\")`.
    - Else,
      `RAW_COMMIT_MSG=$(./coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_gemini.sh -s \"$SYSTEM_PROMPT\" \"$USER_PROMPT\")`.
    - Handle errors from helper scripts.
  - [ ] Clean `RAW_COMMIT_MSG` (e.g., using `sed` to remove markdown backticks,
    `echo \"$MSG\" | tr -s \' \\t\\n\' \' \' | sed \'s/^ *//;s/ *$//'` or similar POSIX ways to trim).
  - [ ] `FINAL_COMMIT_MSG=$(echo \"$CLEANED_MSG\" | awk \'NF {print $0; found=1} END {if (!found) print \"\"}\')`
    (ensure one newline).
  - [ ] Conditional commit:
    - If `NO_EDIT_FLAG` is true, `git commit -m "$FINAL_COMMIT_MSG"`.
    - Else, `git commit --edit -m "$FINAL_COMMIT_MSG"`.
  - [ ] `chmod +x bin/gc`.
- [ ] **Phase 5: Testing & Refinement**
  - [ ] Test `bin/gc` with file arguments and without.
  - [ ] Test `bin/gc` with `--intention`.
  - [ ] Test `bin/gc` with `--no-edit`.
  - [ ] Test `bin/gc` with `--local` (requires LM Studio running) and without (requires Gemini API key).
  - [ ] Test `bin/gc` with empty diff.
  - [ ] Test `bin/gc` with LLM errors or empty responses.
  - [ ] Verify POSIX compliance of all scripts (e.g., use `checkbashisms` or test in a minimal POSIX shell).
- [ ] **Phase 6: Documentation**
  - [ ] Add a new section to `README.md` detailing `bin/gs`, `bin/gl`, `bin/gp`, and `bin/gc`.
  - [ ] Include usage examples and any prerequisites (e.g., `jq`, `GEMINI_API_KEY` environment
    variable, LM Studio for `--local`).

## Acceptance Criteria

- [ ] `bin/gs`, `bin/gl`, `bin/gp`, `bin/gc` scripts exist in the project's `bin/` directory and are
  executable.
- [ ] `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_gemini.sh` and
  `coding-agent-workflow-toolkit-meta/dev-tools/exe-old/llm_query_lms.sh` exist, are executable, and can
  successfully query their respective LLMs.
- [ ] `coding-agent-workflow-toolkit-meta/dev-handbook/prompts/gc_llm_commits.guide.md` exists and
  contains the commit
  message generation guide.
- [ ] `bin/gs` correctly displays Git status (short and verbose options work).
- [ ] `bin/gl` correctly displays Git log in the specified format.
- [ ] `bin/gp` correctly performs `git push`, passing through arguments.
- [ ] `bin/gc` can stage specified files or all changes.
- [ ] `bin/gc` correctly uses the `--intention` flag.
- [ ] `bin/gc` successfully calls the appropriate LLM helper script (`--local` flag works) to generate a commit
  message based on the diff and intention.
- [ ] `bin/gc` cleans the LLM response.
- [ ] `bin/gc` allows editing the commit message by default and skips editing with `--no-edit`.
- [ ] All scripts are POSIX-compliant.
- [ ] `README.md` is updated to document the new `bin/` scripts and their usage, including LLM helper script
  prerequisites.

## Out of Scope

- Replicating all Fish aliases from `git.fish` beyond the core `gc`, `gl`, `gp`, `gs` (e.g., `gcma`, `gcama`,
  `gcmap` which are combinations). Users can chain the new `bin/` scripts if needed.
- Implementing the `gh-rc` functionality (GitHub repository creation).
- Making the LLM helper scripts (`llm_query_gemini.sh`, `llm_query_lms.sh`) discoverable on the system `PATH`
  (they will be called via their relative path from `bin/gc`).
- Advanced interactive features in the scripts beyond what standard Git commands offer (e.g., interactive staging
  within `bin/gc`).
- Support for LLM providers other than Gemini and LM Studio unless explicitly added.
- Automatic installation of `jq`.

## References

- `fish/functions-cs3b/gc-llm.fish`
- `fish/functions-cs3b/gemini-query.fish`
- `fish/functions-cs3b/lms-query.fish`
- `fish/aliases-cs3b/git.fish`
- `coding-agent-workflow-toolkit-meta/dev-handbook/guides/write-actionable-task.md`
- POSIX shell scripting guides.
- `git` command documentation (`git add`, `git diff`, `git commit`, `git log`, `git status`, `git push`).
- `curl` documentation.
- `jq` documentation.
- Gemini API documentation.
- LM Studio API documentation.
