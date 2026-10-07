# frozen_string_literal: true

require "json"
require "ace/herdr/molecules/bounded_process"
require "timeout"
require "ace/assign/authority/private_directory"

module Ace
  module Lab
    module Molecules
      # Source-owned receiver handler. Permission admission is a separate
      # authority operation; this runner never grants or reconstructs it.
      class ProtectedServiceHandler
        MAX_STDOUT = 16 * 1024
        MAX_STDERR = 8 * 1024

        def execute(operation:, envelope:, candidate_root:)
          unless Process.uid == operation.fetch("executor_uid") && Process.euid == operation.fetch("executor_uid")
            raise SecurityError, "handler executor differs"
          end
          root = Ace::Assign::Authority::PrivateDirectory.verify!(candidate_root)
          result = Ace::Herdr::Molecules::BoundedProcess.call(operation.fetch("argv"),
            stdin_data: JSON.generate(envelope), timeout_s: 30,
            output_limit: MAX_STDOUT, stderr_limit: MAX_STDERR, cleanup_group: true,
            environment: {"PATH" => "/usr/bin:/bin", "LANG" => "C.UTF-8", "HOME" => root}, chdir: root)
          return nil if result.oversized || !result.status.success?
          out = result.stdout
          response = JSON.parse(out)
          request = envelope.fetch("request")
          unless response.is_a?(Hash) && response.keys.sort == %w[evidence input_digest outcome request_id] &&
              response["request_id"] == request.fetch("request_id") && response["input_digest"] == request.fetch("input_digest") &&
              %w[succeeded failed].include?(response["outcome"]) && response["evidence"].is_a?(Array)
            return nil
          end
          response
        rescue JSON::ParserError, Timeout::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError,
          IOError, SystemCallError
          nil
        end
      end
    end
  end
end
