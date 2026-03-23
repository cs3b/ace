# ace-support-nav

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-support-nav.svg)](https://rubygems.org/gems/ace-support-nav)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Protocol-aware navigation and resource discovery for ACE handbook content.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-nav` powers the [`ace-nav`](../ace-support-nav) CLI with cascade-aware URI resolution across project, user, and gem sources. It supports protocols like `wfi://`, `guide://`, `tmpl://`, `skill://`, and `task://`, with override targeting, wildcard discovery, and fast cached lookups.

## How It Works

1. Accept a protocol URI (e.g., `wfi://setup`) and search project, user, and gem handbook sources in cascade order.
2. Apply extension inference and override targeting (`@project`, `@user`, `@gem`) to locate the best match.
3. Return the resolved path, content, or a list of candidates for wildcard and prefix patterns.

## Use Cases

**Resolve ACE resources without memorizing file paths** - run `ace-nav resolve wfi://setup` or `ace-nav resolve guide://configuration` to locate workflows, guides, templates, and skills through protocol URLs instead of raw paths.

**Target the right override layer explicitly** - use `@project`, `@user`, or specific gem aliases (e.g., `wfi://@ace-git/setup`) to bypass cascade ambiguity when multiple sources provide the same resource.

**Discover matching resources quickly** - use wildcard and prefix patterns like `ace-nav list 'wfi://*test*'` or `ace-nav resolve prompt://guidelines/` to browse available content across all handbook sources.

**Navigate task specs through the same interface** - use `task://` references (e.g., `ace-nav resolve task://083`) so task lookup shares the same navigation workflow as handbook resources, delegating to [ace-task](../ace-task) under the hood.

**Load resolved content into agent workflows** - pair with [ace-bundle](../ace-bundle) to fetch and embed resources discovered through `ace-nav` into agent context for skills and workflows.

## Documentation

Command help: `ace-nav --help`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
