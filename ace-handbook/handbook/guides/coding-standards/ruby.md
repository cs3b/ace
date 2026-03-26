# Ruby Coding Standards

This sub-guide captures conventions and idioms specific to Ruby development in this project. Follow these in
addition to the generic standards in `../coding-standards.md`.

## Idioms & Best Practices

- Follow the community Ruby Style Guide (<https://rubystyle.guide/>) unless overridden here.
- Prefer blocks and `yield` for configurability and iteration when appropriate.
- Use metaprogramming judiciously; prioritize clarity over cleverness.
- Leverage standard library features instead of reinventing the wheel.

## Formatting

- Indentation: 2 spaces (no tabs).
- Line length: 100 characters max.
- Use `standardrb` or `rubocop -A` to auto-correct formatting issues.

## Error Handling

- Derive custom errors from `Aira::Error` base class.
- Include contextual data (e.g., `user_id`, `task_id`) when raising.

## Testing Conventions

- Use RSpec with the directory layout defined in `guide://testing` (Ruby/RSpec section).
- Tag specs (`:unit`, `:integration`, `:e2e`) per the testing guide.

## File Organization

- Mirror production code structure under `spec/`.
- Group concerns into modules; avoid deep inheritance trees.

## Performance Tips

- Prefer `each` over `map` when you don't need the new array.
- Avoid creating unnecessary objects in hot code paths.

---

Refer back to the main coding standards guide for cross-language principles.
