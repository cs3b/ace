# Prune acceptance scenarios
1. `bin/ace-overseer prune 8wr.t.example --force --dry-run`: an unmerged or actively written fixture is listed as blocked with HEAD and missing proof; no metadata, files or runtime windows change. Apply with `--yes --force` remains blocked and exits nonzero.
2. `bin/ace-overseer prune 8wr.t.example --preservation .ace-local/prune/destinations.yml --dry-run`: verify the manifest below against two temporary repos, then display accepted content equivalence. Running with `--yes` recomputes proof; changing either HEAD invalidates it.
```yaml
version: 1
candidates:
  - worktree_path: /tmp/source-task
    source_repo: /tmp/source
    source_base: <source-base-sha>
    source_head: <source-head-sha>
    destination_repo: /tmp/successor
    destination_base: <destination-base-sha>
    destination_head: <accepted-head-sha>
    destination_branch: refs/heads/main
```
3. `bin/ace-overseer prune --assignment fixture --force --yes --quiet`: an uncertain attempt or missing durable artifact returns nonzero without deleting cache/journal. `--runtime lab --dry-run WORK_ID` reports an in-flight or unprovable Work as blocked; apply cannot delegate destroy.
