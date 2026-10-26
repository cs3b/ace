# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Hitl
    module CLI
      module Commands
        # One-turn ask: create the question, deliver it through the configured
        # adapter routes, block until the answer arrives, and print it. Ask is
        # the LAST action of a turn — the caller resumes from the printed
        # answer; there is no background poll loop to babysit.
        class Ask < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Ask: create, send, and wait for one HITL question; prints the answer"

          example [
            "ask \"Continue with batch 2?\" --to captain --kind approval --question \"Proceed?\"",
            "ask \"Auth strategy?\" --to overseer --task 8xg.t.sbz.1.1 --timeout 3600"
          ]

          argument :title, required: false, desc: "HITL event title"

          option :to, type: :string, required: true, desc: "Configured recipient name (required)"
          option :kind, type: :string, aliases: %w[-k], desc: "Kind: clarification, decision, approval"
          option :question, type: :string, repeat: true, aliases: %w[-Q], desc: "Question line (repeatable)"
          option :task, type: :string, desc: "Task reference"
          option :tags, type: :string, aliases: %w[-T], desc: "Comma-separated tags"

          option :"poll-every", type: :integer, desc: "Polling interval in seconds (default: 600)"
          option :timeout, type: :integer, desc: "Max wait time in seconds (default: 14400)"
          option :scope, type: :string, desc: "Scope (current, all)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title: nil, **options)
            unless title && !title.strip.empty?
              raise Ace::Support::Cli::Error.new("Title required")
            end

            kind = options[:kind]
            validate_kind!(kind) if kind
            validate_scope!(options[:scope])

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = create_question(manager, title, options)
            puts "HITL event created: #{event.id} #{event.title}" unless options[:quiet]

            deliver(event, options)

            result = manager.wait_for_answer(
              event.id,
              scope: options[:scope],
              poll_every: options[:"poll-every"] || 600,
              timeout: options[:timeout] || 14_400,
              waiter: {
                session_id: ENV["ACE_AGENT_SESSION_ID"] || ENV["ACE_SESSION_ID"],
                provider: ENV["ACE_PROVIDER"]
              }
            )

            case result[:status]
            when :answered
              puts "Answer: #{result[:event].answer}"
            when :timeout
              raise Ace::Support::Cli::Error.new(
                "Timed out waiting for HITL event '#{event.id}'"
              )
            else
              raise Ace::Support::Cli::Error.new("HITL event '#{event.id}' vanished while waiting")
            end
          rescue Ace::Hitl::Molecules::HitlAddressResolver::UnknownRecipientError,
            Ace::Hitl::Molecules::HitlAddressResolver::InvalidAddressError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Adapters::Error,
            Ace::Hitl::Molecules::HitlRouteLoader::NoRoutesError,
            Ace::Hitl::Molecules::HitlRouteLoader::InvalidRouteError,
            Ace::Hitl::Lifecycle::StateError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def create_question(manager, title, options)
            manager.create(
              title,
              to: options[:to],
              kind: options[:kind],
              type: "question",
              task: options[:task],
              questions: Array(options[:question]).map(&:strip).reject(&:empty?),
              tags: parse_tags(options[:tags])
            )
          end

          def deliver(event, options)
            report = Organisms::HitlSender.new.send(event.id, scope: options[:scope])
            return if options[:quiet]

            puts "HITL event #{report.event_id} sent through #{report.results.size} route(s):"
            report.results.each do |result|
              detail = result.detail ? " - #{result.detail}" : ""
              puts "  #{result.route} (#{result.adapter}): #{result.status}#{detail}"
            end
            return if report.all_delivered?

            raise Ace::Support::Cli::Error.new(
              "HITL event '#{report.event_id}' not delivered on all routes"
            )
          end

          def validate_kind!(kind)
            allowed = %w[clarification decision approval]
            return if allowed.include?(kind)

            raise Ace::Support::Cli::Error.new("Invalid kind '#{kind}'. Allowed: #{allowed.join(", ")}")
          end

          def validate_scope!(raw_scope)
            return if raw_scope.nil?

            scope = raw_scope.to_s.strip
            allowed = Ace::Hitl::Molecules::WorktreeScopeResolver::VALID_SCOPES
            return if allowed.include?(scope)

            raise Ace::Support::Cli::Error.new("Invalid scope '#{raw_scope}'. Allowed: #{allowed.join(", ")}")
          end

          def parse_tags(raw)
            return [] unless raw

            raw.split(",").map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end
