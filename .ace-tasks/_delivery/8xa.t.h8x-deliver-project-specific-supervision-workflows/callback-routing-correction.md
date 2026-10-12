# h8x supervision record — callback routing correction (host, 2026-10-12)

- EXECUTOR/REVIEWER callbacks for h8x route to the PROJECT OVERSEER
  (overseer-ace, w6:p1) as queue owner; the lab coordinator (overseer,
  w1:pS) is escalation + host-relay lane only.
- Friction recorded: EXECUTOR-H8X-A-DONE / EXECUTOR-H8X-B-DONE were
  addressed to the lab overseer by the earlier callback template; results
  were valid and adopted (heads verified on forge by the coordinator).
- All future h8x dispatch briefs use: `herdr --session lab agent prompt
  overseer-ace "<AGENT>-DONE: ..."` — with coordinator JSON verification by
  the queue owner.
