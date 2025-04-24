# Implementing Task Cycle: Ruby Application

This details specific steps and commands for the task cycle when working on a Ruby application within this project.

1.  **RSpec first**: `bundle exec rspec --only-failures` keeps focus on broken specs. citeturn0search2
2.  **Code & RuboCop**: Auto‑correct style (`bundle exec rubocop -A`), then rerun tests.
3.  **Commit / Retrospect / Re‑commit** as per the [generic cycle](docs-dev/guides/implementing-task-cycle.md).
4.  **CI** → GitHub Action runs Ruby 3.2 & 3.3 matrix with `rspec` + `rubocop`.
5.  **Deployment** handled by a separate release workflow.
