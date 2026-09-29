# Observed `fj` (forgejo-cli) surface — capability and argv evidence

Task: 8wr.t.uj0. Recorded 2026-09-29. This file is the implementation's
capability source of truth: argv forms below are copied from real binary
observation, not invented. Everything not listed as observed is unsupported
for selection binding.

## Provenance and observation limits

- The Lab machines have **no `fj` binary on PATH** and this workstation has
  no Lab API token (the Lab Forgejo answers `401 Only signed in user is
  allowed to call APIs.` for unauthenticated API calls, verified 2026-09-29
  against `https://forgejo.tail6c0887.ts.net`). The Lab's own installed
  version could therefore **not** be queried from here; **SC4 stays open**
  for the Lab-specific version/help record and the Lab smoke test.
- Observation source: the upstream release binary
  `forgejo-cli-aarch64-linux.tar.gz` from
  `https://codeberg.org/forgejo-contrib/forgejo-cli/releases/tag/v0.6.0`
  (latest release as of 2026-09-29), executed inside a linux/arm64 Debian
  container on this workstation. This is the same upstream tool and version
  the qk1.0 review cited ("fj v0.6.0 per the forgejo-cli wiki"), upgraded
  from wiki text to binary observation. Per-subcommand `--help` was captured
  for: `pr search|view|create|edit|merge|close|status`, `issue view|create|edit|close|search`,
  `repo view|create|clone|fork|edit`, `actions tasks`, `auth list`,
  `version`, `whoami`.
- Read-only behavior was exercised against a real Forgejo server
  (`codeberg.org`, unauthenticated reads) using the exact argv forms listed
  below. No mutation was sent anywhere. No credentials exist in this
  evidence; the container used an empty throwaway `$HOME`.
- The runtime gate treats only versions in this table as observed
  (`v0.6.0`). A different installed version is refused with
  `ProviderUnsupportedCapabilityError` until re-observed; it must not
  inherit capabilities from this fixture.

## Targeting surface (v0.6.0)

Global options: `-H/--host <HOST>`, `-C/--cwd <CWD>` (sets working
directory), `--style <fancy|minimal>` (minimal is forced for pipes).

Two explicit-target mechanisms exist; both are used by the provider:

1. **Repo flag** `-r, --repo <OWNER/REPO>` (with `-H` for the host):
   `pr search`, `pr create`, `issue search`, `issue create`,
   `actions tasks`.
2. **Qualified ID** `[OWNER/REPO]#<N>` as the object argument (with `-H`):
   `pr view` (incl. `diff`/`commits` subcommands), `pr status`, `pr edit`,
   `pr close`, `pr merge`, `issue view`. Confirmed in v0.6.0 source
   (`src/prs.rs` `repo()`/`no_repo_error()`: View, Status, Comment, Assign,
   Unassign, Edit, Close, Merge, Browse, Review all parse the same
   `owner/repo#N` argument) and live for view/status/issue-view.

A bare number without a checkout fails closed by fj itself:
`Error: can't figure out what repo to access, try specifying with
`{owner}/{repo}#700`` (observed, exit 1). URL-form IDs are rejected by the
argument parser (`invalid digit found in string`). `-R/--remote` names a
local git remote — still checkout-dependent (ambient), never used by ACE.

## Operation matrix (provider operation → observed argv)

`H` = selected host, `R` = selected `owner/repo`, `N` = PR/issue number.
`-H H` is stamped by the executor boundary on every repository command.

| Operation | Observed argv | Evidence level |
| --- | --- | --- |
| pr view | `fj -H H --style minimal pr view R#N` | live (codeberg) |
| pr head commits | `fj -H H --style minimal pr view R#N commits` | live |
| pr diff | `fj -H H pr view R#N diff` | live |
| pr search (all/open) | `fj -H H --style minimal pr search --state all -r R` | live |
| pr create | `fj -H H pr create TITLE --head BR --base BASE --body BODY -r R` | help + source (mutation not live-fired) |
| pr edit title | `fj -H H pr edit R#N title NEW` | source (mutation not live-fired) |
| pr edit body | `fj -H H pr edit R#N body NEW` | source (mutation not live-fired) |
| issue view | `fj -H H --style minimal issue view R#N` | live |
| actions tasks | `fj -H H --style minimal actions tasks -r R` | help (+ live error shape) |
| repo view | `fj -H H --style minimal repo view R` | live |
| version probe | `fj version` | live (`fj v0.6.0` on stdout, exit 0) |
| auth probe | `fj auth list` | live: **no logins → stderr `No logins.`, exit 0**; host lines expected on stdout/stderr; ACE compares stripped lines exactly against the selected authority |

## Confirmed output shapes (live, minimal style)

- `pr search` header `N pull requests`, entries `#N: title (by author)`,
  bidi isolates (U+2066/U+2069) around dynamic fields, newest first,
  **no `--limit` flag** (client-side cap required).
