---
id: 8ws.t.m0h
status: done
priority: high
created_at: "2026-09-29 14:40:32"
estimate: 
dependencies: []
tags: [spinel, aot, support-gems]
---

# Support-gem AOT lowering (help/version commands, usage/registry/banner, Config#get, fs)

Support gems lowered for AOT (CRuby suites green):

- **ace-support-cli**: HelpCommand/VersionCommand rebuilt as statically-declared classes returning configured instances (Spinel bakes the class graph — Class.new unsupported); usage.rb duck-registry branch routed through a poly-dispatch helper; registry.rb manual path split; banner.rb index-based description walk; factory tests updated to the instance contract.
- **ace-support-config**: Config#get loop rewrite (return-in-block misboxes); Config.wrap narrowing; explicit require "set"; permitted_classes without Date; path_rule_matcher/file_config_resolver pair-iteration rewrites; setup_doctor tty/line_count typing.
- **ace-support-fs**: explicit require "set"; gsub! -> gsub chains (gsub! union misboxes).

Suites: ace-support-cli 60/60, ace-support-config 252/252, ace-support-fs 71/71.
