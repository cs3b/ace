# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          # Top-level shortcut for models info
          class InfoShortcut < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc "Show model info (shortcut for: models info)"

            argument :model_id, required: true, desc: "Model ID (provider:model)"
            option :full, type: :boolean, desc: "Show complete details"
            option :json, type: :boolean, desc: "Output as JSON"

            example [
              "openai:gpt-4o            # Brief info",
              "openai:gpt-4o --full     # Full details"
            ]

            def call(model_id:, **options)
              ModelsSubcommands::Info.new.call(model_id: model_id, **options)
            end
          end
        end
      end
    end
  end
end
