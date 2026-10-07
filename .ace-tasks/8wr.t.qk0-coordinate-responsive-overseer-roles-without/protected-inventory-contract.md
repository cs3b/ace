# Protected assignment inventory — draft contract

This defines qk0's existing status/restart requirement. It is not an additional prerequisite for xz9.2 and does not promote qk0. Producer owner: ace-assign; consumer owner: ace-overseer. Independent readiness review is required before implementation.

## Observable result

After an overseer restart with no remembered assignment IDs or local assignment directories, `ace-overseer status --project PROJECT --format json` discovers registered assignments and their attempts through the selected Assign authority. It distinguishes a verified empty inventory from an unavailable authority. It never queries labd, scans another user's directories, or treats absence from a local cache as completion.

## Read-only owner interface

Add `assignment_inventory` to the existing protected authority protocol, with `mutation_id: null` and closed parameters `{mapping_id, journal_commit, after, limit}`. The first call uses null revision and cursor. `limit` is an integer from 1 to 50, defaulted by the consumer to 25; neither floats nor implicit coercion are accepted. `after` is null or the previously returned closed cursor `{assignment_id, attempt_id}`, where attempt_id is null only for a registration without attempts. An explicit commit is an exact supported Git object ID, authenticated as a retained canonical first-parent revision of the selected journal; arbitrary object IDs and abandoned CAS candidates are refused.

The current installed mapping selects project, authority and journal. Current mapped launcher or supervisor credentials authorize this projection; worker, service, context-owner and unrelated project identities do not. Authorization is checked on every page, including continuation at an old revision. Possession of a cursor, old grant or known assignment ID conveys no authority. A non-null cursor requires a non-null revision and must identify a row actually visible in that mapping at that revision; fabricated or cross-mapping cursors are refused.

Each response has closed fields `{project_id, mapping_id, journal_commit, items, next_after}`. Items are sorted by the bytewise tuple (assignment ID, attempt ID), with null attempt ID before non-null, and selected only from accepted assignment registrations for the requested mapping at that revision. Internal evidence directories such as definitions or request indexes are not assignments. Each item contains `{assignment_id, task_id, definition_digest, definition_generation, attempt_id, scope, reservation_generation}`. One row represents one accepted attempt, so large assignment histories remain pageable. A registered assignment without attempts appears once with null attempt_id, scope and reservation_generation. Attempt fields come from the accepted original reservation; scope is the authoritative delegated step/subtree reference, not a guessed current workflow step. Historical attempts remain discoverable for reconciliation. No launch tickets, prompts, private paths, credentials or raw process identities are exposed.

All definitions, task associations, registrations and attempt references in a page come from exactly `journal_commit`. The consumer follows `next_after` using that same revision. Advancing the live journal does not silently alter later pages; a missing/unretained revision is an explicit unavailable result and the consumer starts a fresh inventory, discarding the incomplete old projection. It does not combine pages from different revisions. `next_after` is null only when enumeration at that revision is complete. An empty final page is valid; an empty page that advances without returning a record is not.

The existing 16,384-byte protocol frame bound applies. The producer may return fewer than `limit` whole rows to fit the frame. It must refuse with an explicit bounded-result error if one row cannot fit; it must not omit attempts, truncate strings or report a complete partial result. The consumer displays this limitation as unavailable, not an empty queue. No new persistent inventory, pagination session, cache authority or background broker is introduced.

## Joining status without fabricating a snapshot

The inventory is discovery evidence at a revision, not liveness or completion evidence. For each returned attempt, the consumer invokes the existing attempt-status owner and retains that result's own revision/generation. If detailed status is newer, the output labels it as a later observation instead of claiming a single atomic project snapshot. If status cannot be obtained, the discovered attempt stays visible with unknown status. Cleanup, retry, review acceptance and scope release continue to require their existing canonical owners.

Task ID comes from the accepted assignment definition. An active step comes only from accepted execution evidence for that attempt/scope. Where that evidence is absent, report unknown; do not substitute a mutable local workflow file. Overseer may discard a completed display snapshot and refresh, but may not use its displayed revision as mutation permission without normal current-generation checks.

## Required source verification

- Actual protected journal, authority router/client and overseer composition: multiple assignments/mappings, a registered assignment with no attempt, multiple attempts, and restart without local assignment state.
- Current role and project refusal, revoked authorization between pages, malformed limits/cursors/revisions, and an abandoned candidate commit.
- Concurrent accepted mutation between pages: all inventory pages retain the original revision; later detailed status explicitly has its own revision. Missing retained history refuses without fallback.
- Definition replacement at a later revision cannot change task/definition data returned for the selected earlier revision. Source review found `LaunchLifecycle#definition(..., commit:)` currently calls `read_events(id)` without forwarding `commit`; implementation must not reuse that helper unchanged for this contract.
- Exact frame bound, shortened page, single oversized row refusal and an assignment spanning multiple pages, internal non-assignment directories, verified empty inventory and unavailable journal are distinct cases.
- Source tests exercise real canonical Git evidence with injected external OS boundaries. Installed deployment and actual users remain solely lab-config:gad.2.

This is a proposed contract, not evidence of delivered enumeration. qk0 remains draft with needs_review true.

Independent scoped readiness review (wave_5h5, Sol 6.1, 2026-10-07): APPROVE the final contract, spec reference and usage amendment, including flat per-attempt rows, tuple cursor membership and fixed-revision/current-authorization checks. This is amendment approval only; qk0 remains draft/needs_review. Task show confirms draft metadata and diff validation passes. No implementation test or installed result is claimed.
