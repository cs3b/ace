---
status: done
completed_at: 2025-12-09 00:27:04.000000000 +00:00
id: 8n51ss
title: Idea
tags: []
created_at: '2025-12-06 01:11:58'
---

# Idea

Migrate ace-llm YAML config loading from Symbol to String keys Tech debt: ace-llm client_registry.rb uses YAML.load_file with permitted_classes: [Symbol, Date] which could theoretically allow DoS via symbol table exhaustion if untrusted configs were loaded. Current risk is low (configs are local/repo-controlled) but defense-in-depth suggests migrating to string-only keys project-wide. This would also simplify configuration handling consistency across gems. tech-debt,security,ace-llm

---
Captured: 2025-12-06 01:12:04