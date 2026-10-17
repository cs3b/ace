# Published installation acceptance
1. `bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001` against a fresh sandbox and the frozen release manifest: normal/full-index evidence resolves and loads each intended version; final runner/verifier verdict completes.
2. A successful installation resolving ace-git-github 0.1.2 through stale consumer constraints fails the exact-manifest acceptance even if basic onboarding works. Direct installation of 0.2.0 does not satisfy this case.
3. If both bundle commands exit 0 but the wrapper ends ERROR, preserve successful goal receipts and report incomplete scenario verification. Do not relabel ERROR as PASS or Lab-ready.

## Manifest input
Write `.ace-local/release/installation-manifest.json` before invoking the scenario, or pass the absolute file with `ACE_RELEASE_MANIFEST=/absolute/path/manifest.json bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001`. Schema example (replace SHAs with actual full commit IDs and include all intended packages):
```json
{"schema_version":1,"source_sha":"<40-char-commit>","packages":[{"name":"ace-test-runner","artifact_version":"0.27.1","source_sha":"<40-char-commit>","supersedes":["0.27.0"]}]}
```
Missing/invalid input stops setup before installation. The copied manifest validates actual resolution/load results; it never overrides consumer dependency constraints.
