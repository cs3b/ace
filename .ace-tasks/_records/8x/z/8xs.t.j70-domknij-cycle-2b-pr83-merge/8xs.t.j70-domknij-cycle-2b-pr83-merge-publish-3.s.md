---
id: 8xs.t.j70
status: done
priority: medium
created_at: "2026-10-29 12:47:48"
estimate: 
dependencies: []
tags: [cycle2b, release, publish, live-test]
status_note: "LIVE-TEST PASSED (captain ruling). Numbers - ask 8xskjj fired 13:41:43Z, captain reply 'ok' on panel 13:41:59Z = 16s ask->reply; reply frame reply-fbe9a004 correctly keyed/correlated (0.9.6 fix works). CAPTAIN RULING - the transport folder /lab/state/hitl-address/ace IS the delivery address, reply-*.json arrival = the answer; the relay-into-case hop is a middleman being REMOVED (no relay). Consumed myself - 'ok' written into 8xskjj (status answered, --no-resume), frame acked. Wake watches - retarget to transport reply path = NEXT-SLICE CODE CHANGE (see VERDICT note in body); current watches on case files were interim. REMAINING - closure HITL report SENT (8xskwh, delivered panel msg 2464, host GitHub sync pending), panes checked (only own pane alive), task done.
ADDENDUM (second wake executor, 13:58Z): my bridge also consumed a mirrored 8xskjj wake-request, so BOTH sessions executed the closure - duplicate closure report 8xskxf (panel msg 2465) followed 8xskwh; same verdict, no correction sent. Extra numbers: ask->case-file answer latency 13m40s (answered_at 13:55:23Z) - the relay-into-case hop the captain is removing accounts for the gap vs the 16s panel reply. Additional findings: (1) ace-hitl cancel CLI unusable - boundary endpoint /run/lab/hitl.sock missing (in-file cancellation used, non-blocking); (2) canonical-checkout frames 8xsjzs/8xskgh rejected (receiver accepts only the registered .ace-wt/overseer-lab92 root) - both cancelled in-file. Nothing outstanding; next queued task 8xr.t.9o9 awaits orders."
---

# Domknij cycle-2b: PR83 merge, publish 3 gemow, install 0.9.6, live-test ask
# Charter + plan: domknij cycle-2b do końca (PR83 → publish → install → live-test)

## TWOJE ZASADY STOJĄCE (od teraz, zawsze)

1. **Twój plan = twoje taski tutaj** (`.ace-tasks/_overseer/`, git-ignored).
   Po KAŻDEJ turze: zaktualizuj task (co zrobione, co następne, blocker).
   Skończysz krok — zamknij, weź następny. Koniec tury = plan zapisany.
2. **Domykasz sam**: worker → independent review → merge (swe credential) →
   release → publish. Host = tylko księga approvals + infrastruktura.
3. **Potrzebujesz czegoś — pytasz bezpośrednio**: od Kapitana przez `ask`
   (route captain), od innego agenta przez pane-ping (herdr agent prompt).
   Żadnych relayów, żadnego czekania na budzenie przez operatora.
4. **Pane'e zamykasz po akceptacji** (close-on-accept). Max 4 pane na tab.
5. **Sekrety**: OTP/klucze tylko do zmiennych env, nigdy echo/argv/logi.
   Publikacja tylko przez `dotenv -f /home/mo/.ace/.env run -- …`.

## KROKI DO WYKONANIA TERAZ (pełny łańcuch, po kolei)

### 1. Merge PR83 (hotfix release, 3 gemy)
- Approval #237 już zapisany przez host; review APPROVE w PR.
- Token: `/home/mo/.config/lab-overseer/forgejo.token` (write:repository ✓,
  identity: lab-overseer). Pobierz do zmiennej:
  `TOK=$(printf "protocol=https\nhost=forgejo.tail6c0887.ts.net\n\n" | LAB_FORGEJO_TOKEN_FILE=/home/mo/.config/lab-overseer/forgejo.token /usr/local/lib/lab/git-credential-lab get | grep ^password= | cut -d= -f2-)`
- `curl -sf -X POST -H "Authorization: token $TOK" -H "Content-Type: application/json" https://forgejo.tail6c0887.ts.net/api/v1/repos/cs3b/ace/pulls/83/merge -d '{"Do":"rebase"}'`
- Zweryfikuj: main == head PR83.

### 2. Publisher (3 gemy: ace-support-items 0.15.16, ace-hitl 0.24.3, ace-hitl-hermes 0.9.6 — wg kolejki)
- Pane w worktree zmerged main; kolejka staged (pending-queue.yml).
- **OTP przez ask**: `ace-hitl ask "OTP: publikacja 3 gemow (hotfix)" --kind approval --to captain --question "Swiezy 6-cyfrowy RubyGems OTP - wygeneruj w chwili odpowiedzi."`
- **TĘ rundę** (0.9.5 correlation zepsuta; fix jedzie w tym release): bounded
  watch na `/lab/state/hitl-address/ace` — nowy plik `reply-*.json` celujący
  w Twój case, interval 2 s, max 90 s (sanctioned OTP-window exception).
  Kod z pliku → `GEM_HOST_OTP_CODE="$OTP"` → `dotenv … ace-rubygems-publish`.
