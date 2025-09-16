Creating a Ruby command-line (CLI) tool involves several steps, from structuring your code to packaging and distributing it. Here’s a best-practice guide to building Ruby CLI tools:

⸻

🧱 1. Start with a RubyGem Scaffold

Use Bundler to generate a gem scaffold:

bundle gem my_cli_tool --.ace/tools/exe
cd my_cli_tool

This creates a directory structure like:

my_cli_tool/
├── bin/
│   └── my_cli_tool
├── lib/
│   ├── my_cli_tool.rb
│   └── my_cli_tool/
│       └── version.rb
├── my_cli_tool.gemspec

✅ The --.ace/tools/exe flag creates an executable in bin/.

⸻

🧰 2. Use CLI Libraries

Choose a library for argument parsing and CLI UX:

🔹 Thor

Great for command-style interfaces:

# lib/my_cli_tool/cli.rb
require 'thor'

module MyCliTool
  class CLI < Thor
    desc "greet NAME", "Say hello to NAME"
    def greet(name)
      puts "Hello, #{name}!"
    end
  end
end

# bin/my_cli_tool
#!/usr/bin/env ruby
require_relative "../lib/my_cli_tool/cli"
MyCliTool::CLI.start(ARGV)

Make it executable:

chmod +x bin/my_cli_tool

🔹 OptionParser

Built into Ruby for simple tools:

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: my_cli_tool [options]"

  opts.on("-nNAME", "--name=NAME", "Name to greet") do |v|
    options[:name] = v
  end
end.parse!

puts "Hello, #{options[:name]}!"


⸻

🧪 3. Testing

Use RSpec or Minitest to test functionality:

# spec/my_cli_tool_spec.rb
RSpec.describe MyCliTool do
  it "greets the user" do
    expect { MyCliTool::CLI.new.greet("Jane") }.to output("Hello, Jane!\n").to_stdout
  end
end

Run tests with:

rspec


⸻

📦 4. Distribute the Tool

Add a bin entry to your .gemspec:

spec.executables << 'my_cli_tool'

Build and install locally:

gem build my_cli_tool.gemspec
gem install ./my_cli_tool-0.1.0.gem

Then run with:

my_cli_tool greet Alice


⸻

🪪 5. Versioning and Help

Always include:
	•	--version: Show version
	•	--help: Display help message (handled by Thor or OptionParser)

⸻

📋 6. Best Practices Summary

Practice	Recommendation
✅ Structure	Use lib/, bin/, spec/ standard gem structure
✅ CLI Library	Use Thor for subcommands, OptionParser for simple options
✅ Tests	Test CLI and core logic separately
✅ UX	Always provide --help and --version
✅ Packaging	Package as a gem for reuse and easy install
✅ Error Handling	Gracefully handle bad input and provide helpful messages
✅ Documentation	Add a README with installation and usage instructions


⸻
