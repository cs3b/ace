# Reverse-reference pair contract

## Developer API and wire schema

Construct `Ace::Hitl::Providers::Ref.new(session: "$0", pane: "%0")`. Its `to_h` remains `{schema: "ace.hitl.ref/v1", session: "$0", pane: "%0"}`. This validates syntax only; existing authoritative native binding still controls delivery.

Construct the existing Herdr pair `session: "W692.lab_1", pane: "agent:3-x_9.y"`, or obtain it from existing HERDR_SESSION/HERDR_PANE variables. Valid pairs remain accepted; outer whitespace is normalized by the direct/environment interface.

Try `$0` with `pane1`, `%0` in the session field, `$0` in the pane field, padded IDs, or non-String inputs. Ref refuses with InvalidRefError. The ManagedEnvelope boundary refuses malformed/noncanonical persisted pairs with InvalidEnvelope; it does not select a replacement target. A valid pair that disagrees with authoritative ownership still refuses through the existing owner checks.

Consumers validate the whole typed pair through `Ref.new`; component-only `Ref.validate!` is removed. Use `canonical: true` for wire/persisted addresses, with optional diagnostic labels `session_source`/`pane_source` that never select field semantics. Invalid/non-ASCII-compatible Ruby encodings refuse with InvalidRefError. Maintained usage is in ace-hitl-contract/README.md and ace-herdr/docs/usage.md.
