I would like to make certain improvements to dev-handbook

1. extract templates to dev-handbook/templates/
  currenlty we have them in guides e.g.:
  - dev-handbook/guides/code-review
  - dev-handbook/guides/initialize-project-templates

  we should add proper suffixes for each of them so they will never mixed with real one when search for files e.g.:
  - .prompt.md
  - .template.md
  - ...

  # When preparing the task
  a) search for all templates inside the guides
  b) propose the structure e.g.:
    - dev-handbook/guides/code-review/_code-review-system.md -> dev-handbook/templates/review-code/system.prompt.md
    - dev-handbook/guides/code-review/_meta-code-review-comprison.md -> dev-handbook/templates/review-synthezizer/system.prompt.md
    - dev-handbook/guides/initialize-project-templates/architecture.md -> docs/arhictecture.template.md
    - ...

  # When executing the task (user will verify the task proposition in part b))
  c) for all the templates move them to correct place
  d) update all the reference for the old paths -> new paths
