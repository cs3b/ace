---
id: 8ws.t.m09
status: done
priority: high
created_at: "2026-09-29 14:40:17"
estimate: 
dependencies: []
tags: [research, spinel, build]
---

# Build Spinel from source on macOS arm64 + stdlib capability probe matrix

Built spinel + spin from source on macOS arm64 in ~2 min (make deps && make; system clang). Verified hello-world: 230 KB binary, 1.2 MB peak RSS, ~30x fewer CPU cycles than `ruby -e ''`.

Stdlib capability probe matrix (require + runtime behavior):
- real: json, pathname, fileutils, Set (explicit require), Time (utc/at/nsec/strftime/now.utc), Dir.new/children/pwd, File.fnmatch (no ** recursion)
- MISSING (hard errors): yaml, date, rubygems
- SILENT STUBS: optparse (compiles, parses nothing!), timeout (ignored with warning)

Full matrix: docs/research/spinel-aot-pilot.md.
