# frozen_string_literal: true
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/protected_socket"
require "securerandom"
require_relative "guarded_native_origin"

module Ace
  module Herdr
    module Molecules
      # Uses only the canonical attempt's pinned server and original fresh reply.
      class ProtectedNativeControl
        def initialize(mapping:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @mapping, @kernel = mapping, kernel
          @origin = nil
        end

        def verify!
          @kernel.supported!
          native = @mapping.fetch("native")
          wire.root_path!(File.dirname(native.fetch("socket_path")), directory: true, owner: @mapping.fetch("worker_uid"))
          identity = wire.socket_identity(native.fetch("socket_path"))
          unless identity == native.fetch("socket_identity") && native.fetch("version") == "0.9.3"
            raise Ace::Runtime::RuntimeUnavailableError, "native endpoint generation or version changed"
          end
          @kernel.live!(native.fetch("server_identity"))
          true
        end

        def request(method, params = {})
          result = exchange(method, params)
          unless result["result"].is_a?(Hash) && !result.key?("error")
            raise Ace::Runtime::RuntimeUnavailableError, "native control response is invalid"
          end
          result.fetch("result")
        end

        # Admission calls this before committing the durable prompt intent.
        # Neither this method nor replay is permission to issue native input.
        def prompt_preflight!(binding)
          raise Ace::Runtime::RuntimeUnavailableError, "canonical original binding is unavailable" unless binding.is_a?(Hash)
          original = binding.reject { |key, _| key == "guarded_origin" }
          fresh = guarded_binding!(original)
          unless fresh.fetch("guarded_origin") == guarded_origin!(binding)
            raise Ace::Runtime::RuntimeUnavailableError, "canonical original guarded actor changed"
          end
          fresh.fetch("guarded_origin")
        end

        # Explicit N2 capture keeps existing original scope binding bytes
        # unchanged. The launch owner persists this separately in its canonical
        # record data before issuing any steering permission.
        def guarded_binding!(binding)
          raise Ace::Runtime::RuntimeUnavailableError, "canonical original binding is unavailable" unless binding.is_a?(Hash)
          original = binding.reject { |key, _| key == "guarded_origin" }
          observed = observe(original.fetch("native_origin").merge("process_binding" => original))
          info = request("pane.process_info", {"pane_id" => original.fetch("pane")}).fetch("process_info")
          unless info["pane_id"] == original.fetch("pane") && info["shell_pid"] == observed.dig("process_identity", "pid") &&
              info["guarded_prompt"] == true && info["guarded_input_drain"] == true
            raise Ace::Runtime::RuntimeUnavailableError, "native original guarded capability is unavailable"
          end
          observed.merge("guarded_origin" => GuardedNativeOrigin.verify!(info.fetch("guarded_prompt_origin"),
            terminal_id: observed.fetch("terminal_id"), child: observed.fetch("process_identity")))
        rescue KeyError, TypeError
          raise Ace::Runtime::RuntimeUnavailableError, "canonical original guarded actor is unavailable"
        end

        # Only an already accepted canonical issue permit invokes this method.
        # Unknown/lost transport results remain uncertain even if a local error
        # occurred before some observed write; native phase is the only refusal
        # evidence. Never return native agent/message fields or prompt bytes.
        def prompt(binding:, text:)
          body = text.dup.force_encoding(Encoding::UTF_8) if text.is_a?(String)
          unless body && body.valid_encoding? && body.bytesize.between?(1, 16_384) && !body.match?(/\A[[:space:]]*\z/)
            raise ArgumentError, "prompt text must be bounded nonblank UTF-8"
          end
          origin = guarded_origin!(binding)
          submit_prompt(origin, body)
        end

        def submit_prompt(origin, body)
          frame = exchange("agent.prompt", {"target" => origin.fetch("terminal_id"), "text" => body, "expected_origin" => origin},
            write_limit: 131_072, read_limit: 16_384)
          result = frame["result"]
          if frame.keys.sort == %w[id result] && result.is_a?(Hash) && result.keys.sort == %w[agent origin submission type] &&
              result["type"] == "agent_prompted" && result["submission"] == "submitted" && result["origin"] == origin && result["agent"].is_a?(Hash)
            return {"outcome" => "submitted", "submission" => "submitted", "origin" => origin}
          end
          error = frame["error"]
          codes = %w[guard_mismatch origin_unavailable origin_exited agent_blocked agent_not_ready target_missing submission_busy]
          if frame.keys.sort == %w[error id] && error.is_a?(Hash) && error.keys.sort == %w[code message phase] &&
              error["phase"] == "not_issued" && codes.include?(error["code"]) && error["message"].is_a?(String)
            return {"outcome" => "not_issued", "phase" => "not_issued", "code" => error.fetch("code"), "origin" => origin}
          end
          {"outcome" => "uncertain", "origin" => origin}
        rescue Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
          {"outcome" => "uncertain", "origin" => origin}
        end

        # Input drain authenticates the captured actor even after its original
        # child exited. Reobserving a live child here would destroy that proof.
        # Actor/server replacement or missing completion remains unconfirmed.
        def inhibit_input(binding:)
          origin = guarded_origin!(binding)
          drain_input(origin)
        end

        def drain_input(origin)
          frame = exchange("terminal.inhibit_input", {"target" => origin.fetch("terminal_id"), "expected_origin" => origin},
            write_limit: 16_384, read_limit: 16_384)
          result = frame["result"]
          if frame.keys.sort == %w[id result] && result.is_a?(Hash) && result.keys.sort == %w[input_state origin pending_input type] &&
              result["type"] == "terminal_input_drained" && result["origin"] == origin && result["input_state"] == "inhibited" &&
              result["pending_input"].is_a?(Integer) && result["pending_input"].zero?
            return {"outcome" => "inhibited", "origin" => origin, "input_state" => "inhibited", "pending_input" => 0}
          end
          error = frame["error"]
          if frame.keys.sort == %w[error id] && error.is_a?(Hash) && error.keys.sort == %w[code phase] &&
              error["phase"] == "unconfirmed" && %w[invalid_params guard_mismatch origin_unavailable input_drain_unavailable].include?(error["code"])
            return {"outcome" => "unconfirmed", "origin" => origin, "code" => error.fetch("code"), "phase" => "unconfirmed"}
          end
          {"outcome" => "unconfirmed", "origin" => origin}
        rescue Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
          {"outcome" => "unconfirmed", "origin" => origin}
        end

        def guarded_origin!(binding)
          raise Ace::Runtime::RuntimeUnavailableError, "canonical original guarded binding is unavailable" unless binding.is_a?(Hash)
          GuardedNativeOrigin.verify!(binding.fetch("guarded_origin"), terminal_id: binding.fetch("terminal_id"),
            child: binding.fetch("process_identity"))
        rescue KeyError, TypeError
          raise Ace::Runtime::RuntimeUnavailableError, "canonical original guarded binding is unavailable"
        end

        def exchange(method, params = {}, write_limit: wire::LIMIT, read_limit: wire::LIMIT)
          verify!
          native = @mapping.fetch("native")
          wire.connect(native.fetch("socket_path")) do |socket|
            unless @kernel.same?(@kernel.peer(socket), native.fetch("server_identity")) &&
                wire.socket_identity(native.fetch("socket_path")) == native.fetch("socket_identity")
              raise Ace::Runtime::RuntimeUnavailableError, "native peer differs from installed server"
            end
            id = SecureRandom.hex(12)
            deadline = wire.deadline
            wire.write(socket, {"id" => id, "method" => method, "params" => params}, deadline: deadline, limit: write_limit)
            result = wire.read(socket, deadline: deadline, limit: read_limit)
            unless result.is_a?(Hash) && result["id"] == id
              raise Ace::Runtime::RuntimeUnavailableError, "native control response is invalid"
            end
            verify!
            result
          end
        rescue SystemCallError, IOError
          raise Ace::Runtime::RuntimeUnavailableError, "native control outcome is unavailable"
        end

        def preflight!
          ping = request("ping")
          unless ping["version"] == "0.9.3" && ping["protocol"] == 22 &&
              ping.dig("capabilities", "endpoint_protocol_generation") == 1
            raise Ace::Runtime::RuntimeUnavailableError, "installed native protocol is unsupported"
          end
          workspace = request("workspace.get", {"workspace_id" => @mapping.fetch("native").fetch("workspace_id")}).fetch("workspace")
          unless workspace["workspace_id"] == @mapping.fetch("native").fetch("workspace_id")
            raise Ace::Runtime::RuntimeUnavailableError, "installed native workspace differs"
          end
          true
        rescue KeyError, TypeError
          raise Ace::Runtime::RuntimeUnavailableError, "installed native workspace is unavailable"
        end

        def create(mapping_id:, ticket:)
          preflight!
          raise Ace::Runtime::RuntimeUnavailableError, "native creation is never repeated" if @origin
          # Mark attempted BEFORE any remote write: a lost reply cannot respawn.
          @origin = {"state" => "uncertain"}
          workspace = @mapping.fetch("native").fetch("workspace_id")
          command = [@mapping.fetch("bootstrap"), mapping_id, ticket]
          layout = request("layout.apply", {"workspace_id" => workspace, "focus" => false,
            "root" => {"type" => "pane", "cwd" => @mapping.fetch("worker_cwd"),
              "command" => command}})
          layout = layout.fetch("layout")
          root = layout.fetch("root")
          unless layout["workspace_id"] == workspace && root.is_a?(Hash) && root["type"] == "pane" &&
              !root.key?("children") && !root.key?("first") && !root.key?("second") &&
              root["command"] == command && root["cwd"] == @mapping.fetch("worker_cwd")
            raise Ace::Runtime::RuntimeUnavailableError, "native creation is not a fresh single-pane layout"
          end
          pane = root.fetch("pane_id")
          original = {"workspace" => workspace, "tab" => layout.fetch("tab_id"), "pane" => pane,
            "server_identity" => @mapping.fetch("native").fetch("server_identity"),
            "socket_identity" => @mapping.fetch("native").fetch("socket_identity"), "command" => command, "cwd" => @mapping.fetch("worker_cwd")}
          @origin = original
          observe(original)
        rescue KeyError, TypeError
          raise Ace::Runtime::RuntimeUnavailableError, "native creation provenance is unavailable"
        end

        def observe(origin)
          unless origin["workspace"] == @mapping.fetch("native").fetch("workspace_id") &&
              origin["server_identity"] == @mapping.fetch("native").fetch("server_identity") &&
              origin["socket_identity"] == @mapping.fetch("native").fetch("socket_identity")
            raise Ace::Runtime::RuntimeUnavailableError, "native creation server changed"
          end
          pane = request("pane.get", {"pane_id" => origin.fetch("pane")}).fetch("pane")
          info = request("pane.process_info", {"pane_id" => origin.fetch("pane")}).fetch("process_info")
          unless pane["pane_id"] == origin["pane"] && pane["workspace_id"] == origin["workspace"] &&
              pane["tab_id"] == origin["tab"] && info["pane_id"] == origin["pane"] && [String, Integer].any? { |type| pane["terminal_id"].is_a?(type) }
            raise Ace::Runtime::RuntimeUnavailableError, "original native pane or terminal changed"
          end
          child = @kernel.capture(info.fetch("shell_pid"))
          unless child["uid"] == @mapping.fetch("worker_uid") && child["gid"] == @mapping.fetch("worker_gid") &&
              child["groups"] == @mapping.fetch("worker_groups") &&
              child["parent_pid"] == origin.fetch("server_identity").fetch("pid")
            raise Ace::Runtime::RuntimeUnavailableError, "original native child lineage or credentials changed"
          end
          binding = {"runtime" => "herdr", "session" => origin.fetch("workspace"), "pane" => origin.fetch("pane"),
            "terminal_id" => pane.fetch("terminal_id").to_s, "process_identity" => child,
            "shell_identity" => child, "native_origin" => origin.reject { |key, _| key == "process_binding" }}
          if origin.key?("process_binding") && origin["process_binding"] != binding
            raise Ace::Runtime::RuntimeUnavailableError, "original native child changed"
          end
          binding
        rescue KeyError, TypeError
          raise Ace::Runtime::RuntimeUnavailableError, "original native child cannot be observed"
        end

        def terminate(binding, handle:)
          observe(binding.fetch("native_origin").merge("process_binding" => binding))
          request("pane.close", {"pane_id" => binding.fetch("pane")})
          @kernel.exited?(handle, timeout: 5)
        end

        private
        private :exchange, :submit_prompt, :drain_input
        def wire
          Ace::Runtime::Molecules::ProtectedSocket
        end
      end
    end
  end
end
