# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Select an assignment as current (sets .current symlink)
        #
        # @example Select by ID
        #   ace-assign select abc123
        #
        # @example Clear current selection
        #   ace-assign select --clear
        class Select < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Select an assignment as the current active assignment"

          argument :id, required: false, desc: "Assignment ID to select"
          option :clear, type: :boolean, default: false, desc: "Clear current selection (revert to .latest)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(id: nil, **options)
            manager = Molecules::AssignmentManager.new

            if options[:clear]
              manager.clear_current
              puts "Cleared current assignment selection (will use most recent)" unless options[:quiet]
              return
            end

            raise Error, "Assignment ID required. Usage: ace-assign select <id> or ace-assign select --clear" unless id

            assignment = manager.set_current(id)

            unless options[:quiet]
              puts "Selected assignment: #{assignment.name} (#{assignment.id})"
            end
          end
        end
      end
    end
  end
end
