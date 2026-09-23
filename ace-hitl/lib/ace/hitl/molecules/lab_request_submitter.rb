# frozen_string_literal: true

require "open3"
require "securerandom"
require "json"

module Ace
  module Hitl
    module Molecules
      # Builds and runs the `lab-hitl request` invocation on behalf of a
      # requester. The argv contract is stable: existing required flags
      # first, effect flags in a fixed order (match, args, cwd, timeout).
      # Values pass through verbatim; no answer content or effect argv is
      # ever logged here.
      class LabRequestSubmitter
        DEFAULT_LAB_BIN = "/usr/local/bin/lab-hitl"
        LAB_BIN_ENV = "ACE_HITL_LAB_BIN"

        class SubmissionError < StandardError; end

        def initialize(bin: nil, runner: nil, id_generator: nil)
          @bin = bin || ENV.fetch(LAB_BIN_ENV, DEFAULT_LAB_BIN)
          @runner = runner || ->(argv) { Open3.capture3(*argv) }
          @id_generator = id_generator || -> { "hitl-#{SecureRandom.hex(8)}" }
        end

        def generate_request_id
          @id_generator.call
        end

        def build_argv(request_id:, work:, attempt:, project:, harness:, plan:, question:, ace_hitl_id:,
          match: nil, effect_args: [], effect_cwd: nil, effect_timeout: nil)
          argv = [
            @bin, "request",
            "--id", request_id,
            "--work", work,
            "--attempt", attempt,
            "--project", project,
            "--harness", harness,
            "--plan", plan,
            "--question", question,
            "--ace-hitl-id", ace_hitl_id
          ]
          argv += ["--effect-match", match] if match
          Array(effect_args).each { |arg| argv += ["--effect-arg", arg] }
          argv += ["--effect-cwd", effect_cwd] if effect_cwd
          argv += ["--effect-timeout-s", effect_timeout] if effect_timeout
          argv
        end

        def submit(argv)
          stdout, stderr, status = run(argv)
          unless status.success?
            raise SubmissionError, "lab-hitl request failed (exit #{status.exitstatus}): #{stderr.to_s.strip}"
          end

          parse_request_id(stdout)
        end

        private

        # Distinguishes could-not-execute (missing/unreadable binary,
        # Errno::*) from could-not-parse so failures are actionable.
        def run(argv)
          @runner.call(argv)
        rescue => e
          raise SubmissionError, "could not execute #{@bin}: #{e.class}: #{e.message}"
        end

        def parse_request_id(stdout)
          value = JSON.parse(stdout)
          id = value["id"]
          raise SubmissionError, "lab-hitl request returned no id" if id.nil? || id.to_s.strip.empty?

          id
        rescue JSON::ParserError => e
          raise SubmissionError, "could not parse lab-hitl request output as JSON: #{e.message}"
        end
      end
    end
  end
end
