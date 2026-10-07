# Fixed cleanup invocation — draft

An installed maintenance worker submits the exact prune request through its provisioned receiver socket. It receives actual accepted request/commit metadata while the original supervised receiver worker continues the fixed operation. Existing service_status queries remain bounded; a slow operation never turns the acceptance ACK into a success receipt.

If root/receiver connection is lost, query the same request ID. The original root birth may finish its one admitted invocation; a new birth inspects immutable result evidence and never adopts/replays deletion. Actual no-effect/settlement challenge identifies recovery; EOF alone leaves uncertainty.

Wrong peer, input, root entry/profile or phase refuses. No caller executable, path-to-delete, root UID option, ambient sudo or passed descriptor is supported. Exact closed frames and output limits are in ../../protected-prune-source-candidate.md. This is proposed source capability, not an installed command.
