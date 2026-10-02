## ace-lab

Topology, routing, and scoped service request CLI for the Lab. Part of ACE
(Agentic Coding Environment).

`ace-lab` answers one question -- *what is the stable ID of the project, agent,
or service I mean, and what is it authorized and able to do?* -- from
configuration. Topology queries never invoke a service. The `service`
commands submit configured operations through a verified executor and use
`ace-assign` for durable request evidence. No command hands credentials to
the caller or guesses transient pane or session identifiers.

### Install

    gem install ace-lab

### Usage

Configure topology via the ADR-022 cascade (`~/.ace/lab/config.yml` or
`.ace/lab/config.yml`; deployed values are owned by the `lab-config`
repository). Authorization grants live in a separate deployment-controlled
file at the fixed path `/etc/lab/ace-lab/authorization.yml` -- root-owned and
not group/world-writable, verified at every query -- never in the
caller-writable cascade and never at a caller-selected location:

```yaml
# .ace/lab/config.yml -- topology only
schema_version: 1
topology:
  projects:
    - { id: atlas, label: Atlas platform }
  agents:
    - id: atlas-planner
      project: atlas
      role: planner
      capabilities: [planning]
      binding: { kind: runtime, state: active, instance_id: i1, attested_instance_id: i1 }
  services:
    - id: atlas-search
      project: atlas
      capabilities: [search]
      default_for: [search]
      endpoint: { kind: http, url: "https://search.example.internal/query?token=secret" }
      binding: { kind: service, state: active, instance_id: i2, attested_instance_id: i2 }
```

```yaml
# trusted grants file (deployment-owned)
principals:
  "<verified-local-uid>": { projects: ["atlas"] }
```

Query it:

    ace-lab projects --format json
    ace-lab agents --project atlas --format json
    ace-lab services --project atlas --format json
    ace-lab resolve --id atlas-planner --format json
    ace-lab route --project atlas --capability search --format json

Request a configured operation for an active, managed assignment attempt:

    ace-lab service request --project atlas --assignment A --attempt ATT \
      --operation publish --input release.json --authorization DECISION \
      --request-id REQUEST --dry-run
    ace-lab service status --request REQUEST --format json

The trusted grants file may also contain exact `operations` and
`authorizations` mappings. See [usage](docs/usage.md) for the request schema,
executor transport, and uncertain-state recovery.

Every command prints one deterministic JSON document:

    {"status":"ok","data":{"entry":{"id":"atlas-search","project":"atlas",
     "capabilities":["search"],"default_for":["search"],
     "binding":{"kind":"service","state":"available",
     "endpoint":{"kind":"http","url":"https://search.example.internal"}}}}}

Failures are classified: `missing`, `ambiguous`, `stale`, `unauthorized`,
`invalid_configuration` -- for example a replaced agent process:

    {"status":"error","error":{"code":"stale","message":"stable ID
     \"atlas-planner\" has a stale runtime binding; ...","id":"atlas-planner",
     "project":"atlas"}}

### Guarantees

- **Stable IDs are canonical.** Labels are display values and never resolve.

  Exact match or a classified `missing` error.

- **Public output never leaks.** Tokens, auth-file paths, endpoint userinfo,

  query parameters, fragments, pane/session identifiers, and instance
  identities are excluded by an allowlist projection, not field redaction.

- **Authorization comes from the verified local process owner**, matched

  against configured principals. There is no `--role` or `--principal` flag;
  identity flags are rejected outright.

- **Routing is project-local.** Candidates are capable services of the

  requested project with fresh (active + attested) bindings. Zero candidates
  are `missing`; several equal candidates need a configured `default_for`, or
  the result is `ambiguous`. Another project's service is never picked.

- **Execution evidence is separate from topology.** `ace-lab service` uses a

  managed `ace-assign` attempt and its evidence ref. A lost executor receipt
  remains uncertain and a repeated request ID never replays the effect.

### Non-goals

`ace-lab` does not track Works or schedule anything. `ace-assign` owns attempt
state; deployed operation handlers and topology values are owned by `lab-config`
(`8wl.t.gad`); this package defines and validates the schema.

### Development

    bundle install
    bin/ace-test ace-lab all
