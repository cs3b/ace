---
doc-type: user
title: ace-idea
purpose: Landing page for ace-idea
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-idea

Capture and organize ideas from anywhere -- clipboard, terminal, or LLM.

![ace-idea demo](docs/demo/ace-idea-getting-started.gif)

## Why

`ace-idea` turns raw notes into structured idea files so nothing gets lost:

* capture an idea as plain text or straight from your clipboard
* ask for LLM enhancement when a rough note needs more shape
* move ideas through the root-scope `next` queue plus `_maybe`, `_anytime`, and `_archive`
* keep the workflow small with six commands: create, show, list, update, doctor, status

## Works With

* `ace-task` when an idea is ready to become a task
* `ace-bundle` for loading idea workflows directly
* `ace-git-commit` for scoped commits around idea changes

## Agent Skills

Package-owned canonical skills:

* `as-idea-capture`
* `as-idea-capture-features`
* `as-idea-review`

## Features

* text, clipboard, and LLM-enhanced capture
* short sortable IDs with 3-character shortcut lookup
* GTD-style folder organization with `--move-to`
* status views, metadata updates, and doctor checks for idea hygiene

## Documentation

* [Getting Started](docs/getting-started.md)
* [CLI Usage Reference](docs/usage.md)
* [Handbook Catalog](docs/handbook.md)
* Command help: `ace-idea --help`

## Part of ACE

`ace-idea` is part of [ACE][1]: CLI tools designed for developers and ready for agents.

[1]: https://github.com/cs3b/ace
