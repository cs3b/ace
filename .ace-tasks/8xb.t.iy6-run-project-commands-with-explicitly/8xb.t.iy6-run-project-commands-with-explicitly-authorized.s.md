---
id: 8xb.t.iy6
status: draft
priority: medium
created_at: "2026-10-12 12:37:58"
estimate: large
dependencies: []
tags: [ace-lab, execution, services]
title: Run project commands with explicitly authorized service access
needs_review: true
bundle:
  presets: [project]
  files:
    - ace-lab/docs/usage.md
    - ace-lab/lib/ace/lab/cli/commands/service.rb
    - ace-lab/lib/ace/lab/molecules/service_policy.rb
    - ace-lab/lib/ace/lab/organisms/service_request_service.rb
    - .ace-bin/ace-rubygems-publish
    - .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md
    - .ace-tasks/8xb.t.iy6-run-project-commands-with-explicitly/ux/usage.md
  commands: []
---

# Run project commands with explicitly authorized service access

## Objective and user experience
An operator or project agent invokes a configured project command without sudo,
per-release wrappers, copied credentials or manual changes of Unix identity. The
command runs as the authorized executor with the project's working directory and
only the approved execution context. Interactive publication retains a real TTY,
including a no-echo OTP prompt, while the caller receives the actual result.
The Captain explicitly requested this behavioral draft; this is not authority to
implement it, provision grants or publish a release.

## Expected behavior
- Each project configuration declares an unambiguous default executor, working
  directory, nonsecret environment, secret references, permitted commands and
  allowed service/mapping selections. An authorized administrator establishes
  execution grants; project-writable preferences cannot manufacture privileges.
- With no --service, use only the project's explicitly configured default service
  set, which may be empty. Do not infer services from command names or select all
  available services. Missing or ambiguous defaults fail before command execution.
- Repeatable --service replaces that default set with the explicitly requested set.
  All selections must exist and be individually authorized for the actual caller,
  project, operation and executor, and their combination must also be authorized.
  Never union privileges implicitly, silently drop a denied selection, choose a
  broader executor or execute with partial grants. Repeated identical selectors
  are deduplicated; incompatible mappings, executor UIDs or environment/secret destinations fail before effects. All requested services must be compatible with one permitted executor.
- Optional --as chooses only an already configured, permitted executor mapping.
  An unknown identity, caller-supplied role string or administrator username is not
  a grant. No --as means the single configured project default, not ambient root.
- Execute only commands admitted by the project's trusted command policy. The argv
  after -- is passed literally, without an added shell; relative executables resolve
  against the configured project context. Authorization covers the actual executable
  and arguments. Reject unsafe substitutions rather than allowing arbitrary code
  with unrelated service credentials. Invoking a shell itself needs an explicit grant.
- Before executing a release command, resolve and report the actual checkout/cwd,
  source ref and exact commit against the accepted release scope. Dirty or diverged
  source is preserved and reported; require its owning workflow to reconcile the
  mismatch before effects. Never automatically wipe, reset or switch foreign work.
- Keep secrets outside command arguments, diagnostic output, recorded metadata and
  shell history. Resolve only configured secret references inside the permitted
  executor context. A command explicitly granted a secret may use it; do not claim
  to prevent a malicious permitted command from printing its own secrets. ACE's
  own output never dumps credentials or environment contents.
- mo invokes the public CLI without sudo. The child has the actual configured UID,
  GID and allowed supplementary groups. Root configuration/provisioning remains
  administrator-owned; missing execution capability is a classified blocker, not
  automatic privilege escalation or a fallback to legacy Work.
- Preserve terminal size, input/output, signals and exit behavior. getpass works
  without echo in an interactive terminal. EOF and Ctrl-C reach the child; normal
  command failure is reported accurately. Non-TTY invocation does not pretend to
  provide an interactive prompt or secretly allocate an unrelated terminal.
- Attribute invocation/result to the existing execution/evidence owner. Preserve
  command/selection identity and sanitized result, not a second queue or journal.
  A lost completion response is uncertain; never rerun external effects automatically.

## Public interface contract

```sh
ace-lab run --project ace -- .ace-bin/ace-rubygems-publish --interactive
ace-lab run --project ace --service rubygems-publish --service forgejo -- .ace-bin/ace-rubygems-publish --interactive
ace-lab run --project ace --as lab-admin --service rubygems-publish -- .ace-bin/ace-rubygems-publish --interactive
```

--project is required; --as is optional and singular; --service is optional and
repeatable; -- separates the command argv. Empty argv and conflicting singleton
options are usage errors. Success preserves command exit0; completed nonzero child
status is preserved. Signal termination preserves conventional shell signal status.
Preflight refusals return nonzero with a stable classified cause (unknown project,
ambiguous default, denied service/combination/executor, unavailable identity or
invalid command/context) and no command/credential-bearing child starts. Runtime
uncertainty exposes the original execution reference and read-only reconciliation
path; it is not reported as successful completion.