- Zweryfikuj rubygems latest × 3 (read-only API).
- Raport HITL (wersje+digesty+latencja, NIGDY kod). Zamknij pane publishera.

### 3. Instalacja 0.9.6 + extension
- `gem install "ace-support-items:0.15.16" "ace-hitl:0.24.3" "ace-hitl-hermes:0.9.6" --no-document` do lab92-v2.
- Extension deploy: skopiuj `ace-wake/` z merged main do
  `~/.pi/agent/extensions/ace-wake` (README: deployment = copy). Zrestartuj
  swój proces (ctrl+d + herdr agent start) — załaduje nowy extension.
- `ace-lab verify` → 18/0/0.

### 4. LIVE-TEST pełnego łuku (moment „zaczęło działać")
- Świeży `ask` (testowy): "reply OK when convenient".
- Kapitan odpowie KIEDY ZECHCE. Wake ma dostarczyć odpowiedź DO CIEBIE
  (0.9.6 naprawia correlation; poll-fallback łapie virtiofs).
- Po wake: raport HITL co wakeniósł + latencja. To zamyka akceptację ask-flow.

### 5. Domknięcie
- GitHub sync main = host lane (note w raporcie: "host: sync pending").
- Zamknij wszystkie pane po akceptacji. Task done.
- Kolejny w kolejce (nie zaczynaj bez rozkazu): standing loops (8xr.t.9o9).

## UPDATE (root cause found + lane identities complete)

The 405 was the wrong-account collaborator (lab-overseer-ACE had write, the
actual account LAB-OVERSEER had pull only; AGit pushes only need pull). Fixed:
lab-overseer now has write on cs3b/ace (perms push:true) - merge works.

NEW standing rule (b-fix): the REVIEWER pane posts the FORMAL Forgejo APPROVED
itself - not only a comment - using the merge-lane identity:
- token: /lab/projects/ace/_overseer/lane-review.token (identity lab-merge-ace)
- POST /repos/cs3b/ace/pulls/N/reviews {"event":"APPROVED","commit_id":"<head>","body":"independent verdict: ..."}
Roles stay separated: author lab-overseer (AGit push), formal approver
lab-merge-ace (reviewer pane), merger lab-overseer (you). Host ledger retired.

For PR83 NOW: approval #237 (host, last one) already satisfies the gate -
merge it yourself and continue the task chain.

## OTP PROCEDURE — FINAL, replaces ALL earlier window/bounded-watch nonsense

    loop:
      1. ask: ace-hitl ask "OTP: publikacja gemow" --kind approval --to captain
         (question text: NO urgency, NO windows, NO seconds - just: reply with
         a fresh 6-digit code when convenient)
      2. CODE=$(ace-hitl wait <case> --poll-every 5)     # NO timeout flag -
         waits as long as needed, returns the answer
      3. GEM_HOST_OTP_CODE="$CODE" dotenv -f /home/mo/.ace/.env run -- \
         .ace-bin/ace-rubygems-publish
      4. if publish says OTP rejected/expired: goto 1 (new ask, new wait)

That is the whole procedure. No 90s windows. No bounded watches. No freshness
management. The answer arrives whenever it arrives; if the code died, ask again.

## VERDICT (captain ruling) + NEXT-SLICE NOTE

LIVE-TEST PASSED. Transport folder IS the delivery address. Numbers: ask 13:41:43Z, captain
reply 'ok' 13:41:59Z (16s), reply frame reply-fbe9a004... correlated by key (hermes 0.9.6 fix
confirmed). Asker consumed its own reply: 'ok' -> 8xskjj ## Answer (answered), frame unlinked.

NEXT ACE SLICE (design change, no relay):
1. ace-hitl ask: after publishing the request frame, compute the reply-frame path
   /lab/state/<channel>/reply-<key>.json (key = SHA256 of JSON [project, origin_path, case_id])
   and arm the wake THERE (create of reply-*.json = the answer). Stop watching the case file.
2. Asker consumes its own reply file (read + unlink) and writes ## Answer bookkeeping itself.
3. Retire the relay-into-case middleman expectation from ace-wake README ask-bridge section.
4. Hygiene: 4 stale reply frames from earlier flows still sit in /lab/state/hitl-address/ace
   (8xsdfo, 8xsjhc, 8xsjm3, 8xptnw) - sweep policy needed now that consumption is asker-side.
5. PROJECT_ROOT_PATH pins ProjectRootFinder - asks from a worktree need the override (8xskgh
   lesson) or ask must resolve root from cwd/git toplevel first.
