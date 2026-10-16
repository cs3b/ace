# Effective delivery contract — source verification

2026-10-16, ei9.1/.5/.8. Package defaults are selected because no project preset
of these four names exists. No copied preset or new scheduler was introduced.
The project guide now resolves through its own registered source at priority 5.
`guide://project-delivery` is the exact project URI; the absent
`guide://delivery-supervision` is not an alias. `wfi://review/pr` resolves from the
current source ace-review, ahead of the stale user registration. Navigation uses
`ace-nav resolve URI --why`; `ace-nav explain` is not an available command.

| Result | Effective path | Before SHA-256 | After SHA-256 |
|---|---|---|---|
| UPDATED | `ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml` | `3715c719d712e681ce962e9d7398ebf1b601019516ca596a93239d035b25aa0c` | `1f6db9ef786cd5fb095595f8976028244f8336f551e77fe1d7a94107edf4fa4a` |
| UPDATED | `ace-assign/.ace-defaults/assign/presets/integrate-batch.yml` | `b557c9ce18049cdebb286a3839d2dab9f66c5ddf2c5c3e013c8925d62803cb4a` | `3b0697b4137d6478b6b58d378a305040230317a1bcbaf4520a0cbce10b339259` |
| UPDATED | `ace-assign/.ace-defaults/assign/presets/deliver-release.yml` | `1768a45cfaca1da0f18c2f6d93f160debe0ed3ac144bdd8ff7c69b4eff0a3662` | `4ba3008a743757756ec2fca929d5114ccd31a10124aad4e21d38171a87d00e2c` |
| KEPT | `ace-assign/.ace-defaults/assign/presets/close-delivery.yml` | `2cfcd3df1c5a8416ce754009ff73d04b209f0cc74c22e0b30f87ea89bf571bcd` | `2cfcd3df1c5a8416ce754009ff73d04b209f0cc74c22e0b30f87ea89bf571bcd` |
| UPDATED | `ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md` | `6a8cf3b6bd07752daa6afc42cab671e0f6ee2acbe90ac10503d2295f30ca7367` | `3e7350a42a5f5e53acb27948d5876adf8fac9a0c14ff7e1c7b7a3c5cb99d6001` |
| UPDATED | `.ace-handbook/guides/project-delivery.g.md` | `9b1700de578ae292709f327959430cb2b9f0c36bade6a7e6a9fc730dbc13612b` | `1974256688ca4fe4abf80ab78759af61d87cd32ee2c5285698868113637ce3c5` |
| CREATED | `.ace/nav/protocols/guide-sources/project-local.yml` | `absent` | `181faa9921cec6b5654539d8c71402e3cc53da9c2288785c2191275cb2231b0e` |

Guide review (`as-handbook-review-guides`): scoped to project-delivery.g.md.
Naming, conceptual policy focus, section structure and links to maintained
workflow owners are appropriate; no language-specific implementation was added.
Corrected stale GitHub-only review claim, blanket moved-head invalidation,
non-deployment assumption and missing advisory-CI policy. Registration fixes the
previously unresolved project guide. Package handbook projection test passed:
82 tests / 603 assertions, report
`.ace-local/test/reports/handbook/96c52850-ee25-4086-9353-f4aa804cf096/`.

Presets now require an initial independent verdict, recorded assessment of moved
head, executed proof for identical rebases, and independent delta review for
material or uncertain changes. The publisher is an explicitly bound executable
owner with partial/uncertain registry reconciliation. The objective queue stores
only goals, actions, blockers and references; Assign owns execution state.

BLOCKED for installed acceptance: the actual ordinary authority owner, executable
publisher selection, coordinator bundle adoption and two-project receipt remain
unfinished. These source outcomes do not grant runtime authority or prove deployment.
A second inventory must be byte-identical unless further source edits are intended.
