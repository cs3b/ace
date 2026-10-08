# frozen_string_literal: true
require_relative "protected_submission"

module Ace
  module Assign
    module CLI
      module Commands
        class InboxReconcile < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Verify a Herdr inbox proof and record its references in the assignment journal"
          option :mapping, desc: "Installed protected mapping"
          option :assignment, desc: "Original assignment"
          option :inbox_context, desc: "Installed Inbox context"
          option :mutation, desc: "Stable original mutation"
          option :expected_generation, desc: "Original authority generation"
          option :registration, desc: "Saved canonical bind registration JSON"
          option :signature, desc: "Detached signature byte file"
          option :attempt, desc: "Exact attempt ID"
          option :event, desc: "Herdr inbox event ID"
          option :receipt, desc: "Existing native receipt JSON file with detached FILE.sig"

          def initialize(coordinator: nil, inbox: nil)
            super()
            @coordinator = coordinator
            @inbox = inbox
          end

          def call(**options)
            context = protected_context(options)
            if context
              usage = "inbox-reconcile with original protected selectors and registration/receipt/signature files"
              client, params, mutation = protected_attempt_request(context, options, usage)
              registration = input_json(input_bytes(require_option(options, :registration, usage), limit: 16 * 1024))
              unless registration.is_a?(Hash) && registration.keys.sort == %w[attempt_id event_id payload_sha256 receipt_key_sha256] &&
                  registration.values.all? { |value| value.is_a?(String) } &&
                  %w[payload_sha256 receipt_key_sha256].all? { |key| registration.fetch(key).match?(/\A[0-9a-f]{64}\z/) }
                raise Ace::Support::Cli::Error, "Registration schema is invalid"
              end
              event = require_option(options, :event, usage)
              unless registration.values_at("attempt_id", "event_id") == [params.fetch("attempt_id"), event]
                raise Ace::Support::Cli::Error, "Registration selectors differ"
              end
              receipt = input_bytes(require_option(options, :receipt, usage), limit: 16 * 1024)
              raise Ace::Support::Cli::Error, "Inbox receipt must be a JSON object" unless input_json(receipt).is_a?(Hash)
              signature = input_bytes(require_option(options, :signature, usage), limit: 16 * 1024)
              params.merge!("event_id" => event, "inbox_context_id" => require_option(options, :inbox_context, usage),
                "expected_registration" => registration, "receipt_sha256" => Digest::SHA256.hexdigest(receipt),
                "signature_sha256" => Digest::SHA256.hexdigest(signature))
              return emit_json(upload_call(client, "reconcile_inbox", params, mutation, [receipt, signature], :inbox_proof))
            end
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
