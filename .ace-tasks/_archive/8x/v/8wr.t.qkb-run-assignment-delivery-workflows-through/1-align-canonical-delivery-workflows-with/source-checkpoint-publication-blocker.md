# SC4 publication prerequisite blocker — source checkpoint

Scope: the existing delivery workflow now explicitly routes an unavailable publication prerequisite through the original assignment failure owner. This is a negative source composition, not positive protected publication or OTP completion. vs3 remains downstream of qkb; no reverse completion dependency, new publication API, service grant, or journal is introduced. Protected PR create/update/ready policy remains unresolved.

## Test responsibility

- `ace-assign/test/feat/prepared_publication_blocker_test.rb` captures the exact shipped `Unavailable publication prerequisite` section using BundleLoader and real TaskManager/PreparedWorkBuilder, registers/releases it through the maintained canonical owners, and runs PreparedWorker with controlled provider/kernel/workspace observations. Both scenarios invoke registered `ace-assign fail` and `status` with the original assignment/scope/attempt/mapping. Failed is a terminal queue state, not successful work: the original worker rejects completion.
- Missing configured publisher: actual ProtectedServicePolicy rejects the exact publish request; receiver transport remains uncertain. After actual listener stop/join, canonical ref is unchanged, request is absent and handler has no effects. These final facts and observed maintained-policy denial supply the proof; uncertainty alone does not.
- Missing OTP: the actual ordinary publisher script runs against the existing isolated fake RubyGems executable/credentials fixture with no OTP. Its actual prerequisite refusal precedes push; no push log/command exists. The same protected assignment failure path retains the value-free blocker. This ordinary script result does not supply a protected publisher receipt, executor capability or positive scoped OTP.
- `ace-handbook/test/feat/rubygems_publish_script_test.rb` retains all existing 12 scenarios after extracting only its shared process fixture to a module. No concrete test subclass duplicates inherited cases.

Only these inspected files are executed. Actual temporary Git/files and ordinary publisher subprocesses remain real; excluded native/process-identity/installed/kernel/resource boundaries are injected. No network, host configuration, publication, or global install occurs. Outer runner120 seconds is an execution budget for the composed test, not a product deadline change.

## Preserved unsuccessful observations

An initial wrong-cwd file selection found no test file and ran no tests. `13ea40db-5769-4fea-b731-533129635e14` failed2/21 before the provider; `d88780a5-8757-48e6-ba2a-1ad2d73692e2` was an excluded unchanged repeat after a wrong-cwd edit failed. Diagnostic `83989928-b77d-480b-ac20-e0168d562877` failed2/19 and identified literal JSON ending `}}` in the unrelated merge portion of the whole workflow; PreparedInput currently treats it as unresolved syntax. No renderer was weakened. This selected publication leaf captures only its exact maintained publication section. The broader literal-JSON issue is reported separately.

`ba044896-2695-4685-bea0-df4b62ad827c` reached both real blocker/fail paths but failed2/45 because the assertion incorrectly equated terminal queue failure with an incomplete queue. Corrected assertions require failed and not all-done, while PreparedWorker independently refuses success.

## Executed evidence and review

Original publisher regression: PASS12/100, 16.51s, receipt `44682aa7-6b00-4866-8a58-33dde932d349`.

Actual composition: PASS2/65, 40.58s, receipt `036dcf15-cff5-4ca6-96c9-5cec88df6ef2`. Both live handles are terminal.

Independent verdict remains pending; this document does not approve itself or close qkb.
