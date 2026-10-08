# SC4 wrong SHA, uncertain remote merge and red CI

Source base: main `8c66a0484`. This checkpoint adds three scenarios to the existing actual protected merge boundary fixture; no production owner or authorization policy changes.

## Responsibility and existing evidence

Lower ServiceMerge tests already covered wrong actual PR head/provenance and lost mutation reply. Existing full boundary tests cover stale caller selectors, missing accepted review, missing service/authorization and lost claim/completion replies. A lost actual REMOTE mutation response is distinct from a lost canonical completion response. This checkpoint supplies those missing end-to-end technical cases without repeating their other matrix rows.

| Case | Maintained proof |
| --- | --- |
| Wrong actual provider SHA | Accepted original candidate/review remains exact. Actual normalized provider PR read returns another head; fixed ServiceMerge/CLI reports ProviderExpectedHeadConflictError before mutation. Final receiver is joined, zero provider mutation, no canonical completion/import/delivery; original worker status remains uncertain and success consumption refuses without writes/retry. |
| Lost actual merge reply | Controlled remote accepts the one exact-head/method mutation then returns failure. Actual provider/lifecycle classifies ProviderUnknownOutcomeError; fixed CLI subprocess boundary returns failure without receipt. Final receiver joined, canonical dispatch remains uncertain, no complete_service/import/delivery. Fresh original-worker status and refused success consumption neither write nor resend. |
| Red CI only | Actual GitHub provider parses failed check evidence for exact repository/head, including complete check/status inventories. Existing accepted tests/review and scoped grant permit the actual neutral merge, canonical import and original worker delivery consumption. Red CI alone does not veto; no mandatory-green policy is introduced. |

The shared process seam now models fixed CLI failure as a nonzero child result only for these explicit fault cases. Unrelated canonical Git calls still use real BoundedProcess; no journal is mocked. ServiceMergeBoundaryTest now invokes the maintained original workspace provisioning fixture required by the current release getter. It affects only this concrete test class, avoiding duplicate subclass provisioning.

Actual temporary Git, Client/Server, receiver, fixed ServiceMerge command, typed provider normalization, canonical journal and worker consumer remain real. Kernel/native/installed identity/resource boundaries and remote subprocess transport are controlled. This proves source composition, not remote service, installed runtime or whole qkb acceptance. No protected PR create/update/ready policy, publication capability or retry grant is added.

## Executed observations

Initial exact3 selection `ad8b6103-f2b6-464c-be1b-196434f90ab4`:3/12 errors before service/provider because this fixture lacked original lifecycle workspace resources. After maintained provisioning, `3d37d528-4d8a-4ce0-87e0-e7654e66bec2`:3/87,2 failures. Red-CI success passed; fault assertions incorrectly required a particular error word and absence of a nullable completion field. Corrected assertions check exact typed underlying error, null completion and absence only of service imports (valid review imports stay allowed).

Final exact two fault cases: PASS2/57,48.26s, `67f57eae-e497-4d24-96be-0d828581abbd`. Final exact red-CI scenario: PASS1/47,34.91s, `f6b523fe-06ff-4030-9324-7200ae548f7a`. Both handles are terminal. Every selected run's raw --name covers only the named added methods. Outer180/120 budgets bound these composed scenarios; no product deadline changes.

Independent source review remains pending. SC1/6 packaging and publication blocker proofs are already separately delivered. Final affected-package/default verification and the Captain protected PR-order decision remain separate; no task status or completion is changed here.
