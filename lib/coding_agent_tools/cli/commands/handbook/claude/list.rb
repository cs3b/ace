# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class List < Dry::CLI::Command
            desc "List all Claude commands and their status"

            def call(*)
              puts "list: Not yet implemented"
              puts "This will display all available Claude commands and their current status"
            end
          end
        end
      end
    end
  end
end