The project configuration surface must document the named default executor,
working directory, environment/secret references, default service set and allowed
service/mapping/command policy, their trusted ownership and precedence. Do not add
CLI flags that accept caller-selected credential values, grant files or policy roots.

## Scope and ownership
Single end-to-end capability, advisory size large. Owner ace-lab; reuse current
identity/admission/execution/evidence primitives. Existing qjx owns structured
service request routing; xz9 owns cross-user fixed-handler admission and expressly
excludes shell passthrough. This task adds the user-requested interactive project
command surface, not another implementation of those boundaries. Confirm the
producer integration contracts during readiness review; no false completed
prerequisite or installed proof is asserted. lab-config owns domain configuration
and real installation acceptance. No new Python bridge, generic daemon, per-release
launcher, copied credentials, fake Work or fabricated attempt.

## Success criteria and verification plan
- [ ] An unprivileged real caller executes a permitted project command under the
  configured distinct account without sudo; verify real UID/GID/groups/cwd and
  approved environment using nonsecret probes. Defaults and explicit --as agree
  with trusted configuration; requester edits cannot expand authority.
- [ ] Zero, one and multiple selected services follow the documented defaults,
  replacement and all-grants rules. A denied member or unauthorized combination
  prevents every child/effect; cross-project and incompatible-mapping cases fail.
- [ ] A real PTY test exercises getpass without echo, terminal resize, EOF, Ctrl-C,
  ordinary exit0/nonzero and signal termination. Test non-TTY behavior separately.
- [ ] Secret references resolve only for admitted selections. Execute tests with
  synthetic secrets and assert ACE diagnostics, argv and stored evidence contain
  neither values nor full environment dumps. Missing/revoked grant or secret refuses.
- [ ] Wrong/changed executable, arguments, cwd or identity is refused at admission;
  interruption after launch retains attributable uncertainty and never auto-replays
  a publisher or other effect. Concurrent invocations remain attributable and isolated.
- [ ] Fresh public CLI and project configuration documentation demonstrate the three
  scenarios in ux/usage.md. Run ace-test ace-lab all and relevant affected package
  tests after implementation, plus independent review and real distinct-user/PTY
  integration fixtures. No code/tests are implemented or executed during drafting.

## Decisions and references
No new behavioral approval is requested: the Captain specified project defaults,
optional multiple services and constrained --as. Defaults and denial behavior are
explicit above. Readiness review must verify capability composition against existing
producers before promotion; status remains draft. UX contract: ux/usage.md.
Environment interface: lab-config docs/lab-interface.md. Existing h8x one-off
publisher illustrates the user pain, but this task is reusable project execution,
not expansion of that release authorization or a task to publish more packages.

## Draft producer-composition acceptance — needs review

The identity, all-or-nothing service admission, cwd/environment/secret, literal
argv, PTY/getpass/signal/exit and uncertain-no-replay criteria above are the single
acceptance owner for those behaviors; qk0/qkb must cross-reference them and must not
duplicate a narrower command runner. The open source work is the producer join:

- trusted project configuration owns executor/default-service/command/cwd/env and
  secret-reference precedence; caller-writable repository configuration cannot
  override installed admission or choose credentials;
- the public invocation returns one execution reference only after durable
  authenticated admission, and a public read-only status path accepts that exact
  original reference and selectors after requester or receiver restart;
- lost admission acknowledgment resolves by the original reference, receiver
  unavailability is a classified no-child blocker, and an uncertain original child
  result is inspected without resubmitting the command;
- controlled source composition exercises the maintained CLI through the actual
  admitted producer/status owner, then the existing identity/env/PTY/no-effect
  scenarios verify the child. A one-off publisher wrapper, injected callback or
  configured integer UID does not satisfy this join.

xz9 owns reusable fixed-operation authenticated admission/execution/receipt
mechanisms, but its current protected receiver is bound to protected
authority/attempt/mapping, requires a distinct non-root executor and excludes
arbitrary shell passthrough. iy6 must implement a separately reviewed project-command
producer that uses its own explicit command policy and cannot borrow the protected
receiver or turn fixed handlers into caller-selected argv. qkb.1 owns the ordinary
fixed merge producer/receipt consumer; qk0/qk0.1.1 owns overseer recovery and wake
behavior. Shared execution-reference/status primitives may be factored to their ACE
owner only after their authority semantics are explicit. `gad.b` installs reviewed
configuration and `gad.2` proves real identities/PTY after source availability.
There is no Python host bridge, raw maintainer-token transfer or cross-VM HTTP
fallback.
