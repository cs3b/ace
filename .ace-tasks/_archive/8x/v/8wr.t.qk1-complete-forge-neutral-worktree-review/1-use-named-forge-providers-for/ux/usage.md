# Provider-neutral review — usage

## Review named Forgejo
`ace-review --pr 25 --server forgejo-lab --preset code-valid --provider-timeout 60`
Expected: session and verdict bound to exact server/repository/PR/head; comments/check states preserve identity.

## Prepare only
`ace-review --pr 25 --server forgejo-lab --preset code-valid --dry-run`
Expected: prepared evidence/context, no LLM execution or posted comments. No verdict implies completed review.

## Invalid head or unsupported operation
Input: PR head changes while collection runs, or selected provider cannot resolve a requested thread.
Expected: non-approval head conflict or explicit unsupported capability. Never claim review/resolve success; CI failure alone is advisory.
