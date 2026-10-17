# Coordinated installation manifest provenance

Frozen candidate: `5a0c9e05b00fe429dc59f36445ec43507fbefae4`.
Manifest: `.ace-local/release/coordinated-installation-manifest.json`.
SHA256: `851babb5c3bd0cb76959db015960ed5d4b48e216f500ec6e75f5fd230287189f`.
Status at construction: final candidate tests and independent release review are
pending root confirmation. No archive was built, installed or published here.

The manifest has 49 records, matching the root Gemfile package set: 16 exact
release versions from the coordinated plan and 33 unchanged historical records.
Top-level source SHA and all 16 selected package SHAs bind the frozen candidate.
The source SHA identifies intended build source; artifact verification must still
prove that the actual prepared archives match it before publication.

Metadata was evaluated with `Gem::Specification.load` in a fresh Ruby process
per package from gemspec/version files extracted by `git show` at exact 5a.
`.ace-local/release/coordinated-gemspec-metadata.json` retains those actual
runtime declarations, including non-ACE requirements. Each manifest replacement
includes its ACE runtime declarations, preserves the prior supersession list,
and adds the previous accepted wave version. No declarations were inferred from
the proposed plan or from a registry resolution.

Historical baseline: tracked y1q
`evidence/installation-manifest.json`, digest
`4c9b7be77d08ccaaad90384baec02ebbe4d2746f6c337e42ce431bbd267ff78e`.
All 33 unchanged entries are structurally identical to their accepted historical
records, including versions, source SHAs, supersession and dependency fields.
This does not identify current main as the source of any historical payload.

Two retained historical records explicitly use later release context
`b4bcb42a9aa998c67c5552c7d2bf9f31a464f664`: ace-git-forgejo 0.6.1 and
ace-support-test-helpers 0.14.7. Their original archive build source is documented
as `f7416cbfc8f51daf26f3fa312ff03cfd12a8ec2d` in the wave preparation and accepted
y1q notes. Their package trees have no difference between those commits. This
manifest preserves the reviewed historical records; it does not silently relabel
release context as original build source or claim a new rebuild. Original archive
digests and verification are retained in the wave evidence. Any later provenance
normalization requires explicit review and a new frozen manifest.

Executed local metadata validation:

- Exact 5a `ReleaseManifest.load_validated` passed, and public
  `validate_and_copy` passed all scenario-required names/supersession entries;
  its temporary validated copy matched the manifest bytes and was removed.
- 49 unique records, 16 selected candidate records, 33 unchanged historical
  records; all frozen ACE dependency constraints admit their selected versions.
- Required consumer-only declarations are Bundle 0.44.2 → GitHub provider
  `["~> 0.2"]`, Review 0.59.0 → `["~> 0.3"]`, Task 0.39.1 → `["~> 0.4"]`, with
  provider 0.4.0. Historical Bundle/Task fields were preserved; Review was extracted
  from exact final source. Their six installed edge proofs remain pending.

The stale default `.ace-local/release/installation-manifest.json` is unchanged.
Use this new manifest's absolute path as `ACE_RELEASE_MANIFEST` for the later
postpublication TS-MONO-001 run and as the same run's finalizer source input, as
documented in `installation-manifest-preparation.md`. Final source verification,
review, archive/source integrity, publication receipts, isolated installation,
completed pipeline and finalizer acceptance are separate required evidence.

## Root preparation completion

The pending local gates in the historical construction note above are now satisfied for source `5a0c9e05b00fe429dc59f36445ec43507fbefae4`: exact-source default suite 51 entries / 11280 passed / 24 skipped / 34658 assertions, zero failures/errors; independent release metadata and artifact/manifest review APPROVE; 16 freshly built archives / 1110 payload files verified. Source was pushed to origin and fg before preparation. Publication, the new installed graph run and all native/Lab acceptance remain unperformed.
