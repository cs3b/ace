# frozen_string_literal: true
require_relative "protected_submission"

module Ace
  module Assign
    module CLI
      module Commands
        class CampaignExportResult < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Download a verified accepted campaign result through its original authority"
          option :mapping, desc: "Original installed parent mapping"
          option :assignment, desc: "Original parent assignment"
          option :attempt, desc: "Original parent attempt"
          option :head, desc: "Exact parent candidate head"
          option :candidate_generation, desc: "Exact parent candidate counter"
          option :output, desc: "Result byte file (created once, exact retries allowed)"

          def call(**options)
            usage = "campaign-export-result with original parent selectors and --output FILE"
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "Campaign export requires installed authority" unless context
            params = {"assignment_id" => require_option(options, :assignment, usage),
              "attempt_id" => require_option(options, :attempt, usage), "head" => require_option(options, :head, usage),
              "candidate_generation" => integer_option(options, :candidate_generation, usage, positive: true)}
            raise Ace::Support::Cli::Error, "Campaign head must be an exact SHA-1" unless params["head"].match?(/\A[0-9a-f]{40}\z/)
            context.verify_attempt_hints!(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"))
            path = require_option(options, :output, usage)
            reply = context.client(options: options).call("campaign_export_result", params, download: true, purpose: :artifacts, timeout: 30)
            bytes = reply.parts&.first
            unless reply.parts&.size == 1 && bytes.is_a?(String) && bytes.bytesize <= 64 * 1024 &&
                reply.data.values_at("head", "candidate_generation", "bytes", "sha256") ==
                  [params.fetch("head"), params.fetch("candidate_generation"), bytes.bytesize, Digest::SHA256.hexdigest(bytes)]
              raise AttemptErrors::EvidenceUnavailable, "Campaign result download differs"
            end
            begin
              File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
                file.write(bytes)
                file.flush
                file.fsync
              end
            rescue Errno::EEXIST
              raise Ace::Support::Cli::Error, "Existing campaign result file differs" unless input_bytes(path, limit: 64 * 1024) == bytes
            end
            emit_json(reply.data.except("transfer").merge("path" => path))
          rescue SecurityError, Ace::Runtime::RuntimeUnavailableError
            protected_transport_unavailable!
          rescue SystemCallError, IOError
            raise Ace::Support::Cli::Error, "Campaign result file or transport is unavailable"
          end
        end
      end
    end
  end
end
