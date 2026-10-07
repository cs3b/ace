---
id: 8wr.t.qk0.0
status: draft
priority: high
created_at: "2026-10-07 05:30:19"
estimate: medium
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/protected-inventory-contract.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/coordinator-source-contract.md, ace-assign/lib/ace/assign/authority/deployment.rb, ace-assign/lib/ace/assign/authority/launch_lifecycle.rb, ace-assign/lib/ace/assign/authority/server.rb, ace-assign/lib/ace/assign/authority/client.rb, ace-assign/lib/ace/assign/molecules/evidence_journal.rb, ace-overseer/lib/ace/overseer/organisms/status_collector.rb, ace-lab/lib/ace/lab/atoms/public_projection.rb]
  commands: []
needs_review: true
parent: 8wr.t.qk0
---

# Discover canonical assignments after coordinator restart

## Behavioral Specification

### User Experience

After restarting with no remembered assignment IDs, the overseer shows accepted project assignments, original attempts, canonical occupancy and exact terminal/release evidence. Unavailable liveness or incomplete access stays visible instead of becoming an empty queue.

### Expected Behavior

- Protected agent IDs equal literal installed launch mapping IDs. Public topology supplies project visibility/labels; protected Deployment supplies the fixed pool and current mapping association. No alias table, mutable counter or caller-invented mapping.
- Expose the bounded read-only `assignment_inventory` contract in `../protected-inventory-contract.md`, and consume it through actual `ace-overseer status`. Complete pages share one authenticated canonical first-parent revision and current authorization; historical definitions/attempts cannot accidentally use current bytes.
- Include metadata-only original binding digest, exact pinned attempt authority generation, canonical state and actual authenticated terminal/release selectors from existing owners. A registration-only row has null generation; accepted attempt generation is positive Integer. No native I/O, process pinning, mutation permission, private directory fallback or raw process data. The actual parent can join the ready child's exact generation/binding at the retained ready commit after live advance without invoking old-birth status.
- Preserve mapping-role precedence and original private Driver birth. A restarted launcher can read this stable-credential projection, but overlapping supervisor UID does not authorize detailed old-incarnation status. Detailed liveness without an actually admitted distinct supervisor remains unknown.
- Full project capacity comes from fixed Deployment. Partial topology/authorized mapping discovery is labelled partial. Failure never looks like verified empty inventory; a successfully empty complete page set does.

### Interface Contract

`ace-overseer status [--project PROJECT] --format json` consumes protected `assignment_inventory`, null mutation ID, exact `{mapping_id,journal_commit,after,limit}` and closed response/rows from the sibling contract. Current detailed observations retain their own revision; no atomic live-project snapshot is claimed. Revoked/forbidden/malformed/unavailable/oversized history gives a classified error or unknown observation, never invented completion.

### Success Criteria and Verification Plan

- [ ] SC1: Real canonical Git + maintained Server/Client + actual overseer status discover multiple mappings, no-attempt registration, multiple attempts and restart without local cache. Exact old original binding/canonical released-terminal metadata is visible; old private-birth read still refuses. Actual parent→child ready metadata joins generation/original binding at its retained commit despite live advance; wrong generation/digest/ref/tuple refuses.
- [ ] SC2: Concurrent advance preserves selected pages; later details keep their revision. Same-project role precedence, revoked continuation, cross-mapping cursor, float limit, fabricated/abandoned commit, missing history, corrupt terminal/release and replaced definition refuse correctly.
- [ ] SC3: Exact frame bound, shortened pages, oversized single row and verified empty vs unavailable are exercised. Execute permitted deterministic Assign/Overseer source selections plus required suite with independent exact candidate review; no installed/native probe claim.

### Scope and Ownership

Producer ace-assign; consumer ace-overseer; existing ace-lab visibility/protected Deployment boundaries. This is an independently deliverable restart/status outcome within qk0, not whole coordinator/cleanup delivery. Advisory size medium. No unresolved product decision; exact contract review precedes promotion/implementation.

### Usage and Review Evidence

`ux/usage.md`; sibling inventory contract's earlier flat-row approval remains scoped. Root independently approved the proposed lifecycle-field delta on 2026-10-07; the exact child/consumer composition still needs readiness verdict. Draft and needs_review stay unchanged until that verdict.
