# Address Lab projects agents and services by stable IDs: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Resolve a project agent

```text
ace-lab resolve --id overseer-ace --format json
```

Expected: Returns its stable project/role identity and currently verified runtime binding.

## Scenario 2: Find a publisher

```text
ace-lab route --project ace --capability rubygems-publish --format json
```

Expected: Returns one configured publisher identity or explicit ambiguity, never its token.
