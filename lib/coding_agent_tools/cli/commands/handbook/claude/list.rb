# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/claude_command_lister"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class List < Dry::CLI::Command
            desc "List all Claude commands and their status"

            option :verbose, type: :boolean, default: false, desc: "Show detailed information"
            option :type, type: :string, values: %w[custom generated missing all], default: "all", desc: "Filter by type"
            option :format, type: :string, values: %w[text json], default: "text", desc: "Output format"

            def call(**options)
              lister = CodingAgentTools::Organisms::ClaudeCommandLister.new
              lister.list(options)
            rescue StandardError => e
              warn "Error: #{e.message}"
              exit 1
            end
          end
        end
      end
    end
  end
end