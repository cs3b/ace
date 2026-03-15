# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          # Top-level shortcut for models search
          class SearchShortcut < Ace::Support::Cli::Command
            include Ace::Core::CLI::Base

            desc "Search models (shortcut for: models search)"

            argument :query, required: false, desc: "Search query"
            option :provider, type: :string, aliases: ["-p"], desc: "Limit to provider"
            option :limit, type: :integer, aliases: ["-l"], default: 20, desc: "Max results"
            option :filter, type: :array, aliases: ["-f"], desc: "Filter by key:value (repeatable)"
            option :json, type: :boolean, desc: "Output as JSON"

            example [
              "gpt-4                     # Search by name",
              "opus -p anthropic         # Search within a provider"
            ]

            def call(query: nil, **options)
              ModelsSubcommands::Search.new.call(query: query, **options)
            end
          end
        end
      end
    end
  end
end
