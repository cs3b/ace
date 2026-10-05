# Shared protected policy mechanism — independent review

Source slice: `a2c64bf4c5041cb1e1a9d5e30f6f8a6c8cf0e65d`.

Verdict: **APPROVE for this isolated adapter and grants-snapshot change only**.
Root independently read the exact diff, ProtectedServicePolicy, existing
ServiceInput, CallerAuthorizer and ServicePolicy, and the maintained tests.
Executed adapter and GrantResolver tests: `lab/8x44tm`, 20 tests, 69 assertions,
zero failures/errors, command exit 0.

The adapter reuses the existing input schema and canonical digest/target;
rejects mismatched assertions; checks current project visibility, exact policy,
authorization and executor lease; and binds the policy digest. The default
loader validates principals from the same protected document bytes. Tests also
cover revoked scope, changed policy, invalid/secrecy/depth bounds and refusal to
replace canonical proposal authorization with a YAML entry.

The d20cd8 ServicePolicy dependency is a separately reviewed qjz source change;
this slice is not an independent publication of that consumer vocabulary.
Public kernel-delegated admission, immutability through CAS/handler use, native
origin, claim/begin atomicity, receiver invocation and installed cross-user
acceptance are outside this limited verdict and still require final integrated
source review and execution evidence. No complete Endcap delivery is claimed.
