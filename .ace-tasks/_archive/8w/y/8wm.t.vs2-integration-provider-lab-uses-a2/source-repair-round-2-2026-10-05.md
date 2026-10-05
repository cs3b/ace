# Second source review repair — 2026-10-05

The independent review of 13e527247 rejected four additional verified defects:
unbounded pending IPC history, implicit captain username exclusion, impossible
calendar dates, and a numeric value accepted as a digest. Prior four fixes remain.

The lifecycle owner now provides byte-bounded keyset pages and the authenticated
client traverses them. All consumed native recovery records remain available;
no second journal, expiry or deletion stands in for signed consumption proof.
Every page checks transport/project authority. A single oversized record yields
a classified failure; the list is not silently truncated. Live scans explicitly
require a later poll for insertions before a cursor.

Hermes submits only after authoritative lifecycle lookup and exact body/project
validation. Username captain is valid; a folder instruction without a lifecycle
request stays with its target. The shared codec requires a JSON String digest
and round-trippable real UTC calendar components.

Executed post-fix receipts in ace-wave5-vs2-final-repair:
- Pending real socket: 8x41jx, 1 test / 10 assertions, green. 120 consumed native
  claims and one fresh request survive multiple frames, exact read, no duplicate
  IDs, project filtering and invalid cursor rejection.
- Hermes publication: 8x41jy, 7 / 35, green, including unmanaged instruction.
- HITL all: 8x41l8, 196 / 1105, no failures/errors, one existing multi-UID skip.
- Hermes all: 8x41kr, 116 / 659, no failures/errors.
- Contract all: 8x41l3, 21 / 897, no failures/errors, one explicit installed-graph skip.

Independent rereview is required before integration. Installed Telegram, protected
native users/signers and final Lab acceptance remain open. No task completion,
release bump or publication is claimed by these source receipts.
