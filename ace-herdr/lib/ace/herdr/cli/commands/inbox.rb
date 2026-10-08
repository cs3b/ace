# frozen_string_literal: true

require "json"
require "openssl"
require "ace/support/cli"
require_relative "support"
require_relative "../../molecules/protected_inbox_selection"
require_relative "../../molecules/inbox_context_client"
require_relative "../../molecules/inbox_cli_input"
require_relative "../../molecules/inbox_direct_effect_binding"
require_relative "../../molecules/inbox_reconciliation_client"

module Ace
  module Herdr
    module CLI
      module Commands
        class Inbox < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc "Enqueue, inspect, deliver, observe, or reconcile a durable agent inbox event"
          argument :operation, desc: "enqueue, status, deliver, observe, or reconcile"
          option :project, type: :string, desc: "Installed project ID"
          option :mapping, type: :string, desc: "Installed mapping ID"
          option :inbox_context, type: :string, desc: "Installed inbox context ID"
          option :claim_generation, type: :integer, desc: "Original expected claim generation"
          option :assignment, type: :string, desc: "Original assignment ID"
          option :mutation, type: :string, desc: "Stable reconciliation mutation ID"
          option :expected_generation, type: :integer, desc: "Original expected authority generation"
          option :receipt_key_sha256, type: :string, desc: "Original registered receipt-key digest"
          option :event, type: :string, desc: "Stable event ID"
          option :attempt, type: :string, desc: "Assignment attempt ID"
          option :ref, type: :string, desc: "Herdr reverse-address JSON file"
          option :file, type: :string, desc: "Payload file"
          option :receipt, type: :string, desc: "Native proof JSON file"
          option :format, type: :string, desc: "Output format (json)"

          def initialize(executor: nil, native: nil, selection: Molecules::ProtectedInboxSelection.new,
            context_client_factory: Molecules::InboxContextClient.method(:selected), reconciliation_client_factory: Molecules::InboxReconciliationClient.method(:new),
            kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
            @executor = executor
            @native = native
            @selection, @context_client_factory, @kernel = selection, context_client_factory, kernel
            @reconciliation_client_factory = reconciliation_client_factory
          end

          def call(operation: nil, **options)
            inbox = nil
            translate_errors do
              cli_error("--event is required") if options[:event].to_s.empty?
              cli_error("only --format json is supported") if options[:format] && options[:format] != "json"
              if operation == "observe"
                %i[project mapping inbox_context event attempt assignment].each do |key|
                  cli_error("--#{key.to_s.tr('_', '-')} must be explicit") unless options[key].is_a?(String) && Molecules::ProtectedInboxSelection::TOKEN.match?(options[key])
                end
                cli_error("--claim-generation must be an explicit positive integer") unless options[:claim_generation].is_a?(Integer) && options[:claim_generation].positive?
              end
              protected = false
              @selection.with(options) do |selected|
                next unless selected
                puts JSON.generate(protected_call(operation, options, selected))
                protected = true
              end
              next if protected
              cli_error("observe requires an installed protected inbox selection") if operation == "observe"
              inbox = Organisms::Inbox.from_config(config: config, executor: executor,
                native: @native || Molecules::NativeQueueExecutor.new,
                root: Dir.pwd)
              result = case operation
              when "enqueue"
                %i[attempt ref file].each { |key| cli_error("--#{key} is required") if options[key].to_s.empty? }
                inbox.enqueue(event: options[:event], attempt: options[:attempt],
                  ref: options[:ref], payload: File.binread(options[:file]))
              when "status"
                inbox.status(event: options[:event])
              when "deliver"
                inbox.deliver(event: options[:event])
              when "reconcile"
                path = options[:receipt]
                begin
                  bytes = path.to_s.empty? ? nil : File.binread(path)
                  receipt = bytes && JSON.parse(bytes)
                  signature = bytes && File.binread("#{path}.sig")
                rescue SystemCallError, JSON::ParserError => e
                  # Receipt input is caller-owned: unreadable or malformed
                  # proof files surface as the documented refusal, never as
                  # command failures.
                  puts JSON.generate(inbox.status(event: options[:event]).merge(
                    "reconciliation_refusal" => "invalid receipt: #{e.message}"))
                  return
                end
                inbox.reconcile(event: options[:event], receipt: receipt,
                  signed_bytes: bytes, signature: signature)
              else
                cli_error("operation must be enqueue, status, deliver, or reconcile")
              end
              puts JSON.generate(result)
            end
          rescue Errno::ENOENT, JSON::ParserError => e
            raise Ace::Support::Cli::Error, e.message
          end


          private

          def protected_call(operation, options, selected)
            %i[event attempt assignment].each { |key| cli_error("--#{key} is required") if options[key].to_s.empty? }
            unless %w[enqueue status deliver observe reconcile].include?(operation)
              cli_error("protected operation requires its maintained direct handler")
            end
            allowed = %i[project mapping inbox_context event attempt assignment format]
            allowed += %i[ref file] if operation == "enqueue"
            allowed += %i[claim_generation] if %w[deliver observe].include?(operation)
            allowed += %i[assignment mutation expected_generation receipt_key_sha256 receipt] if operation == "reconcile"
            if options.any? { |key, value| !value.nil? && !allowed.include?(key) }
              cli_error("protected inbox operation options differ")
            end
            if operation == "reconcile"
              %i[assignment mutation receipt_key_sha256 receipt].each { |key| cli_error("--#{key.to_s.tr('_', '-')} is required") if options[key].to_s.empty? }
              unless options[:expected_generation].is_a?(Integer) && options[:expected_generation] >= 0
                cli_error("--expected-generation must be an explicit nonnegative integer")
              end
              signed_bytes = Molecules::InboxCliInput.read(options.fetch(:receipt), limit: 16_384)
              signature = Molecules::InboxCliInput.read("#{options.fetch(:receipt)}.sig", limit: 16_384)
              return @reconciliation_client_factory.call(selection: selected).reconcile(assignment_id: options.fetch(:assignment),
                mutation_id: options.fetch(:mutation), expected_generation: options.fetch(:expected_generation), event_id: options.fetch(:event),
                attempt_id: options.fetch(:attempt), receipt_key_sha256: options.fetch(:receipt_key_sha256), signed_bytes: signed_bytes, signature: signature)
            end
            context = selected.fetch("context")
            client = @context_client_factory.call(context_id: selected.fetch("inbox_context_id"),
              socket_path: context.fetch("control_socket_path"), owner_credentials: context.fetch("owner_credentials"))
            return protected_observe(client, selected, options) if operation == "observe"
            if operation == "status"
              return client.request("status_context", {"event_id" => options.fetch(:event), "attempt_id" => options.fetch(:attempt), "original" => direct_original(selected, options)}).fetch("record")
            end
            if operation == "deliver"
              unless options[:claim_generation].is_a?(Integer) && options[:claim_generation] >= 0
                cli_error("--claim-generation must be an explicit nonnegative integer")
              end
              admission = direct_admission(client, selected, options, "deliver")
              result = client.request("deliver_context", {"operation_id" => admission.fetch("operation_id"),
                "key_generation" => admission.fetch("key_generation"), "event_id" => options.fetch(:event),
                "attempt_id" => options.fetch(:attempt), "original" => direct_original(selected, options), "expected_claim_generation" => options.fetch(:claim_generation)})
              unless %w[idle unknown].include?(result["admission_state"])
                cli_error("direct delivery admission observation differs")
              end
              client.request("end_context_operation", {"operation_id" => admission.fetch("operation_id")}) if result.fetch("admission_state") == "idle"
              return result.fetch("record").merge("admission_state" => result.fetch("admission_state"))
            end
            %i[ref file].each { |key| cli_error("--#{key} is required") if options[key].to_s.empty? }
            reverse = Molecules::InboxCliInput.reverse(options.fetch(:ref))
            payload = Molecules::InboxCliInput.read(options.fetch(:file), limit: 65_536).dup.force_encoding(Encoding::UTF_8)
            cli_error("payload encoding differs") unless payload.valid_encoding? && !payload.include?("\0")
            admission = direct_admission(client, selected, options, "enqueue")
            result = client.request("enqueue_context", {"operation_id" => admission.fetch("operation_id"),
              "key_generation" => admission.fetch("key_generation"), "event_id" => options.fetch(:event),
              "attempt_id" => options.fetch(:attempt), "original" => direct_original(selected, options), "reverse" => reverse, "payload_bytes" => payload.bytesize,
              "payload_sha256" => Digest::SHA256.hexdigest(payload)}, payload: payload)
            client.request("end_context_operation", {"operation_id" => admission.fetch("operation_id")})
            result.fetch("record").merge("admission_state" => result.fetch("admission_state"))
          end

          def direct_original(selected, options)
            value = selected.slice("project_id", "mapping_id", "inbox_context_id").merge("assignment_id" => options.fetch(:assignment))
            Molecules::InboxDirectEffectBinding.original!(value)
          end

          def protected_observe(client, selected, options)
            original = direct_original(selected, options)
            status = client.request("status_context", {"event_id" => options.fetch(:event),
              "attempt_id" => options.fetch(:attempt), "original" => original}).fetch("record")
            unless status["claim_generation"] == options.fetch(:claim_generation)
              cli_error("observation retained claim generation differs")
            end
            admission = client.request("begin_context_operation", {"context_id" => selected.fetch("inbox_context_id"),
              "purpose" => "observe_to_sign", "event_id" => options.fetch(:event), "process_binding" => @kernel.capture(Process.pid)})
            unless admission.is_a?(Hash) && admission.keys.sort == %w[fingerprint key_generation operation_id state] &&
                admission["state"] == "admitted" && admission["operation_id"].is_a?(String) && admission["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
                admission["key_generation"].is_a?(Integer) && admission["key_generation"].positive? &&
                admission["fingerprint"] == status.fetch("receipt_key_sha256")
              cli_error("observation admission differs")
            end
            params = admission.slice("operation_id", "key_generation").merge("event_id" => options.fetch(:event),
              "attempt_id" => options.fetch(:attempt), "claim_generation" => options.fetch(:claim_generation))
            result = client.request("observe_context", params)
            unless result.is_a?(Hash) && result.keys.sort == %w[attempt_id binding claim_generation context_id event_id key_generation observation operation_id payload_sha256] &&
                result.slice(*params.keys) == params && result["context_id"] == selected.fetch("inbox_context_id") &&
                result["payload_sha256"] == status.fetch("payload_sha256") && result["binding"] == status.fetch("binding") &&
                observation_candidate?(result["observation"], status)
              cli_error("observation candidate association differs")
            end
            # A second same-selection read refuses record drift before releasing the admission.
            current = client.request("status_context", {"event_id" => options.fetch(:event),
              "attempt_id" => options.fetch(:attempt), "original" => original}).fetch("record")
            cli_error("observation retained selection changed") unless current == status
            ended = client.request("end_context_operation", admission.slice("operation_id"))
            cli_error("observation admission end is unconfirmed") unless ended == {"operation_id" => admission.fetch("operation_id"), "state" => "ended"}
            result.merge("candidate" => true)
          end

          def observation_candidate?(value, status)
            return false unless value.is_a?(Hash)
            return value == {"outcome" => "uncertain"} if value["outcome"] == "uncertain"
            reference = value["native_reference"]
            uuid = /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i
            value.keys.sort == %w[endpoint_reference_sha256 native_reference outcome server_process_binding] &&
              value["outcome"] == "consumed" && status.dig("binding", "agent") == "codex" && reference.is_a?(Hash) &&
              reference.keys.sort == %w[client_user_message_id item_id payload_sha256 provider queued_submission_id thread_id turn_id version] &&
              reference.values_at("provider", "version", "thread_id", "payload_sha256") ==
                ["codex", "0.159.3", status.dig("binding", "thread"), status["payload_sha256"]] &&
              reference["client_user_message_id"].is_a?(String) && reference["client_user_message_id"].match?(/\Aace-[0-9a-f]{32}\z/) &&
              reference["turn_id"].is_a?(String) && uuid.match?(reference["turn_id"]) &&
              (reference["queued_submission_id"].nil? || reference["queued_submission_id"].is_a?(String) && uuid.match?(reference["queued_submission_id"])) &&
              reference["item_id"].is_a?(String) && reference["item_id"].valid_encoding? &&
              reference["item_id"].bytesize.between?(1, 256) && !reference["item_id"].include?("\0") &&
              value["endpoint_reference_sha256"].is_a?(String) && value["endpoint_reference_sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              value["server_process_binding"].is_a?(Hash)
          end

          def direct_admission(client, selected, options, purpose)
            peer = @kernel.capture(Process.pid)
            client.request("begin_context_operation", {"context_id" => selected.fetch("inbox_context_id"),
              "purpose" => purpose, "event_id" => options.fetch(:event), "process_binding" => peer,
              "original" => direct_original(selected, options).merge("attempt_id" => options.fetch(:attempt))})
          end

        end
      end
    end
  end
end
