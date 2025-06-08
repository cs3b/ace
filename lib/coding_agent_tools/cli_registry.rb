# frozen_string_literal: true

# This file handles the registration of CLI commands after they are loaded
# This avoids circular dependency issues with autoloading

require_relative "cli"

# Load LLM commands
require_relative "cli/commands/llm/query"

# Register LLM commands
CodingAgentTools::Cli::Commands.register "llm", aliases: [] do |prefix|
  prefix.register "query", CodingAgentTools::Cli::Commands::LLM::Query
end

# Future command registrations will go here
# Example:
# require_relative "cli/commands/git/commit"
# CodingAgentTools::Cli::Commands.register "git", aliases: [] do |prefix|
#   prefix.register "commit", CodingAgentTools::Cli::Commands::Git::Commit
# end
