# Draft Usage

## Scenario 1: Run the assignment-facing preset

Goal: review a PR using the canonical shipped preset without any preset-owned prompt bundle.

Command:

```bash
mise exec -- ace-review --preset pr-risk-based --auto-execute
```

Expected behavior:
- the preset resolves the review subject and pipeline
- selected reviewers provide the prompt composition
- no preset `instructions` or `prompt_composition` keys are required

## Scenario 2: Adjust review focus by editing a reviewer

Goal: change what the `correctness` lane reviews without touching the preset.

Change:

```yaml
prompt:
  base: "prompt://base/system"
  sections:
    review_focus:
      files:
        - "prompt://focus/languages/ruby"
        - "prompt://focus/quality/correctness"
        - "prompt://focus/contracts/public-api"
```

Expected behavior:
- `code-valid` and `pr-risk-based` both pick up the reviewer change
- no preset file needs to be edited for the change to apply

## Scenario 3: Reject stale preset-owned instructions

Goal: fail clearly when a preset still tries to own review intent.

Invalid preset:

```yaml
pipeline: narrow-risk-based
instructions:
  base: "prompt://base/system"
```

Expected behavior:
- preset resolution fails
- the error explains that review instructions must live in reviewer definitions
