# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        class Wait < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Wait for a specific HITL event answer (polling default)"

          argument :ref, required: false, desc: "HITL reference (full ID or shortcut)"

          option :request, type: :string, desc: "Exact scoped request id for pane-less authenticated waiting"
          option :operation, type: :string, desc: "Authorized operation for OTP consumption"

          option :"poll-every", type: :integer, desc: "Polling interval in seconds (default: 600)"
          option :timeout, type: :integer, desc: "Max wait time in seconds (default: 14400)"
          option :scope, type: :string, desc: "Scope (current, all)"
          option :"session-id", type: :string, desc: "Waiter session id (optional)"
          option :provider, type: :string, desc: "Waiter provider (optional)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref: nil, **options)
            if options[:request]
              raise_lifecycle_error("Choose an event reference or --request, not both") if ref
              emit(Ace::Hitl::LiveClient.new(boundary: lifecycle_client).wait(
                request: options[:request], timeout: options[:timeout] || 0, operation: options[:operation]))
              return
            end
            raise_lifecycle_error("An event reference or --request is required") unless ref
            scope = validate_scope(options[:scope])
            poll_every = options[:"poll-every"] || 600
            timeout = options[:timeout] || 14_400

            waiter = {
              session_id: options[:"session-id"] || ENV["ACE_AGENT_SESSION_ID"] || ENV["ACE_SESSION_ID"],
              provider: options[:provider] || ENV["ACE_PROVIDER"]
            }

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = manager.show(ref, scope: scope)&.dig(:event)
            if event && event.metadata["lab_request_id"]
              emit(Ace::Hitl::LiveClient.new(boundary: lifecycle_client).wait(
                request: event.metadata.fetch("lab_request_id"), timeout: options[:timeout] || 0,
                operation: options[:operation]))
              return
            end
            result = manager.wait_for_answer(
              ref,
              scope: scope,
              poll_every: poll_every,
              timeout: timeout,
              waiter: waiter
            )

            case result[:status]
            when :answered
              event = result[:event]
              puts "HITL event answered: #{event.id} #{event.title}"
              puts "Answer: #{event.answer}"
              resume = event.metadata["resume_instructions"]
              puts "Resume: #{resume}" if resume
            when :timeout
              raise Ace::Support::Cli::Error.new("Timed out waiting for HITL event '#{ref}'")
            else
              raise Ace::Support::Cli::Error.new("HITL event '#{ref}' not found")
            end
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end

          private

          def validate_scope(raw_scope)
            return nil if raw_scope.nil?

            scope = raw_scope.to_s.strip
            allowed = Ace::Hitl::Molecules::WorktreeScopeResolver::VALID_SCOPES
            return scope if allowed.include?(scope)

            raise Ace::Support::Cli::Error.new("Invalid scope '#{raw_scope}'. Allowed: #{allowed.join(", ")}")
          end
        end
      end
    end
  end
end
