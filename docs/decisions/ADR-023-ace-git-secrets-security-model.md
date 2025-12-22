# ADR-023: ace-git-secrets Security Model

## Status

Accepted
Date: 2025-12-22

## Context

ace-git-secrets is a security-focused gem that detects, removes, and revokes authentication tokens from Git history. As a security tool, it requires a documented security model that addresses:

1. **Detection Strategy** - How we find tokens and why we chose specific approaches
2. **Token Handling** - How raw tokens are managed in memory and on disk
3. **Threat Model** - What threats we protect against and explicit non-goals
4. **Defense in Depth** - Multiple layers of protection

## Decision

### Detection Strategy: Gitleaks Integration + Ruby Fallback

**Why gitleaks as primary:**
- Actively maintained pattern library with regular updates
- Fast scanning using Go's performance characteristics
- Community-validated patterns reduce false negatives
- Industry-standard tool increases trust

**Why Ruby fallback:**
- Ensures functionality without external dependencies
- Allows custom patterns for internal tokens
- Provides offline scanning capability
- Uses same confidence levels for consistent UX

**Trade-off:** Gitleaks may find different tokens than Ruby patterns due to pattern differences. This is acceptable because the goal is comprehensive detection, not deterministic output.

### Token Handling Security

**In-Memory:**
- Raw tokens exist in Ruby heap during scan/revoke operations
- Tokens are memoized in DetectedToken model for efficiency
- No explicit memory zeroing (Ruby doesn't support this reliably)
- Whitelist audit log stores masked values, not raw tokens

**On-Disk:**
- Scan reports include `raw_value` by default (required for revocation workflow)
- Reports saved to `.cache/ace-git-secrets/` with default umask
- Tempfiles for git-filter-repo use 0600 permissions
- Prefer memory-backed tmpfs (/dev/shm) for replacement files when available

**Mitigations:**
- `masked_value` available for display (shows first/last 4 chars)
- Report files can be explicitly cleaned up by user
- Audit log tracks what was whitelisted without exposing raw values

### Threat Model

**In Scope (Protect Against):**
- Accidental token commits detected before push
- Historical tokens in Git history (via git-filter-repo removal)
- Stale tokens that should be revoked (via provider APIs)
- False negatives through multiple detection methods
- Pre-release token leakage (check-release command)

**Out of Scope (Non-Goals):**
- Protection against malicious actors with repo write access
- Real-time monitoring (designed for point-in-time scans)
- Token generation or rotation
- Protection against memory dump attacks on running process
- DLP (Data Loss Prevention) for non-Git channels

**Assumptions:**
- User has legitimate access to the repository
- Git history is trusted (no malicious object injection)
- Provider APIs are authentic (no MITM concerns with HTTPS)
- Local file system is trusted (temp files are short-lived)

### Defense in Depth Layers

1. **Detection:** Multiple methods (gitleaks + Ruby patterns)
2. **Validation:** Confidence levels filter false positives
3. **Exclusions:** Skip known-safe paths (lock files, build outputs)
4. **Whitelisting:** Token-specific overrides with audit trail
5. **Secure Handling:** Memory-backed temps, restricted permissions
6. **Revocation:** Immediate API calls before history rewrite
7. **Removal:** git-filter-repo purges tokens from all history

## Consequences

### Positive
- Clear security posture for users and auditors
- Documented trade-offs enable informed decisions
- Multiple detection layers reduce false negatives
- Audit logging enables security review

### Negative
- Raw token persistence required for revocation workflow
- No memory protection against local privileged access
- Gitleaks dependency introduces external trust

### Neutral
- Users must understand confidence levels for effective use
- Whitelist requires careful configuration to avoid masking real leaks

## Related ADRs

- ADR-022: Configuration Default and Override Pattern (config cascade)
- ADR-011: ATOM Architecture House Rules (code organization)
