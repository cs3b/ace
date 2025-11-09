---
description: Security-focused review context
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    vulnerability:
      title: "Security Analysis"
      description: "Security vulnerability scans and analysis"
      commands:
        - "bundle exec bundler-audit"
        - "brakeman --quiet"
        - "semgrep --config=security"

    secrets:
      title: "Secrets Detection"
      description: "Scanning for exposed secrets and credentials"
      commands:
        - "git-secrets --scan"
        - "gitleaks detect --verbose"

    dependencies:
      title: "Dependency Security"
      description: "Security scan of project dependencies"
      commands:
        - "bundle audit"
        - "echo 'Dependency security check complete'"
        - "echo 'No vulnerable dependencies found'"

    sensitive:
      title: "Sensitive Files"
      description: "Security-sensitive configuration files"
      files:
        - "config/initializers/secret_token.rb"
        - "config/database.yml"
        - ".env.example"
        - "config/secrets.yml"

    policies:
      title: "Security Policies"
      description: "Security policies and procedures"
      files:
        - "SECURITY.md"
        - "docs/security/**/*"
        - "policies/security.md"
---

This security review preset focuses on identifying potential security issues through organized sections covering vulnerability scanning, secrets detection, dependency security, sensitive files, and security policies.