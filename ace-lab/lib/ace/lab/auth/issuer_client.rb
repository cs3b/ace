# frozen_string_literal: true

require "socket"
require "ace/runtime"
require "ace/runtime/molecules/protected_socket"
require_relative "error"

module Ace
  module Lab
    module Auth
      # Public CLI transport. Session identity is deliberately absent from
      # every request: the server authenticates each connected process.
      class IssuerClient
        SOCKET = "/run/lab/ace-lab-auth.sock"
        Transport = Ace::Runtime::Molecules::ProtectedSocket

        def request(profile_name:, role:, task:, assignment:, repos:, ttl_minutes: nil)
          message = {"action" => "request", "profile" => profile_name, "role" => role,
                     "task" => task, "assignment" => assignment, "repos" => repos}
          message["ttl_minutes"] = ttl_minutes if ttl_minutes
          exchange(message)
        end

        def status(lease_id: nil)
          exchange({"action" => "status"}.tap { |message| message["lease"] = lease_id if lease_id })
        end

        def exec(lease_id:, argv:)
          exchange({"action" => "exec", "lease" => lease_id, "argv" => argv}, stdio: true)
        end

        def revoke(lease_id:, force: false)
          raise Refusal, "forced revocation requires the host operator" if force
          exchange({"action" => "revoke", "lease" => lease_id}).fetch("cleanup").to_sym
        end

        def readiness(target:)
          message = {"id" => "ace-lab:readiness", "method" => "agent.readiness", "params" => {"target" => target}}
          connect_verified do |socket|
            Transport.write(socket, message, deadline: Transport.deadline, limit: 16_384)
            response = Transport.read(Transport::Ingress.new(socket), deadline: Transport.deadline(30))
            result = response.is_a?(Hash) && response["result"]
            unless response.is_a?(Hash) && response["id"] == message["id"] && !response.key?("error") &&
                result.is_a?(Hash) && result["type"] == "agent_readiness" && [true, false].include?(result["ready"])
              raise Refusal, "issuer could not verify session readiness"
            end
            result
          end
        rescue Ace::Runtime::Error, SystemCallError, IOError, SecurityError
          raise Error, "issuer readiness transport is unavailable or invalid"
        end

        def host_readiness(terminal_id:, project:, role:)
          result = exchange({"action" => "readiness", "terminal_id" => terminal_id, "project" => project, "role" => role})
          unless result.is_a?(Hash) && result["terminal_id"] == terminal_id && result["role"] == role &&
              [true, false].include?(result["ready"])
            raise Error, "issuer returned invalid operator readiness"
          end
          result
        end

        def reconcile
          raise Refusal, "reconciliation requires the host operator"
        end

        private

        def connect_verified
          unless RUBY_PLATFORM.include?("linux") && ENV["ACE_TOOLCHAIN"] == "installed"
            raise Error, "isolated session requires the installed Linux runtime"
          end
          Transport.root_path!(File.dirname(SOCKET), directory: true)
          identity = Transport.socket_identity(SOCKET, mode: 0o666)
          raise Error, "issuer endpoint is not root-owned" unless identity.last.zero?
          Transport.connect(SOCKET) do |socket|
            _, uid, = socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_PEERCRED).data.unpack("i!3")
            unless uid.zero? && Transport.socket_identity(SOCKET, mode: 0o666) == identity
              raise Error, "issuer endpoint identity changed"
            end
            yield socket
          end
        end

        def exchange(message, stdio: false)
          connect_verified do |socket|
            Transport.write(socket, message, deadline: Transport.deadline, limit: 16_384)
            ingress = Transport::Ingress.new(socket)
            response = Transport.read(ingress, deadline: Transport.deadline(120))
            if stdio && response == {"stdio" => true}
              unix = UNIXSocket.for_fd(socket.fileno).tap { |io| io.autoclose = false }
              [STDIN, STDOUT, STDERR].each { |io| unix.send_io(io) }
              # The issuer enforces the lease's actual execution deadline.
              response = Transport.read(ingress, deadline: Transport.deadline(86_400))
            end
            unless response.is_a?(Hash) && response["ok"] == true && response.key?("result")
              raise Refusal, response.is_a?(Hash) ? response.fetch("error", "issuer refused the request") : "invalid issuer response"
            end
            response.fetch("result")
          end
        rescue Ace::Runtime::Error, SystemCallError, IOError, SecurityError
          raise Error, "issuer transport is unavailable or invalid"
        end
      end
    end
  end
end
