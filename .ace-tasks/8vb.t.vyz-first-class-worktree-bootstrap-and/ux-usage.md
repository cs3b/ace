# First-class worktree bootstrap and readiness: usage scenarios

## Scenario 1: Configure project bootstrap

**Given** a repository needs a known setup command  
**When** a maintainer runs `config init`, `config set-bootstrap`, and `config show --json`  
**Then** ACE stores a minimal project override and reports the effective command, working directory, timeout, environment, policy, and provenance.

## Scenario 2: Preview preparation

**Given** trust and bootstrap policy are configured  
**When** a user creates with `--dry-run`  
**Then** ACE lists the resolved creation, toolchain-trust, and bootstrap phases without creating a branch/worktree or executing any command.

## Scenario 3: Preserve and retry required failure

**Given** a required bootstrap command fails after worktree creation  
**When** creation exits  
**Then** the branch and worktree remain, readiness is `not_ready`, and ACE prints `ace-git-worktree bootstrap <identifier>` with failure evidence.

**When** the user fixes the prerequisite and runs that retry command  
**Then** ACE prepares the existing worktree and transitions it to `ready` without recreation.

## Scenario 4: Fail closed on mise trust

**Given** the repository tracks `.mise.toml` and trust cannot be proven  
**When** preparation runs under the default required policy  
**Then** the trust phase fails readiness and no bootstrap command is represented as safely completed.

## Scenario 5: Use advisory policy explicitly

**Given** the project explicitly configures an advisory preparation phase  
**When** that phase fails  
**Then** ACE returns `ready_with_warning` and preserves the complete warning evidence.

## Scenario 6: Skip without hiding the decision

**Given** a user intentionally supplies `--no-bootstrap`  
**When** creation completes  
**Then** output records `bootstrap: skipped_by_user`; it does not claim the setup command ran, and no setup behavior is inferred.
