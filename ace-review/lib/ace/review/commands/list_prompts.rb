# frozen_string_literal: true

require_relative "list_prompts_command"

module Ace
  module Review
    module Commands
      # dry-cli Command class for the list-prompts command
      #
      # This wraps the existing ListPromptsCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class ListPrompts < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List all available prompt modules by category"

        example [
          '# List all prompt modules'
        ]

        def call(**options)
          # Use the existing ListPromptsCommand logic
          ListPromptsCommand.new.execute
        end
      end
    end
  end
end
