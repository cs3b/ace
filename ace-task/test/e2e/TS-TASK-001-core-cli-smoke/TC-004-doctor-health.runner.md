# Goal 4 - Doctor Health/Error Path

## Goal

Run `ace-task doctor` in a healthy state, then inject a malformed task file and confirm doctor reports issues.

## Workspace

Save all artifacts to `results/tc/04/`.

## Constraints

- Keep all writes in sandbox paths.
- This goal is order-sensitive: capture `doctor-healthy.*` before creating any malformed task file.
- Capture both healthy and unhealthy command runs.

## Steps

1. Ensure clean baseline by removing `.ace-tasks/8zz.t.bad-broken` if it exists from prior runs.
2. Run `ace-task doctor` and save `doctor-healthy.*`.
3. After `doctor-healthy.*` is saved, create a malformed task file at `.ace-tasks/8zz.t.bad-broken/8zz.t.bad-broken.s.md` with otherwise valid frontmatter but an invalid `status` value. Include at least `id`, `title`, `status`, `tags`, and `created_at` so the broken state isolates the status-validation path.
4. Run `ace-task doctor` again and save `doctor-broken.*`.
5. Save malformed file content to `results/tc/04/broken-task.txt`.
