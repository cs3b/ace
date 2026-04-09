# Goal 8 — Batch Sort Order

## Goal

Encode a fixed set of out-of-order dates, then compare encode-order vs token-sorted
order to prove lexical ordering behavior.

## Workspace

Save output to `results/tc/08/` using this contract:

- `encode-order.tsv` — rows in the exact encode sequence
- `sorted-order.tsv` — same rows sorted lexicographically by token

Each row must be tab-separated:
`<token>\t<date>`

## Constraints

- Use exactly these dates in this encode order:
  1. `2025-01-09T00:00:00Z`
  2. `2025-01-06T00:00:00Z`
  3. `2025-01-12T00:00:00Z`
  4. `2025-01-07T00:00:00Z`
- Use `--format day` for all encodes to keep token granularity consistent.
- Produce `sorted-order.tsv` using a real sort tool (`sort`), not manual rearrangement.
- Do not fabricate tokens.
