# ace-lab usage

Topology and routing CLI for the Lab. Resolves stable project, agent, and
service IDs from configuration -- without knowing transient pane IDs or
holding service credentials.

## Commands

All commands accept `--format json` (the only supported format; anything else
is rejected) and `-q/--quiet` (suppress stdout; exit semantics unchanged).

### `ace-lab projects`

List projects visible to the verified caller.

    $ ace-lab projects --format json
    {"status":"ok","data":{"projects":[{"id":"atlas","label":"Atlas platform"},{"id":"borealis"}]}}

A caller with no configured principal receives:

    {"status":"error","error":{"code":"unauthorized","message":"caller has no configured authorization for any lab project"}}

### `ace-lab agents --project PROJECT`

List agents in one project.

    $ ace-lab agents --project atlas --format json
    {"status":"ok","data":{"agents":[{"id":"atlas-planner","project":"atlas","role":"planner","capabilities":["planning"],"binding":{"kind":"runtime","state":"available"}}]}}

`binding.state` is `available` when the configured runtime binding is active
and its instance identity matches the attestation; otherwise `stale`.

### `ace-lab services --project PROJECT`

List services in one project.

    $ ace-lab services --project atlas --format json
    {"status":"ok","data":{"services":[{"id":"atlas-search","project":"atlas","capabilities":["search"],"default_for":["search"],"binding":{"kind":"service","state":"available","endpoint":{"kind":"http","url":"https://search.example.internal:8443"}}}]}}

The endpoint is a sanitized identity: scheme, host, and explicit port only.

### `ace-lab resolve --id ID`

Resolve one entry by exact stable ID.

    $ ace-lab resolve --id atlas-planner --format json
    {"status":"ok","data":{"entry":{"id":"atlas-planner","project":"atlas","role":"planner","capabilities":["planning"],"binding":{"kind":"runtime","state":"available"}}}}

Labels are display values and never resolve: `resolve "Atlas platform"` is a
`missing` error.

### `ace-lab route --project PROJECT --capability CAPABILITY`

Select a configured capable service in the requested project.

    $ ace-lab route --project atlas --capability search --format json
    {"status":"ok","data":{"entry":{"id":"atlas-search","project":"atlas","capabilities":["search"],"default_for":["search"],"binding":{"kind":"service","state":"available","endpoint":{"kind":"http","url":"https://search.example.internal:8443"}}}}}

Routing never invokes the service and never grants credentials.

## Error semantics

Errors are one deterministic JSON document on stdout plus a non-zero exit.

| Code | Meaning |
|------|---------|
| `missing` | No entry with that stable ID, or no capable service in the project |
| `ambiguous` | Several equally capable services without a configured `default_for` |
| `stale` | Binding is inactive, unattested, or the instance identity was replaced |
| `unauthorized` | Caller's verified local identity has no principal for the project |
| `invalid_configuration` | Topology config violates the schema; message is actionable |

Example:

    $ ace-lab resolve --id atlas-coder --format json; echo $?
    {"status":"error","error":{"code":"stale","message":"stable ID \"atlas-coder\" has a stale runtime binding; a replaced process must re-attest before routing","id":"atlas-coder","project":"atlas"}}
    1

## Configuration

Schema version 1, resolved through the ADR-022 cascade (project `.ace/lab/`
over user `~/.ace/lab/` over gem defaults; gem defaults are an empty, safe
topology). Cascade documents carry **topology only**:

```yaml
schema_version: 1
topology:
  projects:
    - id: atlas               # globally unique across all entries
      label: Display name     # display only; never resolves
  agents:
    - id: atlas-planner
      project: atlas          # must reference an existing project
      role: planner
      capabilities: [planning]  # non-empty; normalized (stripped, lowercased)
      binding:
        kind: runtime           # agents bind to runtimes, services to services
        state: active           # routeable only when active
        instance_id: i1         # runtime identity fact
        attested_instance_id: i1  # must equal instance_id to be fresh
  services:
    - id: atlas-search
      project: atlas
      capabilities: [search]
      default_for: [search]     # exactly one default may win among candidates
      endpoint:
        kind: http              # http or https
        url: "https://search.example.internal/query?token=secret"  # stored, never published
      binding: { kind: service, state: active, instance_id: i2, attested_instance_id: i2 }
```

### Authorization grants

Grants never live in the cascade: project and user documents are
caller-writable, so an `authorization` section there is rejected as
`invalid_configuration`. Grants come from a single deployment-controlled
file at the **fixed path** `/etc/lab/ace-lab/authorization.yml` (installed
by the `lab-config` deployment). The location is not caller-selectable —
there is no flag or environment override. At every query the tool verifies
the file and every directory on its real path are root-owned and not
group/world-writable, and opens the file `O_NOFOLLOW`; any failed
verification fails closed:

```yaml
principals:
  "<verified-local-uid>":     # passwd username or numeric uid of the caller
    projects: ["atlas"]
```

A missing trusted file means nobody is authorized (fail closed).

Validation rejects duplicate IDs (globally unique across projects, agents,
services), unknown project references, malformed capabilities, defaults for
undeclared capabilities, unusable endpoints (absolute http(s) URL with a host
and a port in 1–65535; `endpoint.kind` is `http` or `https`), unsupported
binding kinds, and principals referencing unknown projects.

**Error messages are value-free by design:** validation runs before
authorization, so messages use positional field locations
(`topology.agents[0].project references an unknown project`) and never echo
configured IDs, project names, or principal names — configuration defects
cannot disclose topology to unauthorized callers.

**Ownership:** deployed topology and authorization values are maintained by
the `lab-config` repository (`8wl.t.gad`). `ace-lab` defines the schema and
reads; it never provisions.

## Guarantees and boundaries

- Public output is built from a strict allowlist: `id`, `project`, `label`,

  `role`, `capabilities`, `default_for`, binding `kind` + availability state,
  and a sanitized endpoint identity. Tokens, auth-file paths, URL userinfo,
  paths, query parameters, fragments, pane/session IDs, and instance
  identities never appear in any command output.

- Caller identity comes from the verified local process owner

  (username or uid). `--role`, `--principal`, and `--caller` flags are
  rejected: authorization is a property of the caller, not an input.

- A replaced process keeps its stable ID; until re-attested, queries

  classify it `stale` -- an explicit unavailable result, never a routeable
  answer.

- No Works, assignment state, or scheduling. Service invocation belongs to

  `8wr.t.qjx`; execution state to `8wr.t.qjl`. The Lab execution binary
  (`/usr/local/bin/lab`) is never invoked or required.
