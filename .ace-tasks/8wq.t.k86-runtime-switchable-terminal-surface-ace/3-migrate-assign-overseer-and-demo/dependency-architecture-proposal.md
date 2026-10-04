# Independent architecture review request — k86.3 closure

Status: architecture approved independently by ACE review review-8x3w73 and wave3_otp_services_lane; implementation authored with executable boundary checks. Source baseline `b06d0aee92d58eb03b6603c202993b0152ba7138`. This proposal closes existing standalone-install acceptance, preserving the delivered migration.

Current consumer gemspecs install ace-runtime and ace-tmux, but omit ace-herdr. Adding ace-herdr directly creates assign → herdr → hitl → assign. Herdr uses only provider protocol types: Ref (and TOKEN_PATTERN), InvalidRefError and ProviderUnavailableError, and DeliverResult. It loads the complete HITL package to obtain them. HITL needs ace-assign for AssignmentBinding#with_verified, which holds the verified-attempt exclusion across the whole locked HITL transition; removing that dependency or weakening authority is forbidden.

Extract existing provider protocol definitions into a leaf **ace-hitl-contract** gem. Preserve the existing Ace::Hitl::Providers namespace but move code, with no duplicated definitions, aliases, fallback or obsolete require shims. Move Ref, the provider error hierarchy, AskResult and DeliverResult; expose `require "ace/hitl/contract"`. Keep provider registry, Lab integration, lifecycle service/store and AssignmentBinding in ace-hitl. Contract has no runtime dependency (Ruby standard library only). Move existing Ref tests, add result/protocol tests and explicit isolated load tests.

Dependency graph after the change:

- ace-assign → ace-runtime, ace-tmux, ace-herdr
- ace-herdr → ace-runtime, ace-hitl-contract (full ace-hitl dependency removed)
- ace-hitl → ace-hitl-contract, ace-assign (locked authority unchanged)
- ace-overseer, ace-demo, ace-git-worktree → ace-runtime, ace-tmux, ace-herdr

Update every require site in the monorepo to the new protocol entrypoint. Root Gemfile/lock and suite register the leaf. Build source gems in an isolated local repository, install each consumer from a manifest naming only that consumer, verify both adapters activate without full HITL service activation, traverse graph to prove acyclic, and exercise installed native consumer behavior. Native prepared-shell fix is independent (removes exec replacing the shell) and does not change this architecture.

Review requested: approve or identify actionable P1/P2 issues in protocol ownership, dependency direction, unchanged authority, module layout and installed verification. This is a pre-implementation architecture verdict, not final implementation/native acceptance. Parent is responsible for final exact-head independent acceptance.

Release choreography: coordinator owns version finalization and publication after exact-head acceptance. Publish ace-hitl-contract 0.1.0 first; bump/publish ace-herdr with its contract dependency, then bumped standalone consumers, then ace-hitl. New dependency requirements remain compatible with those release lines; every changed package has an Unreleased entry. No existing version has been published from this worktree.
