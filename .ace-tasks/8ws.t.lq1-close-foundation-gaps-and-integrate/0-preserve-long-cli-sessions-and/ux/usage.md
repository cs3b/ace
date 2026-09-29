# Long-session result contract
1. Through the existing ace-llm CLI provider path, run an authorized fixture whose configured execution timeout exceeds a long silent tool call. The session completes once; the word `timeout` in successful tool output does not trigger fallback.
2. Run a fixture exceeding its actual configured deadline. Expect timeout classification with duration/session context and retained partial output, never a successful answer fabricated from an intermediate shell exit.
3. `bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001`: a disconnected runner produces an explicit incomplete/ERROR result. A completed runner and verifier can produce the genuine scenario verdict. Installation side effects are not automatically replayed through fallback after an unknown result.
