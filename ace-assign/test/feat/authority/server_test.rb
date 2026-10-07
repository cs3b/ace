# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/server"

module Ace
  module Assign
    class ProtectedAuthorityServerTest < AceAssignTestCase
      def test_shutdown_keeps_owner_until_blocked_handler_finishes
        with_temp_cache do |root|
          path = File.join(root, "authority.sock")
          service = {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort, "socket_path" => path}
          map = {"authority_id" => "authority", "project_id" => "project", "launcher_uid" => 13002,
            "launcher_gid" => 13002, "launcher_groups" => [13002]}
          deployment = Object.new
          deployment.define_singleton_method(:verify_composition!) { |*args, **options| true }
          deployment.define_singleton_method(:verify_receiver_paths!) { |_id| true }
          deployment.define_singleton_method(:authority) { |_id| service }
          deployment.define_singleton_method(:verify!) { |*args, **options| map }
          deployment.define_singleton_method(:project) { |_| {"inbox_contexts" => {}} }
          kernel = Object.new
          kernel.define_singleton_method(:supported!) { true }
          kernel.define_singleton_method(:capture) { |_pid| service.slice("uid", "gid", "groups") }
          kernel.define_singleton_method(:peer) { |_socket| {"uid" => 13002, "gid" => 13002, "groups" => [13002]} }
          admitted, release = Queue.new, Queue.new
          lifecycle = Object.new
          lifecycle.define_singleton_method(:dispatch) do |**options|
            admitted << true
            release.pop
            {data: {"accepted" => true}, replayed: false}
          end
          actual_wire = Ace::Runtime::Molecules::ProtectedSocket
          fixture_wire = Object.new
          fixture_wire.define_singleton_method(:root_path!) { |*args, **options| true }
          %i[socket_identity read write deadline].each do |name|
            fixture_wire.define_singleton_method(name) { |*args, **options| actual_wire.public_send(name, *args, **options) }
          end
          factory = proc do
            server = Authority::Server.new(authority_id: "authority", lifecycle: lifecycle, deployment: deployment, kernel: kernel)
            server.define_singleton_method(:wire) { fixture_wire }
            server
          end
          first = factory.call
          owner = Thread.new { first.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(path) }
          socket = UNIXSocket.new(path)
          actual_wire.write(socket, {"version" => 1, "operation" => "blocked", "mutation_id" => "one",
            "project_id" => "project", "params" => {"mapping_id" => "mapping"}}, deadline: actual_wire.deadline(1))
          Timeout.timeout(3) { admitted.pop }
          first.request_stop
          Timeout.timeout(3) { sleep 0.005 until socket.read_nonblock(1, exception: false).nil? }
          assert owner.alive?, "closing client streams cannot terminate the admitted mutation"
          assert File.socket?(path), "endpoint must remain owned during handler drain"
          assert_raises(AttemptErrors::Conflict) { factory.call.serve }
          release << true
          assert owner.join(3), "owner should end after its handler ends"
          refute File.exist?(path)
        ensure
          release << true if owner&.alive?
          first&.request_stop
          owner&.join(3)
          socket&.close
        end
      end
    end
  end
end
