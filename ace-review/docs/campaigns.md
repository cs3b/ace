# Durable review campaigns -- planned (L5.5)

> **Planned (L5.5):** role rules, independent review rounds, and the
> forge-neutral review/delivery workflow are not available yet.

The `ace-review campaign` commands still exist in the codebase from the
replaced protected model. They are not part of the file-based flow and must not
be used as the current review owner:

- They consume attempt/execution evidence from the old coordinator/journal

  boundary, which L1 removed from the active flow.

- They require accepted receipts and journal evidence that an ordinary local

  assignment does not produce.

Until L5.5 defines the supported role/review-round contract, use the ordinary
review path instead:

```bash
bin/ace-review --preset code-valid --subject diff:BASE..HEAD --auto-execute
bin/ace-review-feedback list --status pending
```

The local review session and feedback artifacts remain under `.ace-local/review/`.
See [usage](usage.md) for the supported review and feedback commands.
