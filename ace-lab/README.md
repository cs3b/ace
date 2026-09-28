## ace-lab

Topology and routing CLI for the Lab: address projects, agents, and services
by stable IDs. Part of ACE (Agentic Coding Environment).

`ace-lab` answers one question -- *what is the stable ID of the project, agent,
or service I mean, and what is it authorized and able to do?* -- from
configuration alone. It never invokes Lab, never reads credentials, tracks no
work, and never guesses transient pane or session identifiers.

### Install

    gem install ace-lab

### Usage

Configure topology via the ADR-022 cascade (`~/.ace/lab/config.yml` or
`.ace/lab/config.yml`; deployed values are owned by the `lab-config`
repository):

```yaml
schema_version: 1
authorization:
  principals:
    "<verified-local-uid>": { projects: ["atlas"] }
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

Query it:

    ace-lab projects --format json
    ace-lab agents --project atlas --format json
    ace-lab services --project atlas --format json
    ace-lab resolve --id atlas-planner --format json
    ace-lab route --project atlas --capability search --format json

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

- **Read-only by contract.** No Lab invocation, no execution state, no

  scheduling, no credentials -- service invocation and execution state belong
  to separate tools.

### Non-goals

`ace-lab` is not an execution-state engine. It does not invoke services
(`8wr.t.qjx` owns the service contract), track Works or assignment state, or
schedule anything. Deployed topology values are owned by `lab-config`
(`8wl.t.gad`); this package defines and validates the schema.

### Development

    bundle install
    ace-test ace-lab        # or: bundle exec rake test from ace-lab/
