# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class UpdateRegistry < Dry::CLI::Command
            desc "Update commands.json registry with new commands"

            def call(*)
              puts "update-registry: Not yet implemented"
              puts "This will update the commands.json file with newly discovered commands"
            end
          end
        end
      end
    end
  end
end