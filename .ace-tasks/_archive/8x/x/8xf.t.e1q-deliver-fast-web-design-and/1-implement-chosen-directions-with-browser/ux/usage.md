# Implement chosen directions with browser evidence: usage contract

## Happy path

/as-design-site-implement SESSION; /as-design-app-implement SESSION; /as-design-site-audit URL; /as-design-app-audit URL; ace-design inspect URL --surface site|app [--out DIR].

Expected: User hands selected direction to engineering or audits an existing URL; receives functioning implementation and inspectable browser evidence with honest coverage.

## Invalid input

A missing target/session or unavailable browser produces a specific error, preserves prior artifacts, and never claims completion.

## Resume

Reuse the recorded context and decisions; only requested variants or affected checks run again.
