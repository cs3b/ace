---
description: Simple example showing basic section usage
bundle:
  params:
    output: stdio
    format: markdown-xml
    embed_document_source: true

  sections:
    focus:
      title: "Main Files"
      content_type: "files"
      priority: 1
      files:
        - "src/main.js"
        - "package.json"

    commands:
      title: "System Info"
      content_type: "commands"
      priority: 2
      commands:
        - "pwd"
        - "git status --short"
---

This is a simple example demonstrating the basic structure of section-based configuration. It shows two sections: one for files and one for commands, each with a title, content type, and priority.