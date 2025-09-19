

subject: diff from sha till HEAD on following repos (commads for context: git -C dev-hanbook diff 0567c83~1..HEAD and so on for each repo )

[main]         8e7882c chore: update submodules after review implementation
[.ace/handbook] 0567c83 feat(code-review): implement preset-based command config
[.ace/tools]    df8f6e2 refactor(cli): redesign code-review command

context:

- presets: project, .ace/handbook, .ace/tools

- context for system prompt:
    .ace/handbook/templates/review-modules/focus/architecture/atom.md
    .ace/handbook/templates/review-modules/focus/languages/ruby.md
    .ace/handbook/templates/review-modules/focus/scope/tests.md
    .ace/handbook/templates/review-modules/focus/scope/docs.md
    .ace/handbook/templates/review-modules/format/detailed.md
    .ace/handbook/templates/review-modules/guidelines/tone.md
    .ace/handbook/templates/review-modules/guidelines/icons.md
