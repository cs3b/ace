# frozen_string_literal: true

require "json"
require "openssl"
require "ace/support/cli"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Inbox < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc "Enqueue, inspect, deliver, or reconcile a durable agent inbox event"
          argument :operation, desc: "enqueue, status, deliver, or reconcile"
          option :event, type: :string, desc: "Stable event ID"
          option :attempt, type: :string, desc: "Assignment attempt ID"
          option :ref, type: :string, desc: "Herdr reverse-address JSON file"
          option :file, type: :string, desc: "Payload file"
          option :receipt, type: :string, desc: "Native proof JSON file"
          option :format, type: :string, desc: "Output format (json)"

          def initialize(executor: nil, native: nil)
            @executor = executor
            @native = native
          end

          def call(operation: nil, **options)
            inbox = nil
            translate_errors do
              cli_error("--event is required") if options[:event].to_s.empty?
              cli_error("only --format json is supported") if options[:format] && options[:format] != "json"
              inbox = Organisms::Inbox.new(executor: executor,
                native: @native || Molecules::NativeQueueExecutor.new,
                deliveries_dir: deliveries_dir,
                receipt_public_key: %w[enqueue reconcile].include?(operation) ? receipt_public_key : nil)
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
                bytes = path.to_s.empty? ? nil : File.binread(path)
                receipt = bytes && JSON.parse(bytes)
                signature = bytes && File.binread("#{path}.sig")
                inbox.reconcile(event: options[:event], receipt: receipt,
                  signed_bytes: bytes, signature: signature)
              else
                cli_error("operation must be enqueue, status, deliver, or reconcile")
              end
              puts JSON.generate(result)
            end
          rescue JSON::ParserError, Errno::ENOENT => e
            # Receipt/ref file problems are caller-input errors and surface
            # as an observable refusal; persistence failures are not.
            if operation == "reconcile"
              puts JSON.generate(inbox.status(event: options[:event]).merge(
                "reconciliation_refusal" => "invalid receipt: #{e.message}"))
              return
            end
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def receipt_public_key
            path = config["inbox_receipt_public_key"]
            return nil unless path.is_a?(String) && path.start_with?("/")

            key = OpenSSL::PKey.read(File.read(path))
            key if key.is_a?(OpenSSL::PKey::RSA) && !key.private?
          rescue SystemCallError, OpenSSL::PKey::PKeyError
            nil
          end
        end
      end
    end
  end
end
