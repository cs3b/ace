---
doc-type: user
title: ace-b36ts Getting Started
tags:
  - ace-b36ts
  - getting-started
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with `ace-b36ts`

## Prerequisites

- Ruby 3.2+
- `ace-b36ts` installed and on `PATH` through the repo bundle

## Install

- From RubyGems:

```bash
gem install ace-b36ts
```

- From this repo (development environment):

```bash
mise exec -- bundle install
```

## First Encode

Run from the project root:

```bash
mise exec -- ace-b36ts encode now
```

Expect an output like:

```text
i50jj3
```

## Decoding

Round-trip the result using:

```bash
mise exec -- ace-b36ts decode i50jj3
```

If the ID is valid, this prints a UTC timestamp.

## Format Options

Start with these common options:

- `day`
- `week`
- `2sec` (default)
- `ms`

Examples:

```bash
mise exec -- ace-b36ts encode --format day now
mise exec -- ace-b36ts encode --format week now
mise exec -- ace-b36ts encode --format ms now
```

## Ruby API Basics

```ruby
require "ace/b36ts"

# Current time
Ace::B36ts.now

# Encode a specific time
Ace::B36ts.encode(Time.utc(2025, 1, 6, 12, 30, 0))

# Encode with custom year zero
ace = Ace::B36ts.encode(Time.now, year_zero: 2025)

# Decode compact IDs
Ace::B36ts.decode("i50jj3", year_zero: 2025)
```

## Split Encoding for Paths

```ruby
parts = Ace::B36ts.encode_split(Time.now, levels: [:month, :week, :day], year_zero: 2025)
# => { month: "i5", week: "1", day: "5", rest: "jj3", path: "i5/1/5/jj3", full: "i515jj3" }
parts[:path]
# => "i5/1/5/jj3"
```

## Common Commands

| Command | What it does |
| --- | --- |
| `ace-b36ts encode now` | Generate a compact ID using default format |
| `ace-b36ts encode --format day now` | Generate day-level compact ID |
| `ace-b36ts decode <id>` | Decode an ID back to timestamp |
| `ace-b36ts config` | Show resolved configuration |

## What to try next

- Add `.ace/b36ts/config.yml` for project-level configuration
- Set custom `year_zero` in config or command flags
- Use format detection and validation for mixed inputs