6. STALE-WATCH NOISE: ask-8xskgh/ask-8xsjzs watches survive and keep firing dir-stat noise on
   EVERY write to the worktree/main hitl dirs (WAKE-2 13:41:44 churn, WAKE-4 13:56:06 = 8xskwh
   closure-report writes). The slice needs a disarm/cleanup path for stale case-file watches
   (or dir-stat changes must not fire a file watch).

## VERDICT-END

## REARM (2026-10-29 13:42 UTC) — live-test ask re-fired and DELIVERED

Diagnosis chain (all evidence in /lab/state/hitl-address/ace/):
1. 8xsjzs delivery-449d633e... state=rejected, empty message_ids -> captain never saw it.
2. 33-frame history: 31/31 delivered = origin root /lab/projects/ace/.ace-wt/overseer-lab92/.ace-local/hitl;
   2/2 rejected (8xprx3, 8xsjzs) = main-checkout .ace-local/hitl roots.
3. /etc/lab/ace-lab/install.yml registers project ace at the worktree path; the worktree was
   deleted after the publish -> registered path vanished -> main-root frames rejected.
4. PROJECT_ROOT_PATH=/lab/projects/ace (session env) pins ProjectRootFinder -> asks always
   create cases in the MAIN root regardless of cwd (caused mis-fire 8xskgh, now cancelled).

Fix applied: git worktree add --detach .ace-wt/overseer-lab92 a1cc51fd9; bundle install
(hermes 0.9.6 from rubygems per lockfile); mirrored untracked .ace/hitl/config.yml into the
worktree; fired with PROJECT_ROOT_PATH=<worktree>.

LIVE: case 8xskjj (worktree hitl root), frame fbe9a004d731...DELIVERED ["2462"] ~13:42:30Z.
Wake watch armed in THIS session (mirrored wake-request consumed). Old 8xsjzs watch may also
exist - harmless, its case was rejected and can never answer.

ON WAKE (captain replies anytime): read the wake excerpt (## Answer), report via ace-hitl what
the wake carried + latency = reply_ts - 13:41:43Z, close the ask-flow acceptance, then step 5.

WAKE-1 (13:4x UTC, watch:ask-8xskgh): ECHO, not the answer. The cancelled mis-fire case file
changed because of my own `update --set status=cancelled` write (watch armed 13:38 with
pre-cancel baseline; wake queued while turn active, delivered after). Case file confirmed:
answered=false, ## Answer empty, receipt still REJECTED. No /continue-work. SIDE RESULT: the
watch->wake idle-delivery loop is CONFIRMED WORKING end to end in this session. Still awaiting
the captain's reply on 8xskjj. (Stale watches ask-8xsjzs/ask-8xskgh linger in the registry -
harmless; their cases can never answer.)
WAKE-2 (watch:ask-8xskgh): also NOISE - reported the WORKTREE hitl DIR stat (mtime 13:41:44 =
my own case+wake-requests creation churn during re-arm), observed late by idle-throttled
reconcile. Verified: 8xskjj ## Answer EMPTY, receipt delivered ["2462"], no reply yet. Do not
act on further ask-8xskgh/ask-8xsjzs wakes; only a wake naming an answer for 8xskjj counts.
WAKE-3 (post-closure, watch:ask-8xskjj): THE REAL ONE - wake carried "answer: ok" (fired on the
asker-side consumption write of ## Answer). Wake arc mechanically complete end to end: case
change -> wake -> answer content delivered. No /continue-work: already consumed, booked, closed
(report 2464), task archived. Note: wake latency was dominated by the stranded-reply interval +
idle throttle - exactly what the next-slice retarget (watch transport reply path) removes.

## RESUME POINT (zapisany przed restartem herdr — cold-start context)

DONE (2026-10-29): PR83 merged by project lane (main = a1cc51fd9); 3 hotfix
gems PUBLISHED and verified live (ace-support-items 0.15.16, ace-hitl 0.24.3,
ace-hitl-hermes 0.9.6); OTP by the simple ask/wait/publish loop.

REMAINING (a fresh session picks up HERE — read the whole task first):
1. Install the 3 gems into /home/mo/.local/share/ace-lab/runtimes/lab92-v2.
2. Deploy extension: copy ace-wake/ from merged main to ~/.pi/agent/extensions/ace-wake.
3. Restart your own pi process (extensions load at start); ace-lab verify == 18/0/0.
4. LIVE-TEST full arc: fresh test ask ("reply OK when convenient"), Captain
   replies whenever, the WAKE must deliver the answer to you. Report what the
   wake carried + latency (this closes the ask-flow acceptance).
5. Report cycle closure via Lab::ACE; note "host: GitHub sync pending" (main
   is ahead). Close panes. Mark task done.

Standing rules live at the top of this task (charter) — apply them always.
