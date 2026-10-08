# frozen_string_literal: true

require "test_helper"
require "socket"
require "ace/hitl/lifecycle/client"

class LifecycleClientDeadlineTest < AceHitlTestCase
  def setup
    @scratch = Dir.mktmpdir("hitl-deadline", "/tmp")
    @path = File.join(@scratch, "service.sock")
    @server = UNIXServer.new(@path)
    @client = Ace::Hitl::Lifecycle::Client.new(socket_path: @path, service_uid: Process.uid)
  end

  def teardown
    @thread&.kill
    @thread&.join
    @server.close
    FileUtils.remove_entry(@scratch)
  end

  def deadline(seconds = 0.05)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
  end

  def test_finite_deadline_bounds_reply_including_indefinite_consume
    @thread = Thread.new do
      socket = @server.accept
      socket.gets
      sleep 2
    ensure
      socket&.close
    end
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      @client.consume("otp1", timeout: 0, operation: "publish", deadline: deadline)
    end
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.5
  end

  def test_expired_or_invalid_deadline_sends_no_request
    [deadline(-1), Float::INFINITY, "later", false].each do |value|
      assert_raises(Ace::Hitl::Lifecycle::TransportError) { @client.read("otp1", deadline: value) }
    end
    assert_nil IO.select([@server], nil, nil, 0)
  end

  def test_deadline_is_local_and_not_a_wire_parameter
    frame = nil
    @thread = Thread.new do
      socket = @server.accept
      frame = JSON.parse(socket.gets)
      socket.write(Ace::Hitl::Lifecycle::Protocol.encode_result({"id" => "otp1"}))
    ensure
      socket&.close
    end
    assert_equal({"id" => "otp1"}, @client.read("otp1", deadline: deadline(1)))
    @thread.join
    assert_equal({"id" => "otp1"}, frame.fetch("params"))
  end

  def test_backpressured_write_uses_same_absolute_deadline
    writer, reader = Socket.pair(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    writer.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF, 1024)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      @client.send(:write_frame!, writer, "x" * (64 * 1024), deadline)
    end
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.5
  ensure
    writer&.close
    reader&.close
  end
end
