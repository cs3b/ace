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
      content_type: "commands"
      priority: 1
      description: "Security vulnerability scans and analysis"
      commands:
        - "bundle exec bundler-audit"
        - "brakeman --quiet"
        - "semgrep --config=security"

    secrets:
      title: "Secrets Detection"
      content_type: "commands"
      priority: 2
      description: "Scanning for exposed secrets and credentials"
      commands:
        - "git-secrets --scan"
        - "gitleaks detect --verbose"

    dependencies:
      title: "Dependency Security"
      content_type: "commands"
      priority: 3
      description: "Security scan of project dependencies"
      commands:
        - "bundle audit"
        - "npm audit --production"
        - "snyk test"

    sensitive:
      title: "Sensitive Files"
      content_type: "files"
      priority: 4
      description: "Security-sensitive configuration files"
      files:
        - "config/initializers/secret_token.rb"
        - "config/database.yml"
        - ".env.example"
        - "config/secrets.yml"

    policies:
      title: "Security Policies"
      content_type: "files"
      priority: 5
      description: "Security policies and procedures"
      files:
        - "SECURITY.md"
        - "docs/security/**/*"
        - "policies/security.md"
---

This security review preset focuses on identifying potential security issues through organized sections covering vulnerability scanning, secrets detection, dependency security, sensitive files, and security policies.