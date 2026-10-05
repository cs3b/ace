# Paired native reference repair

The leaf Ref constructor now validates the whole typed Herdr/native tmux pair. It preserves exact `$N`/`%N`, rejects mixed/cross-field IDs, noncanonical decimals, invalid types and unsupported encodings, and freezes the normalized components. Direct/environment callers normalize outer whitespace; canonical wire/persisted callers refuse it. Diagnostic labels cannot select grammar. Component-only validate! is removed; Herdr CLI/Inbox/Deliverer consume the constructor, with persisted pair validation before claim/observation. ManagedEnvelope and its published JSON Schema both enforce the same canonical pair. Runtime, Assign, authority and service execution ownership are unchanged.

Independent root readiness approved add5a857a, retained/promoted in a5ffe122f. The explicit GPT-6.1 Sol plan attempt31552 reached its120s deadline; no generated plan is claimed. The approved contract and test-plan.md supplied the bounded implementation checklist. This repeats the previously retained task-plan timeout and is tooling evidence, not successful planning or a product test failure.

## Focused executed receipts

| Stage | Receipt | Result |
| --- | --- | --- |
| Original Ref baseline | hitl-contract8x4722 | 9/31 pass |
| Maintained Ref/envelope fail-before | hitl-contract8x473o | 21/73, four failures/one error |
| Encoding fail-before on initial repair | hitl-contract8x477r | 12/81, one failure: unclassified UTF-16 compatibility error |
| Final leaf Ref/envelope | hitl-contract8x478b | 21/128 pass |
| Herdr CLI/Inbox/Deliverer focused | herdr8x478c | 79/404 pass |
| Lab authoritative projection/foreign requester | hitl8x479s | 6/31 pass |
| Published old schema fail-before | 6yk-schema-before/8x47en | 1/4, one failure |
| Repaired published schema/runtime matrix | 6yk-schema-after/8x47eo | 1/24 pass |

The standard schema proof uses Python jsonschema4.25.1 Draft202012Validator in isolated `.ace-local/task/8x4.t.6yk/schema-validator`, invoked by bin/ace-test's maintained opt-in edge test. It checks the complete packaged schema and runtime codec over20 positive/negative pairs, including canonical whitespace and mixed/length/numeric inputs. The runtime gem adds no dependency or production override. Default skip is distinct from the explicit executed proof. Original-schema proof temporarily substituted only the owned schema artifact from exact19e, restored the repaired bytes, then reran; its authoritative before/after reports use separate report roots. An initial same-second default report collision8x47e7 was superseded by these retained unique paths, not used as evidence.

Two new consumer fixture checks initially used the wrong existing save argument order (herdr8x4765 errors2); correction used the actual DeliveryRecordStore contract. The Lab projection check initially asserted a nonexistent top-level reverse field (hitl8x478f failure1); correction inspects the actual envelope and persisted record. These are corrected test-author errors, not successful gates or invented production failures.

Full contract/Herdr/HITL/Lab gates and independent source review remain pending the parent's heavy-slot coordination. Assign source is unchanged and its integrated894/3978 full gate was just executed separately; no automatic rerun is claimed or needed for this leaf delta. qjz installed failures8x45o5 and8x46wb remain unsuccessful. Only accepted integration permits its fresh installed rebuild/run; syntax acceptance neither proves native authority nor adds tmux execution to Herdr.
