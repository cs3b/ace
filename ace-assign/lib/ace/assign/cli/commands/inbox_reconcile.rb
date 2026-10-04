# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        class InboxReconcile < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Verify a Herdr inbox proof and record its references in the assignment journal"
          option :attempt, desc: "Exact attempt ID"
          option :event, desc: "Herdr inbox event ID"
          option :receipt, desc: "Existing native receipt JSON file with detached FILE.sig"

          def initialize(coordinator: nil, inbox: nil)
            super()
            @coordinator = coordinator
            @inbox = inbox
          end

          def call(**options)
            %i[attempt event receipt].each do |key|
              raise Ace::Support::Cli::Error, "--#{key} is required" if options[key].to_s.strip.empty?
            end
            result = (@coordinator || Organisms::AttemptCoordinator.new).reconcile_inbox(
              attempt_id: options[:attempt], event_id: options[:event], receipt_path: options[:receipt],
              inbox: @inbox || Ace::Herdr::Organisms::Inbox.from_config)
            # Keep the public projection bounded; raw native output and the
            # human observation text belong to the existing receipt file.
            puts JSON.generate(result.slice("event_id", "attempt_id", "state", "claim_generation",
              "receipt_key_sha256", "reconciliation_refusal"))
          end
        end
      end
    end
  end
end
