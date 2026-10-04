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

        end
      end
    end
  end
end
