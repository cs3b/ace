# Receiving boundary inspection — 2026-10-04

ServiceExecutor has a Unix client that checks socket ownership and peer UID and sends request/input. No generic receiving implementation exists. ServiceRequestService currently claims and settles in caller-local AttemptCoordinator. Coordinator receipt verification requires executor-owned, non-group/other-writable repository-relative evidence whose digest, mtime and attestation match the claim. That verifies file content at read time but does not establish protected journal/sink ancestry against a worker who owns its checkout.

The receiver cannot accept arbitrary requester repository paths or merely re-run request handling under its own UID: the former expands filesystem authority and the latter changes caller identity. Readiness review must explicitly design the trusted project/assignment mapping, peer-attributed coordinator calls and protected receipt/journal mutation API. Keep existing qjl as sole state authority; do not grant broad write permissions or create a separate service ledger.

HITL Lifecycle::Service supplies existing ACE patterns for authenticated peers, bounded frames and vft exclusive listener ownership. Reuse principles/appropriate primitives while respecting separate service semantics; do not reopen completed vft/qjx as though these already delivered service receiving.
