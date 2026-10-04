# Listener ownership -- acceptance scenarios

Existing CLI/API; no new flags.

1. Start `ace-hitl serve --socket /run/lab/hitl.sock` under the configured service identity. Run the same command again. The second exits nonzero with the existing already-serving error; an authenticated Lifecycle::Client#ping against the original endpoint still returns pong, and its requests remain consumable.
2. Stop the process that actually owns the socket. Its endpoint disappears; a later valid `ace-hitl serve` can acquire it. Stopping a failed contender cannot remove that endpoint.
3. In an isolated protected fixture, replace the pathname after a service acquired it. Cleanup of the older invocation leaves the replacement intact. A stale non-listening socket is recovered only after ownership/protection checks; an untrusted endpoint is refused.
