# OTP challenge deadline -- acceptance scenarios

Existing consume surface; no new flags.

1. For an active requester-owned challenge `REQ` authorizing `gem-push`, run `ace-hitl consume REQ --operation gem-push --timeout 10` before both challenge and vault deadlines. Receive the code once over the existing protected consumer surface; a consumed retry exposes no code.
2. Deliver while REQ is valid, then invoke the same command at or after its recorded expires_at. Receive a classified expiry error and fresh-challenge guidance, never a successful secret handoff even if the vault TTL has time left.
3. Start consumption before expiry and arrange delivery near the deadline. If the actual handoff occurs at/after expiry, it fails identically. Duplicate transport delivery cannot renew the window; a non-secret HITL request retains its existing non-expiring policy.
