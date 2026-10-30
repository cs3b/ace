# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl reply CASE_ID --stdin` (task 8xs.t.pu0.5): the
        # receiver-side half of HITL answer delivery. Hermes runs this
        # command on the OWNER's machine, in the owner's directory, with
        # a structured payload on stdin — the answer text never becomes
        # a shell command or an argv element. The output names ONLY the
        # case and its state: `{"case": ..., "state": "received"}` (a
        # redelivered identical answer reports `"duplicate"`). Success
        # means ace-hitl CONFIRMED the durable write — a reply frame
        # sitting in a transport is not delivery.
        #
        # Every failure is an explicit non-delivery with no side effects
        # on any other case: an empty answer, a report instead of a
        # question, a conflicting answer, or a reference that is not the
        # EXACT case id (no shortcut or latest resolution) all fail
        # without writing.
        class Reply < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Receive a delivered human answer for one exact case; answer on stdin"

          example [
            'echo "Proceed with batch 2" | ace-hitl reply 8xs.t.ab1 --stdin'
          ]

          argument :case_id, required: true, desc: "Exact HITL case id from the ask"

          option :stdin, type: :boolean, required: true, desc: "Read the answer text from stdin"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(case_id:, stdin: nil, **options)
            unless stdin
              raise Ace::Support::Cli::Error.new("reply reads the answer from stdin; pass --stdin")
            end

            answer = $stdin.read.to_s
            if answer.strip.empty?
              raise Ace::Support::Cli::Error.new("empty answer; nothing was written")
            end

            state = Ace::Hitl::Organisms::HitlManager.new.receive_answer(case_id, answer)
            # Only the case and the outcome — never the answer text.
            puts JSON.generate({"case" => case_id, "state" => state.to_s})
          rescue Ace::Hitl::Organisms::HitlManager::UnknownCaseError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Organisms::HitlManager::NotAnswerableError,
            Ace::Hitl::Organisms::HitlManager::AnswerConflictError => e
            raise Ace::Support::Cli::Error.new("not delivered: #{e.message}")
          end
        end
      end
    end
  end
end
