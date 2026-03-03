---
status: pending
priority: maybe
id: 8l4k0w
title: Idea
tags: []
created_at: '2025-10-05 13:20:59'
---

# Idea

 we should check for all dependencies at the beginning of tha process - if possible, eg.:│ │ Issue 2: Wrong Binary Check                                                                                  │ │
│ │                                                                                                              │ │
│ │ Problem: llm_executor.rb:23 checks for ace-llm but should check for ace-llm-query                            │ │
│ │                                                                                                              │ │
│ │ Current code (line 23):                                                                                      │ │
│ │ unless command_exists?('ace-llm')                                                                            │ │
│ │                                                                                                              │ │
│ │ Should be:                                                                                                   │ │
│ │ unless command_exists?('ace-llm-query')                                                                      │ │
│ │                                                                                                              │ │
│ │ Note: Line 65 correctly uses 'ace-llm', 'query' as separate args, but the binary is actually ace-llm-query   │ │
│ │ not ace-llm                                                                                                  │ │
│ │

---
Captured: 2025-10-05 14:21:11