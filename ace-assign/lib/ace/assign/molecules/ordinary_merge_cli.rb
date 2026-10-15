# frozen_string_literal: true

require "json"
require "open3"
require_relative "../errors"

module Ace
  module Assign
    module Molecules
      # Invokes the maintained ordinary fixed merge producer through the
      # installed `ace-lab service request/status --mode ordinary-merge`
      # CLI. The argv is closed: no shell, no caller-selected executable,
      # socket, evidence path or token selector beyond the published request
      # form. Output is bounded and parsed as one strict JSON envelope.
      #
      # Any local execution, framing or parse failure raises
      # UnavailableError: a caller-side blocker that never proves refusal
      # and never authorizes resubmission.
      class OrdinaryMergeCli
        MAX_OUTPUT_BYTES = 16 * 1024

        # Raised when no maintained producer response is obtainable before
        # the envelope could be observed. Maps to the closed
        # `ordinary_merge_unavailable` caller-side blocker.
        class UnavailableError < Ace::Assign::AttemptErrors::EvidenceUnavailable
          def initialize(message = "ordinary merge producer response unavailable")
            super
          end
        end

        def initialize(binary: "ace-lab")
          @binary = binary
        end

        def request(project:, assignment:, attempt:, queue_entry:, input_path:, authorization:, request_id:)
          run(["service", "request", "--mode", "ordinary-merge",
            "--project", project, "--assignment", assignment, "--attempt", attempt,
            "--queue-entry", queue_entry, "--operation", "merge", "--input", input_path,
            "--authorization", authorization, "--request-id", request_id])
        end

        def status(reference:, request_id:, project:, assignment:, attempt:, queue_entry:, input_digest:)
          run(["service", "status", "--mode", "ordinary-merge", "--reference", reference,
            "--request", request_id, "--project", project, "--assignment", assignment,
            "--attempt", attempt, "--queue-entry", queue_entry,
            "--input-digest", input_digest, "--format", "json"])
        end

        private

        def run(arguments)
          output, = Open3.capture3(@binary, *arguments)
          raise UnavailableError, "ordinary merge producer output is missing or exceeds its bound" unless
            output.is_a?(String) && !output.empty? && output.bytesize <= MAX_OUTPUT_BYTES
          envelope = JSON.parse(output, max_nesting: 16, create_additions: false,
            allow_duplicate_key: false, allow_comments: false, allow_nan: false)
          unless envelope.is_a?(Hash) && envelope["status"].is_a?(String) &&
              (envelope.keys - %w[status data error]).empty?
            raise UnavailableError, "ordinary merge producer output is not a maintained envelope"
          end
          envelope
        rescue JSON::ParserError, SystemCallError
          raise UnavailableError, "ordinary merge producer response unavailable"
        end
      end
    end
  end
end
