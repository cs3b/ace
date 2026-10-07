# frozen_string_literal: true

require "json"

module Ace
  module Assign
    module CLI
      module Commands
        class Resume < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget
          desc "Recover accepted assignment state without launching another writer"
          option :assignment, desc: "Assignment ID"
          option :mapping, desc: "Installed protected launch mapping ID"
          option :attempt, desc: "Original protected attempt ID"
          option :dry_run, type: :boolean, default: false, desc: "Inspect recovery without writing observations"

          def call(**options)
            target = resolve_assignment_target(options)
            if target.prepared_input
              raise Ace::Support::Cli::Error, "protected resume only supports --dry-run" unless options[:dry_run]
              result = build_executor_for_target(target).status
              descriptor = target.prepared_input.descriptor
              puts JSON.generate(descriptor.slice("assignment_id", "mapping_id", "attempt_id", "scope", "definition_digest", "selection_sha256").merge(
                "state" => result.fetch(:state).assignment_state.to_s, "dry_run" => true))
              return
            end
            id = options[:assignment].to_s.strip
            raise Ace::Support::Cli::Error, "--assignment ID is required" if id.empty?

            puts JSON.generate(Organisms::AttemptCoordinator.new.resume(
              assignment_id: id, dry_run: options[:dry_run]))
          end
        end
      end
    end
  end
end
