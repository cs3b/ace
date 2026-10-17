# Existing publisher join findings

Research checkpoint, 2026-10-16. This records open delivery work, not completed
publication acceptance.

- `.ace-bin/ace-rubygems-publish:545` already exposes `--scoped-publication`: one
  retained artifact, exact SHA-256, gem name and version. It validates metadata
  and held-file identity before and after push; it does not build artifacts or
  write the batch queue. Retained accepted artifacts can reuse this path.
- The ordinary batch prepare path writes its manifest under the source tree
  (`save_manifest!`, line321) and builds in package directories (line385). A
  read-only accepted project-command snapshot cannot use that path unchanged.
  Build retained artifacts in the accepted build phase; do not invent another
  publisher when the existing scoped boundary meets the release contract.
- `ace-lab/.../protected_publication_publisher.rb:60` invokes that maintained
  boundary with literal argv and transient OTP environment; registry verification
  checks the exact archive SHA. Its admission is provided by its existing caller.
- `OrdinaryAuthorityComposition#hitl_services` currently constructs only
  `AssignmentBinding`. The existing `ServicePublicationBinding` requires a
  same-process authority exposing `with_publication_hitl!` and exact original
  executor identity. This is an unimplemented ordinary publication authority/OTP
  join. A successful `ace-lab run` or operator question is not that authority.
- No synthetic assignment/attempt IDs or ambient `LAB_ATTEMPT_ID` may bridge a
  project-command execution to managed publication. Use real parent provenance
  or an explicit reviewed command-execution binding on the canonical journal.

Searches executed with the research workflow: file discovery for publish and
RubyGems scripts, `bin/ace-search` for OTP/artifact/output references, followed by
reads of the publisher, ordinary composition and service publication binding.
The first shell discovery glob matched no files; corrected to file discovery.

Remaining proof: partial publication, uncertain provider result, rejected OTP,
exact release manifest, every installed consumer and stale-bundle refusal,
followed by both projects' installed delivery acceptance.
