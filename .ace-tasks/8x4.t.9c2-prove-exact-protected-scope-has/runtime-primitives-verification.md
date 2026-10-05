# Runtime primitives source checkpoint

Initial source 0a53295ef, integrated locally as 3faf466caf, passed combined suite session60347: exit0,166.73s,51 entries,11219 passed24skipped34314assertions, explicit timeout300. This did not detect the service-only MainPID requirement incorrectly applied to slices. Author found the real interface discrepancy from pinned systemd v257 source; bounded fix23bf5ed50 repairs requested/required properties and adds realistic fixture checks. Initial independent approval is superseded by round2; no installed/native proof is claimed. Slice itself is a common cgroup property, not service-only; MainPID was the defect.

Corrected independent gates: focused14/90,command boundary4/29,runtimeall189/575, APPROVE23bf5ed50. Root combined corrected-source suite remains running; final receipt will be appended. No configured timeout change, source remains only observation/manager primitives, whole9c2 inprogress.

## Corrected combined-source gate

At main source 27887208ba7d24cb1d7e935e54013ee8d9f8e318, bin/ace-test-suite --timeout 300 completed exit0 in192.22s:51 entries11219passed24skipped34322assertions. Root independently read all51 new immutable completion/summary/detail identities, checked unique entry/execution/report paths and reconciled aggregate counts; retained corrected-suite-manifest.json includes completion payloads, summaries and detail hashes. Assign took189.54s; this is not evidence that configured120s passed. Runtime fast187/559 receipt2e32c68f-3cf9-49c2-beb4-8cdb92c2d5fa passed. No native/installed claim; whole9c2 remainsinprogress.
