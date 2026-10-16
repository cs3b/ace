# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"

module Ace
  module Assign
    class OrdinaryTransportTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket

      # These tests exercise the real wire/peer boundary. Installation policy
      # and native role admission have separate tests; no protected mock exists.
      class Admission
        attr_reader :service
        attr_accessor :authorized
        def initialize(service)
          @service, @authorized = service, true
          @observer = Authority::OrdinaryPeer.new
        end
        def verify_listener! = true
        def peer(socket, deadline:) = @observer.capture(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          @observer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity, "project differs" unless authorized && request["project_id"] == "atlas"
          :worker
        end
      end

      class Handler
        OPERATIONS = %w[observe upload].freeze
        TRANSFER_OPERATIONS = {"upload" => {direction: :upload, purpose: :artifacts, roles: [:worker]}}.freeze
        attr_reader :calls
        def initialize = @calls = []
        def authorize_transfer!(**) = true
        def dispatch(request:, peer:, role:, deadline:, transfer: nil)
          raise "ordinary deadline lost" unless deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @calls << request.fetch("operation")
          {data: {"peer_uid" => peer.fetch("uid"), "role" => role.to_s, "body" => transfer&.bytes&.unpack1("H*")}, replayed: false}
        end
      end

      def test_real_kernel_peer_and_binary_upload_share_closed_authority_transport
        with_owner do |service, admission, handler|
          client = Authority::OrdinaryClient.new(project_id: "atlas", service: service, verify_selection: -> {})
          reply = client.call("observe", {})
          assert_equal Process.uid, reply.data.fetch("peer_uid")
          assert_equal "worker", reply.data.fetch("role")
          refute reply.replayed
          bytes = "binary\x00\n\xff".b
          uploaded = client.call("upload", {}, mutation_id: "upload-one", upload_parts: [bytes], purpose: :artifacts)
          assert_equal bytes.unpack1("H*"), uploaded.data.fetch("body")
          assert_empty Dir.children(File.join(service.fetch("state_root"), "transfers"))
          admission.authorized = false
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("observe", {}) }
          assert_equal %w[observe upload], handler.calls
        end
      end

      def test_extra_body_and_protected_control_are_refused_without_dispatch
        with_owner do |service, _admission, handler|
          socket = UNIXSocket.new(service.fetch("socket_path"))
          WIRE.write(socket, {"version" => 1, "operation" => "observe", "mutation_id" => nil, "project_id" => "atlas", "params" => {}}, deadline: WIRE.deadline(1))
          socket.write("unexpected")
          socket.shutdown(Socket::SHUT_WR)
          assert_equal "invalid_input", WIRE.read(socket, deadline: WIRE.deadline(2)).dig("error", "code")
          client = Authority::OrdinaryClient.new(project_id: "atlas", service: service, verify_selection: -> {})
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("launch_control", {}) }
          assert_empty handler.calls
        ensure
          socket&.close
        end
      end

      def test_changed_endpoint_identity_or_selection_never_falls_back
        with_owner do |service, _admission, handler|
          wrong = Authority::OrdinaryClient.new(project_id: "atlas", service: service.merge("uid" => Process.uid + 1), verify_selection: -> {})
          assert_raises(Ace::Runtime::RuntimeUnavailableError, AttemptErrors::UnauthorizedIdentity, AttemptErrors::EvidenceUnavailable) { wrong.call("observe", {}) }
          revoked = Authority::OrdinaryClient.new(project_id: "atlas", service: service,
            verify_selection: -> { raise AttemptErrors::UnauthorizedIdentity, "grant revoked" })
          assert_raises(AttemptErrors::UnauthorizedIdentity) { revoked.call("observe", {}) }
          assert_empty handler.calls
        end
      end

      private

      def with_owner
        Dir.mktmpdir("ordinary-wire-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0o700, root)
          service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          admission = Admission.new(service)
          handler = Handler.new
          server = Authority::OrdinaryServer.new(admission: admission, lifecycle: Authority::Router.new(handlers: [handler]))
          owner = Thread.new { server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
          yield service, admission, handler
        ensure
          server&.request_stop
          server&.stop
          assert owner.join(3), "ordinary handlers must drain before owner exits"
        end
      end
    end
  end
end
