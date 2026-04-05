# ace-hitl Smart Scope Resolution - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Check blockers from a task worktree

**Goal**: See only the pending HITL items relevant to the current worktree without passing extra flags.

```bash
ace-hitl list
```

**Expected Output**

Shows pending HITL items for the current worktree only. If no pending items exist locally, output is empty but not an error.
The default status filter is `pending` unless overridden with `--status`.

### Scenario 2: Review all pending HITL items from the main checkout

**Goal**: Act as an operator from the main checkout and see pending HITL items across worktrees.

```bash
ace-hitl list
```

**Expected Output**

Shows pending HITL items across all worktrees by default, with enough location detail to understand where each item lives.

### Scenario 3: Force a project-wide lookup from a task worktree

**Goal**: Widen the search explicitly when working inside a task worktree.

```bash
ace-hitl list --scope all
```

**Expected Output**

Shows matching HITL items across all worktrees instead of only the current worktree.

### Scenario 4: Strict local lookup failure

**Goal**: Fail clearly when an item is not present in the current scope and the user requested strict local lookup.

```bash
ace-hitl show t.abc --scope current
```

**Expected Output**

Returns a clear not-found error for the current scope only. The command must not silently widen to all worktrees.

### Scenario 5: Smart fallback resolves outside current worktree

**Goal**: Keep implicit smart lookup user-friendly while making cross-worktree resolution explicit.

```bash
ace-hitl show t.abc
ace-hitl show t.abc --content
```

**Expected Output**

If `t.abc` is not found in the current scope but is found via smart fallback, both command forms include an explicit resolved-location line (path/worktree).

### Scenario 6: Ambiguous global lookup fails with candidate paths

**Goal**: Ensure all-scope `show` does not silently choose when shortcut refs collide across worktrees.

```bash
ace-hitl show 123 --scope all
```

**Expected Output**

Returns an ambiguity error that lists candidate paths for disambiguation.

## Notes for Implementer

Full usage documentation should be completed during implementation using `wfi://docs/update-usage`.
For this slice, documentation edits are limited to `ace-hitl` docs; treat `ace-overseer` docs as reference-only.
