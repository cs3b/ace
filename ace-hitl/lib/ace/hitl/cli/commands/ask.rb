# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"
require "ace/support/cli"

module Ace
  module Hitl
    module CLI
      module Commands
        # One-turn ask: create the question, deliver it through the configured
        # adapter routes, arm the asking agent's own wake for the case answer,
        # and END THE TURN. ask never blocks and never polls: the answer is
        # delivered TO the agent as an ace-wake wake carrying the content, and
        # the agent acts on it immediately. Asks carry no urgency language and
        # no asker-side timeouts — the Captain replies whenever he wants.
        class Ask < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          # Shared with ace-wake's ask bridge (wake/ask-bridge.js): the drop-file
          # contract that arms the asking agent's scoped answer watch.
          WAKE_REQUEST_SCHEMA = "ace.wake.ask/v1"

          desc "Ask: create, send, arm the answer wake, and end the turn"

          example [
            "ask \"Continue with batch 2?\" --to captain --kind approval --question \"Proceed?\"",
            "ask \"Auth strategy?\" --to overseer --task 8xg.t.sbz.1.1"
          ]

          argument :title, required: false, desc: "HITL event title"

          option :to, type: :string, required: true, desc: "Configured recipient name (required)"
          option :kind, type: :string, aliases: %w[-k], desc: "Kind: clarification, decision, approval"
          option :question, type: :string, repeat: true, aliases: %w[-Q], desc: "Question line (repeatable)"
          option :task, type: :string, desc: "Task reference"
          option :tags, type: :string, aliases: %w[-T], desc: "Comma-separated tags"
          option :secret, type: :boolean, default: false,
            desc: "The expected answer is a secret (e.g. OTP): the wake carries the case reference only, never the value"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title: nil, **options)
            unless title && !title.strip.empty?
              raise Ace::Support::Cli::Error.new("Title required")
            end

            kind = options[:kind]
            validate_kind!(kind) if kind

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = create_question(manager, title, options)
            unless options[:quiet]
              puts "HITL event created: #{event.id} #{event.title}"
            end

            deliver(event, options)
            arm_wake(event, manager)
            # The final stdout line is always the bare case id.
            puts event.id
          rescue Ace::Hitl::Molecules::HitlAddressResolver::UnknownRecipientError,
            Ace::Hitl::Molecules::HitlAddressResolver::InvalidAddressError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Adapters::Error,
            Ace::Hitl::Molecules::HitlRouteLoader::NoRoutesError,
            Ace::Hitl::Molecules::HitlRouteLoader::InvalidRouteError => e
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
              tags: parse_tags(options[:tags]),
              secret: options[:secret] == true
            )
          end

          def deliver(event, options)
            report = Organisms::HitlSender.new.send(event.id)
            rejected = report.results.select { |result| result.status == :failed }
            unless rejected.empty?
              # A genuine reject (ContractError, unknown adapter): the frame
              # never went through, so arming a wake would strand the ask.
              detail = rejected.map { |result| "#{result.route}: #{result.detail}" }.join("; ")
              raise Ace::Support::Cli::Error.new("HITL event '#{event.id}' rejected: #{detail}")
            end
            unless options[:quiet]
              puts "HITL event #{report.event_id} sent through #{report.results.size} route(s):"
              report.results.each do |result|
                detail = result.detail ? " - #{result.detail}" : ""
                puts "  #{result.route} (#{result.adapter}): #{result.status}#{detail}"
              end
            end
            # Native-style transports accept first and confirm later: an
            # ACCEPTED QUEUED frame is ask-complete. The answer wake fires
            # whenever the transport confirms — delivered-later states are
            # asynchronous, never an asker-side failure.
            queued = report.results.select { |result| result.status == :unavailable }
            unless queued.empty?
              warn "ace-hitl: warning: delivery unconfirmed (queued on " \
                "#{queued.map { |result| result.route }.join(", ")}); the answer wake fires when the transport delivers"
            end
          end

          # Drop the wake request the ace-wake extension consumes through its
          # own reconcile pass and turns into a scoped watch on the case file:
          # when the answer lands, the wake carries the answer content —
          # EXCEPT for a secret ask (8xs.t.pu0.9), where the wake carries the
          # case reference only and the executor reads the value from the
          # case file through its secure channel. The atomic replace keeps
          # the consumer from reading a torn request.
          def arm_wake(event, manager)
            requests_dir = File.join(File.expand_path(manager.root_dir), "wake-requests")
            FileUtils.mkdir_p(requests_dir)
            request = {
              "schema" => WAKE_REQUEST_SCHEMA,
              "kind" => "ask",
              "case_id" => event.id,
              "case_path" => File.expand_path(event.file_path)
            }
            request["secret"] = true if event.metadata["secret"] == true
            temporary = File.join(requests_dir, ".#{event.id}-#{SecureRandom.hex(8)}.tmp")
            final = File.join(requests_dir, "#{event.id}.json")
            File.write(temporary, JSON.generate(request))
            File.rename(temporary, final)
            final
          ensure
            File.unlink(temporary) if temporary && File.exist?(temporary)
          end

          def validate_kind!(kind)
            allowed = %w[clarification decision approval]
            return if allowed.include?(kind)

            raise Ace::Support::Cli::Error.new("Invalid kind '#{kind}'. Allowed: #{allowed.join(", ")}")
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
