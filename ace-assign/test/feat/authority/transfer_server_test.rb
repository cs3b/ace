# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/server"
require "ace/assign/authority/router"

module Ace
  module Assign
    class ProtectedTransferServerTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket
      class Launch
        OPERATIONS = ["launch_preflight"].freeze
        def close; end
      end
      class Handler
        OPERATIONS = %w[upload export].freeze
        TRANSFER_OPERATIONS = {
          "upload" => {direction: :upload, purpose: :artifacts, roles: [:worker]},
          "export" => {direction: :download, purpose: :artifacts, roles: [:worker]}
        }.freeze
        attr_accessor :authorized
        attr_reader :calls, :admissions
        def initialize; @authorized = true; @calls = []; @admissions = Queue.new; end
        def authorize_transfer!(**options)
          @admissions << true
          raise AttemptErrors::UnauthorizedIdentity, "different attempt" unless authorized
        end
        def dispatch(request:, transfer: nil, **options)
          @calls << request.fetch("operation")
          if transfer
            {data: {"accepted" => transfer.bytes.unpack1("H*")}, replayed: false}
          else
            {data: {"exported" => true}, replayed: false, transfer_parts: ["one\x00\n".b, "two\r\n".b]}
          end
        end
      end

      def with_server(peer_role: :worker)
        Dir.mktmpdir("ace-authority-wire-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          path = File.join(root, "authority.sock")
          service = {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort, "socket_path" => path, "state_root" => root}
          map = {"authority_id" => "authority", "project_id" => "project", "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001]}
          deployment = Object.new
          deployment.define_singleton_method(:verify_composition!) { |*args, **options| true }
          deployment.define_singleton_method(:verify_receiver_paths!) { |_id| true }
          deployment.define_singleton_method(:authority) { |_id| service }
          deployment.define_singleton_method(:verify!) { |*args, **options| map }
          deployment.define_singleton_method(:project) do |_|
            {"inbox_contexts" => {}}
          end
          kernel = Object.new
          kernel.define_singleton_method(:supported!) { true }
          kernel.define_singleton_method(:capture) { |_pid| service.slice("uid", "gid", "groups") }
          uid = {worker: 13001}.fetch(peer_role)
          kernel.define_singleton_method(:peer) { |_socket| {"uid" => uid, "gid" => uid, "groups" => [uid]} }
          handler = Handler.new
          router = Authority::Router.new(launch: Launch.new, handlers: [handler])
          server = Authority::Server.new(authority_id: "authority", lifecycle: router, deployment: deployment, kernel: kernel)
          wire = Object.new
          wire.define_singleton_method(:root_path!) { |*args, **options| true }
          %i[socket_identity read write deadline].each { |name| wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) } }
          server.define_singleton_method(:wire) { wire }
          owner = Thread.new { server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(path) }
          yield path, handler, root
        ensure
          server&.request_stop
          server&.stop
          assert owner.join(3), "all closed transfer handlers must drain"
        end
      end

      def request(socket, operation, params = {})
        WIRE.write(socket, {"version" => 1, "operation" => operation, "mutation_id" => "mutation", "project_id" => "project",
          "params" => params.merge("mapping_id" => "mapping")}, deadline: WIRE.deadline(1))
      end

      def test_exact_upload_and_download_use_fixed_source_framing
        with_server do |path, handler, root|
          codec = Authority::TransferCodec.new(root: root)
          socket = UNIXSocket.new(path)
          payload = "binary\x00\r\n".b
          request(socket, "upload", "transfer" => codec.descriptor([payload], purpose: :artifacts))
          socket.write(payload)
          socket.shutdown(Socket::SHUT_WR)
          reply = WIRE.read(socket, deadline: WIRE.deadline(2))
          assert_equal payload.unpack1("H*"), reply.dig("data", "accepted")
          socket.close
          socket = UNIXSocket.new(path)
          request(socket, "export")
          reply = WIRE.read(socket, deadline: WIRE.deadline(2))
          parts = codec.receive(socket, descriptor: reply.dig("data", "transfer"), purpose: :artifacts, deadline: WIRE.deadline(2)) do |input|
            Array.new(input.count) { |index| input.bytes(index: index) }
          end
          assert_equal ["one\x00\n".b, "two\r\n".b], parts
          assert_equal %w[upload export], handler.calls
          assert_empty Dir.children(File.join(root, "transfers"))
        ensure
          socket&.close
        end
      end

      def test_exact_origin_refusal_precedes_spool_and_body_read
        with_server do |path, handler, root|
          handler.authorized = false
          socket = UNIXSocket.new(path)
          request(socket, "upload", "transfer" => {"invalid" => true})
          reply = WIRE.read(socket, deadline: WIRE.deadline(2))
          assert_equal "unauthorized", reply.dig("error", "code")
          refute File.exist?(File.join(root, "transfers"))
          assert_empty handler.calls
        ensure
          socket&.close
        end
      end

      def test_extra_bytes_refuse_before_mutation_and_remove_spool
        with_server do |path, handler, root|
          codec = Authority::TransferCodec.new(root: root)
          socket = UNIXSocket.new(path)
          request(socket, "upload", "transfer" => codec.descriptor(["one"], purpose: :artifacts))
          socket.write("one-extra")
          socket.shutdown(Socket::SHUT_WR)
          reply = WIRE.read(socket, deadline: WIRE.deadline(2))
          assert_equal "error", reply.fetch("status")
          assert_empty handler.calls
          assert_empty Dir.children(File.join(root, "transfers"))
        ensure
          socket&.close
        end
      end
      def test_malformed_transfer_schema_is_invalid_input_before_handler_or_spool
        with_server do |path, handler, root|
          socket = UNIXSocket.new(path)
          request(socket, "upload", "transfer" => {"invalid" => true})
          socket.shutdown(Socket::SHUT_WR)
          reply = WIRE.read(socket, deadline: WIRE.deadline(2))
          assert_equal "invalid_input", reply.dig("error", "code")
          refute reply.key?("data")
          assert_empty handler.calls
          assert_empty Dir.children(File.join(root, "transfers"))
        ensure
          socket&.close
        end
      end

    end
  end
end
