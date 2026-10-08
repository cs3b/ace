# frozen_string_literal: true

require "test_helper"
require "socket"
require "ace/herdr/molecules/codex_app_server_transport"

class CodexAppServerTransportTest < Minitest::Test
  THREAD = "00000000-0000-0000-0000-000000000001"
  QUEUED = "00000000-0000-0000-0000-000000000002"
  CLIENT = "ace-" + "a" * 32
  Transport = Ace::Herdr::Molecules::CodexAppServerTransport

  class ServerWriter
    def initialize(socket) = @socket = socket
    def write(bytes) = @socket.write(bytes)
  end

  def test_real_driver_correlates_one_native_queue_add
    exercise do |result, calls|
      assert_equal true, result.fetch("accepted")
      assert_equal QUEUED, result.fetch("queued_submission_id")
      assert_equal CLIENT, result.fetch("client_user_message_id")
      assert_equal Digest::SHA256.hexdigest("same text"), result.fetch("payload_sha256")
      assert_equal %w[initialize initialized thread/queue/add], calls.map { |call| call.fetch("method") }
      assert_equal CLIENT, calls.last.fetch("params").fetch("clientUserMessageId")
    end
  end

  def test_lost_reply_is_uncertain_after_exactly_one_add
    exercise(mode: :lost_reply) do |result, calls|
      refute result.fetch("accepted")
      refute result.fetch("pre_submit")
      assert_equal 1, calls.count { |call| call["method"] == "thread/queue/add" }
    end
  end

  def test_wrong_reply_client_id_stays_uncertain
    exercise(mode: :wrong_client) do |result, calls|
      refute result.fetch("accepted")
      refute result.fetch("pre_submit")
      assert_equal 1, calls.count { |call| call["method"] == "thread/queue/add" }
    end
  end

  def test_wrong_payload_stays_uncertain
    exercise(mode: :wrong_payload) do |result, calls|
      refute result.fetch("accepted")
      refute result.fetch("pre_submit")
      assert_equal 1, calls.count { |call| call["method"] == "thread/queue/add" }
    end
  end

  def test_wrong_initialize_id_proves_no_add
    exercise(mode: :wrong_initialize) do |result, calls|
      refute result.fetch("accepted")
      assert result.fetch("pre_submit")
      assert_equal ["initialize"], calls.map { |call| call.fetch("method") }
    end
  end

  def test_decoded_duplicate_response_keys_refuse_without_add
    exercise(mode: :duplicate_initialize) do |result, calls|
      refute result.fetch("accepted")
      assert result.fetch("pre_submit")
      assert_equal ["initialize"], calls.map { |call| call.fetch("method") }
    end
  end

  def test_server_request_is_not_executed
    exercise(mode: :server_request) do |result, calls|
      refute result.fetch("accepted")
      assert result.fetch("pre_submit")
      assert_equal ["initialize"], calls.map { |call| call.fetch("method") }
    end
  end

  def test_oversized_or_invalid_payload_and_nonfinite_deadline_never_write
    client, server = Socket.pair(:UNIX, :STREAM, 0)
    [["x" * 65_537, monotonic + 2], ["invalid\0", monotonic + 2], ["same text", Float::INFINITY]].each do |payload, deadline|
      result = Transport.new.submit(socket: client, thread: THREAD, client_id: CLIENT, payload: payload, deadline: deadline)
      refute result.fetch("accepted")
      assert result.fetch("pre_submit")
      assert_equal :wait_readable, server.read_nonblock(1, exception: false)
    end
  ensure
    client&.close
    server&.close
  end

  def test_expired_original_deadline_never_adds
    client, server = Socket.pair(:UNIX, :STREAM, 0)
    result = Transport.new.submit(socket: client, thread: THREAD, client_id: CLIENT,
      payload: "same text", deadline: monotonic - 1)
    refute result.fetch("accepted")
    assert result.fetch("pre_submit")
    assert_equal :wait_readable, server.read_nonblock(1, exception: false)
  ensure
    client&.close
    server&.close
  end

  private

  def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  def exercise(mode: :success)
    client, server = Socket.pair(:UNIX, :STREAM, 0)
    calls = []
    worker = Thread.new do
      driver = WebSocket::Driver.server(ServerWriter.new(server), max_length: Transport::MESSAGE_LIMIT)
      driver.on(:connect) { driver.start }
      driver.on(:message) do |event|
        call = JSON.parse(event.data)
        calls << call
        case call.fetch("method")
        when "initialize"
          if mode == :duplicate_initialize
            driver.text('{"id":1,"\u0069d":1,"result":{}}')
          elsif mode == :server_request
            driver.text(JSON.generate({"id" => 77, "method" => "item/commandExecution/requestApproval", "params" => {}}))
          else
            driver.text(JSON.generate({"id" => mode == :wrong_initialize ? 999 : call.fetch("id"), "result" => {}}))
          end
        when "thread/queue/add"
          if mode == :lost_reply
            server.close
          else
            params = call.fetch("params")
            queued = {"id" => QUEUED,
              "clientUserMessageId" => mode == :wrong_client ? "foreign" : params.fetch("clientUserMessageId"),
              "input" => mode == :wrong_payload ? [{"type" => "text", "text" => "changed"}] : params.fetch("input")}
            driver.text(JSON.generate({"id" => call.fetch("id"), "result" => {"queuedSubmission" => queued}}))
          end
        end
      end
      until server.closed?
        bytes = server.readpartial(2048)
        driver.parse(bytes)
      end
    rescue EOFError
      nil
    ensure
      server.close unless server.closed?
    end
    result = Transport.new.submit(socket: client, thread: THREAD, client_id: CLIENT,
      payload: "same text", deadline: monotonic + 2)
    client.close
    worker.value
    yield result, calls
  ensure
    client&.close unless client&.closed?
    server&.close unless server&.closed?
    worker&.join(3)
    raise "controlled server remained live" if worker&.alive?
  end
end
