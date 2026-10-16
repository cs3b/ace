# frozen_string_literal: true

require "securerandom"
require "ace/runtime/molecules/protected_socket"
require "ace/herdr/molecules/herdr_executor"
require "ace/assign/authority/ordinary_peer"
require_relative "ordinary_owner_config"

module Ace
  module Lab
    module Molecules
      # Read-only use of Herdr's existing native protocol. Root selection pins
      # the endpoint inode and live server; no ambient CLI environment chooses
      # the daemon, and no protected runtime guarantees are borrowed here.
      class OrdinaryNativeRead
        def initialize(config:, deadline:, peer: Ace::Assign::Authority::OrdinaryPeer.new)
          raise ArgumentError, "native reader needs installed selection" unless config.is_a?(OrdinaryOwnerConfig)
          @config, @deadline, @peer = config, deadline, peer
          @native = config.native
        end

        def preflight!
          result = request("ping", {})
          unless result["type"] == "pong" && result.values_at("version", "protocol") == @native.values_at("version", "protocol")
            unavailable!("native protocol differs from installed selection")
          end
          true
        end

        def pane_get(pane)
          result = request("pane.get", {"pane_id" => pane})
          unless result["type"] == "pane_info" && result["pane"].is_a?(Hash) && result["pane"]["pane_id"] == pane
            unavailable!("native pane metadata differs from requested pane")
          end
          response(result)
        end

        def pane_process_info(pane)
          @process_info = nil
          result = request("pane.process_info", {"pane_id" => pane})
          unless result["type"] == "pane_process_info" && result["process_info"].is_a?(Hash) && result["process_info"]["pane_id"] == pane
            unavailable!("native process inventory differs from requested pane")
          end
          @process_info = result.fetch("process_info")
          response(result)
        end

        # This per-PID native field comes from process_cwd, not the terminal's
        # OSC/UI working directory. The caller separately verifies PID birth.
        def process_cwd(pid)
          processes = @process_info.is_a?(Hash) && @process_info["foreground_processes"]
          unavailable!("native process inventory is unavailable") unless processes.is_a?(Array)
          matches = processes.select { |entry| entry.is_a?(Hash) && entry["pid"] == pid }
          path = matches.one? && matches.first["cwd"]
          unless path.is_a?(String) && path.bytesize.between?(1, 4096) && !path.include?("\0") &&
              path.start_with?("/") && File.expand_path(path) == path
            unavailable!("exact native process working directory is unavailable")
          end
          path
        end

        private

        def request(method, params)
          verify_endpoint!
          wire.connect(@native.fetch("socket_path"), deadline: @deadline) do |socket|
            unless @peer.capture(socket, deadline: @deadline) == @native.fetch("server_identity")
              unavailable!("native peer differs from installed server")
            end
            verify_endpoint!
            id = SecureRandom.hex(12)
            wire.write(socket, {"id" => id, "method" => method, "params" => params}, deadline: @deadline, limit: 16_384)
            value = wire.read(wire::Ingress.new(socket), deadline: @deadline, limit: 65_536)
            unless value.is_a?(Hash) && value.keys.sort == %w[id result] && value["id"] == id && value["result"].is_a?(Hash)
              unavailable!("native read response is invalid")
            end
            verify_endpoint!
            @peer.live!(@native.fetch("server_identity"), deadline: @deadline)
            value.fetch("result")
          end
        rescue SystemCallError, IOError, KeyError, Ace::Assign::AttemptErrors::UnauthorizedIdentity
          unavailable!("native read is unavailable")
        end

        def verify_endpoint!
          @config.verify_selection!
          path = @native.fetch("socket_path")
          wire.root_path!(File.dirname(path), directory: true)
          unless wire.socket_identity(path) == @native.fetch("socket_identity") && (File.lstat(path).mode & 0o007).zero?
            unavailable!("native endpoint generation or access differs")
          end
        end

        def response(result)
          Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate({"result" => result}), stderr: "", success: true, exit_code: 0)
        end

        def wire = Ace::Runtime::Molecules::ProtectedSocket

        def unavailable!(reason)
          raise Ace::Runtime::RuntimeUnavailableError, reason
        end
      end
    end
  end
end
