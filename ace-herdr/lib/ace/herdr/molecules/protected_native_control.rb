# frozen_string_literal: true
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/protected_socket"
require "securerandom"

module Ace
  module Herdr
    module Molecules
      # Uses only an installer-pinned server and its original fresh creation reply.
      class ProtectedNativeControl
        def initialize(mapping:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @mapping, @kernel = mapping, kernel
          @origin = nil
        end

        def verify!
          @kernel.supported!
          native = @mapping.fetch("native")
          wire.root_path!(File.dirname(native.fetch("socket_path")), directory: true)
          wire.root_path!(native.fetch("executable"))
          identity = wire.socket_identity(native.fetch("socket_path"))
          unless identity == native.fetch("socket_identity") && native.fetch("version") == "0.9.3"
            raise Ace::Runtime::RuntimeUnavailableError, "native endpoint generation or version changed"
          end
          @kernel.live!(native.fetch("server_identity"))
          true
        end

        def request(method, params = {})
          verify!
          native = @mapping.fetch("native")
          wire.connect(native.fetch("socket_path")) do |socket|
            unless @kernel.same?(@kernel.peer(socket), native.fetch("server_identity")) &&
                wire.socket_identity(native.fetch("socket_path")) == native.fetch("socket_identity")
              raise Ace::Runtime::RuntimeUnavailableError, "native peer differs from installed server"
            end
            id = SecureRandom.hex(12)
            deadline = wire.deadline
            wire.write(socket, {"id" => id, "method" => method, "params" => params}, deadline: deadline)
            result = wire.read(socket, deadline: deadline)
            unless result.is_a?(Hash) && result["id"] == id && result["result"].is_a?(Hash) && !result.key?("error")
              raise Ace::Runtime::RuntimeUnavailableError, "native control response is invalid"
            end
            verify!
            result.fetch("result")
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
          true
        end

        def create(mapping_id:, ticket:)
          preflight!
          raise Ace::Runtime::RuntimeUnavailableError, "native creation is never repeated" if @origin
          # Mark attempted BEFORE any remote write: a lost reply cannot respawn.
          @origin = {"state" => "uncertain"}
          created = request("workspace.create", {"cwd" => @mapping.fetch("worker_cwd"), "focus" => false})
          workspace = created.fetch("workspace").fetch("workspace_id")
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
          unless origin["server_identity"] == @mapping.fetch("native").fetch("server_identity") &&
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
        def wire
          Ace::Runtime::Molecules::ProtectedSocket
        end
      end
    end
  end
end
