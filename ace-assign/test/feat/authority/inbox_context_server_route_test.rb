# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/server"

module Ace
  module Assign
    class InboxContextServerRouteTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket

      def exchange(operation: "inbox_context_completion", context: "one", peer_uid: 13002, extra: false)
        credentials = {"uid" => 13002, "gid" => 13002, "groups" => [13002]}
        map = {"authority_id" => "authority", "project_id" => "project",
          "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002]}
        deployment = Object.new
        deployment.define_singleton_method(:verify_composition!) { |*args, **options| true }
        deployment.define_singleton_method(:authority) { |_| credentials }
        deployment.define_singleton_method(:verify!) { |*args, **options| map }
        deployment.define_singleton_method(:project) do |_|
          {"inbox_contexts" => {"one" => {"native_mapping_id" => "mapping", "owner_credentials" => credentials},
            "two" => {"native_mapping_id" => "mapping", "owner_credentials" => credentials.merge("uid" => 13003)}}}
        end
        kernel = Object.new
        kernel.define_singleton_method(:peer) { |_| credentials.merge("uid" => peer_uid) }
        calls = []
        handler = Object.new
        handler.define_singleton_method(:dispatch) { |**options| calls << options; {data: {"route" => "accepted"}} }
        server = Authority::Server.new(authority_id: "authority", deployment: deployment,
          kernel: kernel, lifecycle: handler, composition: "services")
        client, accepted = UNIXSocket.pair
        thread = Thread.new { server.send(:receive, accepted) }
        WIRE.write(client, {"version" => 1, "operation" => operation, "mutation_id" => nil,
          "project_id" => "project", "params" => {"mapping_id" => "mapping", "inbox_context_id" => context}}, deadline: WIRE.deadline(2))
        client.write("x") if extra
        client.close_write
        response = WIRE.read(client, deadline: WIRE.deadline(2))
        thread.value
        [response, calls]
      ensure
        client&.close
        accepted&.close unless accepted&.closed?
        thread&.join(2)
      end

      def test_owner_is_query_only_even_when_credentials_overlap_launcher
        response, calls = exchange
        assert_equal "ok", response.fetch("status")
        assert_equal :context_owner, calls.fetch(0).fetch(:role)
        %w[attempt_status native_readiness reserve_attempt].each do |operation|
          response, calls = exchange(operation: operation)
          assert_equal "unauthorized", response.dig("error", "code")
          assert_empty calls
        end
      end

      def test_other_context_and_unmapped_peer_cannot_query
        [{context: "two"}, {peer_uid: 13004}].each do |options|
          response, calls = exchange(**options)
          assert_equal "unauthorized", response.dig("error", "code")
          assert_empty calls
        end
      end

      def test_query_requires_upload_eof_before_dispatch
        response, calls = exchange(extra: true)
        assert_equal "invalid_input", response.dig("error", "code")
        assert_empty calls
      end
    end
  end
end