- `pr view`: `title #N` / `By author — State — +a -d` (em-dash separators)
  / `` From `owner/repo:branch` into `main` `` (repo prefix only for fork
  PRs), then body and `N comments`. Matches the existing parser after
  control/bidi stripping; fixtures updated to the real em-dash shape.
- `pr view R#N commits`: `commit <sha> (+a, -d)` first line — head SHA.
- `repo view R`: first line `owner/repo`, `View online at <url>` line.
- `actions tasks` on a repo without Actions: stderr
  `Error: not found: The target couldn't be found.`, exit 1 → classified
  `ProviderObjectNotFoundError`. The success listing shape (fixtures) is
  wiki-derived and **not** validated against a real Actions-enabled host.
- Lab unauthenticated API text: `Only signed in user is allowed to call
  APIs.` — classified as authentication failure.

## Unsupported capabilities (explicit, fail-closed)

- **No authoritative merge-commit field anywhere** in v0.6.0 output
  (`pr view`, `pr status`, `pr view commits` all observed). `pr status` on
  a merged PR shows `Merged by <user> on <date>` (and panics in v0.6.0 on a
  `$created_at` template bug) — no SHA. Therefore the Forgejo provider keeps
  `merge_commit_sha: nil`; Forgejo cleanup conservatively retains checkouts
  until fj exposes the field. No parser for a merge field is added.
- No draft-to-ready command (`pr` has no ready subcommand).
- `pr merge` has no expected-head precondition (methods: merge, rebase,
  rebase-merge, squash, manual) — atomic-head refusal stays.
- Draft PRs only via `WIP: ` title prefix (a title mutation) — not used;
  evidence reports `draft: nil`.
- Fork-head `pr create` (`--head owner:branch` syntax) is unproven help-wise
  → cross-repo head refusal stays before any subprocess.
- `-H` with a port-bearing authority and plain-http server URLs are untested
  against a real server (Lab is https/443); runtime failures classify as
  unreachable — recorded as a limitation, not worked around.

## Read-only smoke probes (real binary, real server, exact bound argv)

Executed in the container (`debian:stable-slim`, linux/arm64, empty
throwaway `$HOME`, `ca-certificates` installed; no login configured):

- `./fj -H codeberg.org --style minimal repo view forgejo-contrib/forgejo-cli`
  → full name line + `View online at https://codeberg.org/...` (exit 0).
- `./fj -H codeberg.org --style minimal pr search -r forgejo-contrib/forgejo-cli --state all`
  → `30 pull requests` + newest-first `#N: title (by author)` entries.
- `./fj -H codeberg.org --style minimal pr search ... --state open` → open subset.
- `./fj -H codeberg.org --style minimal pr view forgejo-contrib/forgejo-cli#700`
  → merged PR view (em-dash byline, `From Fluffinity/forgejo-cli:...` fork
  segment, body, `0 comments`).
- `... pr view ...#700 commits` → `commit 80c7e92efbaa...(+1, -0)` head SHA line.
- `... pr view ...#700 diff` → raw unified diff.
- `... issue view forgejo-contrib/forgejo-cli#5` → issue view layout.
- `... pr status ...#700` / `...#711` → mergeability + CI checks, **no merge
  SHA**; merged case panics in fj v0.6.0 (`$created_at` template bug).
- `./fj -H codeberg.org --style minimal pr view 700` (bare number, no
  checkout) → `Error: can't figure out what repo to access, try specifying
  with `  {owner}/{repo}#700`` (exit 1) — proves ambient failure mode.
- `./fj version` → stdout `fj v0.6.0` + update hint, exit 0.
- `./fj auth list` (no logins) → stderr `No logins.`, exit 0.

Corroboration: real **Lab** output captured during qk1.0 (2026-09-23,
`ace-git-forgejo/test/fixtures/*.txt`: lab PR #26 view/commits, issue view,
search listing, `cs3b/ace` repo view on `forgejo.tail6c0887.ts.net`) shows
the same shapes, including fork `From lab-builder/ace:lab/W675-ace`
segments — the Lab's fj produced output byte-compatible with upstream
v0.6.0 observation.

## Reproduction

```text
curl -L -o /tmp/uj0-fj/fj.tar.gz \
  https://codeberg.org/forgejo-contrib/forgejo-cli/releases/download/v0.6.0/forgejo-cli-aarch64-linux.tar.gz
tar xzf fj.tar.gz   # single `fj` binary
docker run --rm --platform linux/arm64 -v /tmp/uj0-fj:/work -w /work \
  debian:stable-slim sh -c 'export HOME=/tmp; apt-get update -qq && apt-get install -y -qq ca-certificates; ./fj version'
```

Lab smoke test (SC4, OPEN): with Lab credentials + installed `fj`, run
`bin/ace-git pr show <PR> --server <NAME> --format json` from another
checkout and compare returned identity to the selection; record redacted
output here. Not replaceable by the codeberg probes or mocks.
