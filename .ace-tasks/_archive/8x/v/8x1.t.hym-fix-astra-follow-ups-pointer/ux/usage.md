# Herdr pane and error scenarios

Proposed repair, using existing public tab commands and runtime operations; no new flags.

- Native tab with no ACE ownership: prepare shell, lose that pane, prepare again, restart the adapter, ensure window at the verified native root. Reuse the replacement; never manufacture root:nil ownership or split on each restart.
- Owned window: replace a prepared pane and retain its root/preset. Request a different root/preset: existing conflict remains, no forced adoption.
- Native tab creation fails materialization: ordinary CLI emits the standard actionable error and nonzero exit, not a stack trace or success. Existing unrelated tabs survive.
