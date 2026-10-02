# frozen_string_literal: true

require "json"
require "open3"
require "socket"
require "timeout"
require "time"

module Ace
  module Lab
    module Molecules
      # Executes one fixed, deployment-configured argv under its OS account.
      # Domain handlers receive structured JSON on stdin and return a small
      # receipt; their stdout/stderr are never journaled or returned to callers.
      class ServiceExecutor
        # The trusted policy is reloaded through +policy_loader+ immediately
        # before the effect: a revocation or operation change after the claim
        # must still stop dispatch.
        def execute(operation:, request:, input:, policy_loader:, authorization:)
          fresh = policy_loader.call
          current = fresh.operation!(request.fetch("operation"), project: request.fetch("project_id"),
            service_id: request.fetch("service_id"))
          raise SecurityError, "executor operation changed before dispatch" unless current == operation
          fresh.authorize!(authorization, request)
          if Time.iso8601(current.fetch("lease_expires_at")) <= Time.now.utc
            raise SecurityError, "executor lease has expired"
          end
          out = if operation.fetch("transport", "local") == "unix"
            invoke_unix(operation, request, input)
          else
            invoke_local(operation, request, input)
          end
          return nil unless out && out.bytesize <= 16 * 1024
          response = JSON.parse(out)
          return nil unless valid_response?(response, request)
          {"outcome" => response.fetch("outcome"), "evidence" => response.fetch("evidence"),
           "executor_uid" => current.fetch("executor_uid")}
        rescue JSON::ParserError, Errno::ENOENT, Errno::EACCES, Errno::ECONNREFUSED, EOFError, Timeout::Error
          nil
        end

        private

        def invoke_local(operation, request, input)
          unless Process.uid == operation.fetch("executor_uid") && Process.euid == operation.fetch("executor_uid")
            raise SecurityError, "current OS identity is not the configured executor"
          end
          out, _stderr, status = Timeout.timeout(30) do
            Open3.capture3(*operation.fetch("argv"),
              stdin_data: JSON.generate({"request" => request, "input" => input}))
          end
          status.success? ? out : nil
        end

        def invoke_unix(operation, request, input)
          path = operation.fetch("socket_path")
          stat = File.lstat(path)
          unless stat.socket? && stat.uid == operation.fetch("executor_uid") && (stat.mode & 0o002).zero?
            raise SecurityError, "service socket owner or permissions do not match the executor"
          end
          UNIXSocket.open(path) do |socket|
            peer_uid, = socket.getpeereid
            raise SecurityError, "service peer identity does not match the executor" unless peer_uid == stat.uid
            socket.write(JSON.generate({"request" => request, "input" => input}) + "\n")
            socket.flush
            Timeout.timeout(30) { socket.gets(16 * 1024 + 1) }
          end
        end

        def valid_response?(response, request)
          response.is_a?(Hash) && response.keys.sort == %w[evidence input_digest outcome request_id] &&
            response["request_id"] == request["request_id"] &&
            response["input_digest"] == request["input_digest"] &&
            %w[succeeded failed].include?(response["outcome"]) &&
            response["evidence"].is_a?(Array) && !response["evidence"].empty? &&
            response["evidence"].all? do |item|
              item.is_a?(Hash) && item.keys.sort == %w[ref sha256] &&
                item["ref"].is_a?(String) && item["ref"].match?(/\A[a-zA-Z0-9_.:\/-]{1,256}\z/) &&
                item["sha256"].is_a?(String) && item["sha256"].match?(/\A[0-9a-f]{64}\z/)
            end
        end
      end
    end
  end
end
