# frozen_string_literal: true

require "json"

module Ace
  module Assign
    module CLI
      module Commands
        class Resume < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Recover accepted assignment state without launching another writer"
          option :assignment, desc: "Assignment ID"
          option :dry_run, type: :boolean, default: false, desc: "Inspect recovery without writing observations"

          def call(**options)
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
