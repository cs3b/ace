#!/usr/bin/env ruby
# frozen_string_literal: true

# [Command Name] - [Brief description]
#
# This executable provides [detailed description of functionality].
# [Additional context and purpose].
#
# Usage: [command-name] [ARGUMENTS] [OPTIONS]
#
# Examples:
#   [command-name] --help
#   [command-name] example-input
#   [command-name] example-input --option value
#
# Arguments:
#   [argument]      [Description of argument]
#
# Options:
#   --option        [Description of option]
#   --flag          [Description of boolean flag]

# Use absolute path resolution to support execution from any directory
lib_path = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require "coding_agent_tools/molecules/executable_wrapper"

CodingAgentTools::Molecules::ExecutableWrapper.new(
  command_path: ["command", "subcommand"],        # Array of command path segments
  registration_method: :register_xxx_commands,   # Optional: method to register commands
  executable_name: "command-name"                # Optional: name for error reporting
).call

# Template Instructions:
#
# 1. Replace [Command Name] with the actual command name
# 2. Replace [Brief description] with a concise description
# 3. Update the detailed description and purpose
# 4. Modify the usage examples to match your command
# 5. Update the command_path array to match your CLI command structure
# 6. Set the appropriate registration_method if needed
# 7. Set the executable_name to match the filename
# 8. Ensure the corresponding CLI command class exists in lib/coding_agent_tools/cli/commands/
# 9. Register the command in the appropriate registration method in lib/coding_agent_tools/cli.rb
#
# Example command_path mappings:
#   - ["task", "next"] for task-manager next
#   - ["nav", "ls"] for nav-ls
#   - ["git", "commit"] for git-commit
#   - ["code", "review"] for code-review
#
# Standard ExecutableWrapper Pattern Benefits:
#   - Consistent error handling across all executables
#   - Automatic dry-cli integration
#   - Unified help system
#   - Proper load path management
#   - Standard command registration
