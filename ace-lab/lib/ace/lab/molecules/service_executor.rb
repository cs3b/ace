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
        # must still stop dispatch. The candidate head is revalidated through
        # +head_loader+ for the same reason: a concurrent commit must not let
        # a stale reviewed candidate execute.
        def execute(operation:, request:, input:, policy_loader:, authorization:, head_loader:)
          fresh = policy_loader.call
          current = fresh.operation!(request.fetch("operation"), project: request.fetch("project_id"),
            service_id: request.fetch("service_id"))
          raise SecurityError, "executor operation changed before dispatch" unless current == operation
          fresh.authorize!(authorization, request)
          unless head_loader.call == request.fetch("candidate_head")
            raise SecurityError, "candidate head changed before dispatch"
          end
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
        rescue JSON::ParserError, Timeout::Error, SystemCallError, IOError
          # Transport failures after the claim (broken pipe, connection
          # reset, socket loss) leave the effect unknown: uncertainty, not a
          # classified crash, is the honest outcome.
          nil
        end

        private

        # Handler output is bounded DURING execution: a noisy handler is
        # killed and reaped once its response exceeds the receipt limit
        # instead of being buffered without bound in this process.
        def invoke_local(operation, request, input)
          unless Process.uid == operation.fetch("executor_uid") && Process.euid == operation.fetch("executor_uid")
            raise SecurityError, "current OS identity is not the configured executor"
          end
          out = nil
          status = nil
          Open3.popen3(*operation.fetch("argv")) do |stdin, stdout, stderr, waiter|
            pid = waiter.pid
            begin
              Timeout.timeout(30) do
                stdin.write(JSON.generate({"request" => request, "input" => input}))
                stdin.close
                errors = Thread.new { bounded_read(stderr, 8192) }
                out = bounded_read(stdout, 16 * 1024 + 1)
                errors.join
                Process.kill("KILL", pid) if out && out.bytesize > 16 * 1024
                status = waiter.value
              end
            rescue Timeout::Error
              Process.kill("KILL", pid) rescue nil
              waiter.value
              raise
            end
          end
          out if out && out.bytesize <= 16 * 1024 && status&.success?
        end

        def bounded_read(io, limit)
          io.read(limit).to_s
        rescue IOError, Errno::EBADF
          ""
        ensure
          begin
            io.close
          rescue IOError, Errno::EBADF
            nil
          end
        end


        def invoke_unix(operation, request, input)
          path = operation.fetch("socket_path")
          stat = File.lstat(path)
          unless stat.socket? && stat.uid == operation.fetch("executor_uid") && (stat.mode & 0o002).zero?
            raise SecurityError, "service socket owner or permissions do not match the executor"
          end
          # One deadline covers connecting, writing, and reading: a stalled
          # peer must leave the claimed effect uncertain, never block.
          Timeout.timeout(30) do
            UNIXSocket.open(path) do |socket|
              peer_uid, = socket.getpeereid
              raise SecurityError, "service peer identity does not match the executor" unless peer_uid == stat.uid
              socket.write(JSON.generate({"request" => request, "input" => input}) + "\n")
              socket.flush
              socket.gets(16 * 1024 + 1)
            end
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
