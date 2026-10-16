# frozen_string_literal: true

require_relative "../test_helper"
require "timeout"

class OrdinaryListenerTest < Minitest::Test
  def test_disconnected_client_and_failed_execution_do_not_kill_next_request
    Dir.mktmpdir("ordinary-wire") do |dir|
      path = File.join(dir, "receiver.sock")
      ready, admitted, release = Queue.new, Queue.new, Queue.new
      executed, logs = [], []
      handler = ->(request) do
        if request.fetch("request_id") == "first"
          admitted << true
          release.pop
        end
        {"status" => "ok", "data" => request}
      end
      handler.define_singleton_method(:recover_pending!) { ready << true }
      handler.define_singleton_method(:execute) do |id|
        executed << id
        raise IOError, "secret-provider-token" if id == "first"
      end
      listener = Ace::Lab::Molecules::OrdinaryListener.new(socket_path: path,
        peer_uid: Process.uid, handler: handler, logger: ->(message) { logs << message })
      thread = Thread.new { listener.serve }
      Timeout.timeout(5) { ready.pop }
      socket = UNIXSocket.new(path)
      document = JSON.generate("request_id" => "first")
      socket.write("#{Ace::Lab::Molecules::OrdinarySocket::HANDSHAKE} #{document.bytesize}\n#{document}")
      Timeout.timeout(5) { admitted.pop }
      socket.close
      release << true
      result = Ace::Lab::Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid)
        .submit("request_id" => "second")
      assert_equal "ok", result.fetch("status")
      Timeout.timeout(5) { sleep 0.01 until executed.include?("second") }
      assert_equal %w[first second], executed
      assert thread.alive?
      assert logs.any? { |line| line.include?("effect failed (IOError)") }
      refute logs.any? { |line| line.include?("secret-provider-token") }
    ensure
      release << true
      socket&.close unless socket&.closed?
      listener&.stop
      thread&.join(5)
    end
  end
end
