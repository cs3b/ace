# h8x wait register (Captain wake-order compliance) — owner: overseer-ace w6:p1
Updated: 2026-10-12 (each wait: owner, awaited event, lastcheck, nextcheck/escalation)

## CLOSED waits (evidence received)

- W1 PR38 integration — owner: host integrator. Awaited: merged receipt for
  1fbfd1ad. RECEIVED (exit0, tree 446efa60, re-evaluation #6). main contains it.
- W2 PR39 integration — owner: host integrator. Awaited: merged receipt for
  1265313a. RECEIVED (exit0, tree 6a474e66, re-evaluation #11). main tip = it.
- W3 PR40 integration — owner: host integrator. RECEIVED: main = de4aeb2c
  (fast-forward; all four h8x PRs integrated).

## OPEN waits

- W4 HITL activation (acceptance group 3) — owner: host gad.8/gad.b.
  Awaited: activation confirmation + /run/lab/hitl.sock + authorization.yml
  (topology decision msg2056; one-Hermes; per-project groups). Lastcheck:
  host relay — configuration in progress, NOT activated. Nextcheck: on host
  activation confirmation. Escalation: gad.8 lane via coordinator.
- W5 canonical lab-config sub-line id — owner: host (gad.2 ledger). Awaited:
  canonical id to replace the interim citation form. Lastcheck: interim form
  adopted per coordinator. Nextcheck: next coordinator relay.
- W6 F4 records correction — owner: host. Awaited: confirmation that the
  8x9xcv-era "push despite --no-push" record is corrected. Lastcheck:
  flagged (PR37 review F4; spec records it as open host-owned). Nextcheck:
  next coordinator relay.
- W7 drill windows F1/F2/F3 — owner: host (windows) + overseer-ace
  (execution per relayed plans). Awaited: GO + window per drill. Lastcheck:
  plans relayed (seq 3160); F3 withhold did NOT execute on PR38 (result was
  delivered normally) — window still pending. Nextcheck: per coordinator GO.

## Wake capability state

- Projection: DONE via supported interface (ace-handbook sync --provider pi;
  .pi/extensions/ace-wake + 102 skills + work-backlog prompt). Config:
  pi provider enabled in .ace/handbook/config.yml (Captain wake order;
  other harness providers remain disabled).
- Live-session load: RESOLVED — the ace-wake extension is LIVE in this
  session (host/coordinator-side load during the reload window): real wakes
  delivered and acted on (watch:h8x-host-results fired the receipt
  reconciliation; loop:h8x-duty ticks drive queue sweeps). No shell sleep
  polling; no cron/daemon.
- Wake proof: ACHIEVED — loop:h8x-duty + watch:h8x-host-results wakes
  received, duty executed per wake, subscription inventory: watch:
  h8x-host-results + loop:h8x-duty (active, host/coordinator-registered).
- W8 publication + integration receipts — owner: host integrator (relay: coordinator).
  RECEIVED: PR38 (1fbfd1ad, in main ancestry), PR39 (1265313a = main tip),
  PR40 (de4aeb2c = main tip — verified identical, INTEGRATED). Awaited:
  PR41 (a922ef91 — ff-eligible NOW: its base de4aeb2c = main tip).
  Lastcheck: 2026-10-12 (watch tick) — RubyGems API verified: 0.14.0/0.3.0/0.5.2 NOT yet published; manifest READY in host lane. Nextcheck: next duty tick /
  coordinator relay. Escalation: coordinator if no PR41 receipt after two
  consecutive ticks.
- W9 LAB-origin OTP route — CORRECTED per host verification (2026-10-12):
  the shared Hermes/broker IS ACTIVE host-side (do NOT start a competing
  poller — prior '0 hermes processes' observation was the wrong runtime);
  installed ace-hitl 0.13.1/ace-hitl-hermes 0.2.2 do NOT prove PR40-source
  routing is active. Publisher credential admission READY: HTTP200, push →
  otp-required/provider_rejected_before_acceptance, published[] empty
  (prior 401 resolved). PR41 a922ef914 MERGED (no sealed-source exception
  needed). ACTUAL GATES for the LAB-origin OTP request (no new OTP until
  all demonstrated): (G-a) SATISFIED: real ACTIVE requester-owned attempt **8xbhrc** (state
  running, scope 010, actor mo, assignment 8xahhp, project ace — started
  2026-10-12T11:50:24Z via ace-assign attempt start);
  (G-b) VERIFIED native return route (host confirms the shared
  Hermes/broker round-trip + channel registry coverage);
  (G-c) RESOLVED BY CAPTAIN PRIORITY: publication executes via the root-attached
  INTERACTIVE PANE (w6:pH, lab-admin executor, NoNewPrivileges preserved,
  temp sudoers removed) — publisher LIVE at the RubyGems OTP prompt
  (no-echo; OTP entry is the host operator's, not mine). Nonsecret durable
  receipt /opt/h8x-release-receipts/receipt.json (lab-control-readable):
  source a922ef914, six-artifact scope. STATE: stopped 2026-10-12 — run
  stopped at the OTP prompt awaiting entry; REGISTRY GROUND TRUTH: nothing
  published (all six latests unchanged — no partial push effects; uncertain
  effect preserved, no blind retry by the queue owner). the exact ADMITTED publisher/scoped-service
  REQUEST interface + EXECUTION GRANT for the root-sealed publisher
  continuation at /opt/lab-release-h8x-a922ef914 (root:lab-admin).
  Constraint: ordinary callbacks run requester UID mo; --harness does NOT
  grant lab-admin execution — so the continuation requires a host-side
  scoped-service execution (gad.b protected route,
  ProtectedPublicationPublisher.push! with GEM_HOST_OTP_CODE + artifact
  binding) or an equivalent admitted interface grant. (G-b) PENDING: native
  return route must be VERIFIED by a demonstrated round-trip before the OTP
  ask. My lane: (G-a) done; request origination via installed ace-hitl CLI
  once (G-b)+(G-c) confirmed.
