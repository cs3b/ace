---
tc-id: TC-002
title: Configuration Override
---

## Objective

Verify that validator selection can be configured via .ace/lint/ configuration files.

## Steps

1. Create configuration to prefer RuboCop and lint
   ```bash
   mkdir -p .ace/lint
   cat > .ace/lint/ruby.yml << 'EOF'
   groups:
     default:
       patterns:
         - "**/*.rb"
       validators:
         - rubocop
   EOF
   ace-lint lint valid.rb
   ```

## Expected

- Configuration is respected, RuboCop is used despite StandardRB being available
- File is linted successfully
