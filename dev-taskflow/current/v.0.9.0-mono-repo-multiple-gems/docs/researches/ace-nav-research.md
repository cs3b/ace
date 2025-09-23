Got it 👍 — you want a CLI helper (ace-nav) that abstracts away the gem lookup, so Claude commands don’t need to know about Gem::Specification or filesystem details. Here’s a solid approach:

⸻

1. CLI Helper Design

Add a bin script to your gem (bin/ace-nav):

#!/usr/bin/env ruby
# bin/ace-nav

require "optparse"
require "ace/context"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ace-nav wfi::/load-context [--path] [--content]"

  opts.on("--path", "Print only the resolved file path") { options[:path] = true }
  opts.on("--content", "Print the content of the file") { options[:content] = true }
end.parse!

# Parse resource key, e.g. "wfi::/load-context"
resource = ARGV.shift
unless resource == "wfi::/load-context"
  warn "Unknown resource: #{resource}"
  exit 1
end

# Resolve file path
spec  = Gem::Specification.find_by_name("ace-context")
file  = File.join(spec.gem_dir, "handbook/workflow-instructions/load-context.wfi.md")

if options[:path]
  puts file
elsif options[:content]
  puts File.read(file)
else
  puts file
end

Then in your .gemspec:

spec.executables = ["ace-nav"]

So after gem install ace-context, you’ll have a ace-nav executable.

⸻

2. Claude Command

Your .claude/commands/load-context.md becomes super simple:

# load-context

Read workflow instructions:

```bash exec
ace-nav wfi::/load-context --content

---

## 3. Benefits

- **Claude-friendly**: Just runs a shell command, no Ruby code inline.  
- **Dynamic**: Gem location changes? Doesn’t matter. CLI resolves it.  
- **Extendable**: You can add more resources (`wfi::/setup`, `faq::/errors`, etc.).  

---

## 4. Optional Improvements

- Add a **`--list`** flag to show available resources.  
- Support **multiple gems** (namespaced lookups).  
- Return JSON (`--json`) for structured output (Claude parses better).  

---
