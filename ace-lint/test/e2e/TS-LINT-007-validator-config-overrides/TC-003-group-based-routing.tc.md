---
tc-id: TC-003
title: Group-based Routing
---

## Objective

Verify that file groups route to correct validators based on pattern matching.

## Steps

1. Create group routing config and lint each group
   ```bash
   mkdir -p .ace/lint
   cat > .ace/lint/ruby.yml << 'EOF'
   groups:
     legacy:
       patterns:
         - "**/legacy/**/*.rb"
       validators:
         - rubocop
     modern:
       patterns:
         - "**/modern/**/*.rb"
       validators:
         - standardrb
     default:
       patterns:
         - "**/*.rb"
       validators:
         - standardrb
   EOF
   mkdir -p legacy modern
   cp valid.rb legacy/
   cp valid.rb modern/
   echo "=== Legacy (expect RuboCop) ==="
   ace-lint lint legacy/valid.rb
   echo "=== Modern (expect StandardRB) ==="
   ace-lint lint modern/valid.rb
   ```

## Expected

- Legacy file uses RuboCop
- Modern file uses StandardRB
- All files are linted successfully
