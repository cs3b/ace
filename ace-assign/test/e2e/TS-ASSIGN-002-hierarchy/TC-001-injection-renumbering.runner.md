# Goal 1 — Injection and Renumbering

## Goal

Validate child injection and cascade renumbering using public `ace-assign add --yaml`
operations and full-status snapshots.

## Workspace

Save command captures to `results/tc/01/`.

## Constraints

- Create assignment from local fixture path `injection/jobs/8qbyvw-job.yml`.
- Select the assignment (`ace-assign select <id>`) and mutate through active context.
- Use `add --yaml` with scratch YAML files under `.ace-local/e2e-inputs/tc01/`.
- Demonstrate these outcomes with status snapshots between operations:
  - initial children at `010.01`, `010.02`, `010.03`
  - sibling injection after `010.01` causing renumber shift
  - grandchild placement under renumbered parent
  - second parent-level injection causing descendant cascade renumbering
- Mention assignment id and final descendant path in runner observations.

## Evidence Guidance

- Outcome snapshots and step numbering are the primary oracle.
- Strict fixed capture-name choreography is optional; consistency is sufficient.
