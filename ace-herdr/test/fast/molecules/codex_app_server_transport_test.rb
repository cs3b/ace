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

  def test_real_driver_reads_completed_exact_client_without_publishing_content
    exercise(operation: :observe) do |result, calls|
      assert_equal "consumed", result.fetch("outcome")
      reference = result.fetch("native_reference")
      assert_equal THREAD, reference.fetch("thread_id")
      assert_equal CLIENT, reference.fetch("client_user_message_id")
      assert_equal "item-1", reference.fetch("item_id")
      assert_equal Digest::SHA256.hexdigest("same text"), reference.fetch("payload_sha256")
      refute_includes JSON.generate(result), "same text"
      assert_equal %w[initialize initialized thread/read], calls.map { |call| call.fetch("method") }
      assert_equal({"threadId" => THREAD, "includeTurns" => true}, calls.last.fetch("params"))
    end
  end

  def test_missing_partial_malformed_or_ambiguous_history_never_proves_consumption
    %i[wrong_thread wrong_version same_text_only wrong_read_payload in_progress failed_turn interrupted_turn
      summary not_loaded paginated missing_turns empty_turns duplicate_client duplicate_turn duplicate_item
      malformed_content missing_item_id].each do |mode|
      exercise(operation: :observe, mode: mode) do |result, calls|
        assert_equal "uncertain", result.fetch("outcome"), mode.to_s
        refute result.key?("native_reference"), mode.to_s
        assert_equal 1, calls.count { |call| call["method"] == "thread/read" }, mode.to_s
        refute calls.any? { |call| call["method"].start_with?("thread/queue/") }, mode.to_s
      end
    end
  end

  def test_lost_malformed_oversized_reply_and_expired_read_budget_remain_uncertain
    %i[lost_read_reply duplicate_read_reply oversized_read_reply no_read_reply server_request].each do |mode|
      exercise(operation: :observe, mode: mode) do |result, calls|
        assert_equal "uncertain", result.fetch("outcome"), mode.to_s
        refute result.key?("native_reference")
        refute calls.any? { |call| call["method"].start_with?("thread/queue/") }
      end
    end
  end

  def test_expired_or_invalid_observation_never_writes
    client, server = Socket.pair(:UNIX, :STREAM, 0)
    [[CLIENT, monotonic - 1], [CLIENT, Float::INFINITY], ["foreign", monotonic + 2]].each do |id, deadline|
      result = Transport.new.observe(socket: client, thread: THREAD, client_id: id,
        payload_sha256: Digest::SHA256.hexdigest("same text"), deadline: deadline)
      assert_equal "uncertain", result.fetch("outcome")
      assert_equal :wait_readable, server.read_nonblock(1, exception: false)
    end
  ensure
    client&.close
    server&.close
  end

  private

  def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  # Retained 0.159.3 schema: userMessage.content/clientId, Turn.itemsView
  # and Thread.historyMode. Equal text without the exact ID is unrelated.
  def read_history(mode)
    item = {"id" => "item-1", "type" => "userMessage", "clientId" => CLIENT,
      "content" => [{"type" => "text", "text" => "same text", "text_elements" => []}]}
    unrelated = item.merge("id" => "item-2", "clientId" => nil)
    turn = {"id" => "00000000-0000-0000-0000-000000000003", "status" => "completed",
      "error" => nil, "itemsView" => "full", "items" => [item, unrelated]}
    history = {"id" => THREAD, "cliVersion" => "0.159.3", "historyMode" => "legacy", "turns" => [turn]}
    case mode
    when :wrong_thread then history["id"] = QUEUED
    when :wrong_version then history["cliVersion"] = "0.159.4"
    when :same_text_only then item.delete("clientId")
    when :wrong_read_payload then item.fetch("content").first["text"] = "changed"
    when :in_progress then turn["status"] = "inProgress"
    when :failed_turn then turn["status"] = "failed"
    when :interrupted_turn then turn["status"] = "interrupted"
    when :summary then turn["itemsView"] = "summary"
    when :not_loaded then turn["itemsView"] = "notLoaded"
    when :paginated then history["historyMode"] = "paginated"
    when :missing_turns then history.delete("turns")
    when :empty_turns then history["turns"] = []
    when :duplicate_client then unrelated["clientId"] = CLIENT
    when :duplicate_turn then history["turns"] << JSON.parse(JSON.generate(turn))
    when :duplicate_item then unrelated["id"] = item.fetch("id")
    when :malformed_content then item["content"] = ["not an input"]
    when :missing_item_id then item.delete("id")
    end
    {"thread" => history}
  end

  def exercise(mode: :success, operation: :submit)
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
        when "thread/read"
          if mode == :lost_read_reply
            server.close
          elsif mode == :duplicate_read_reply
            driver.text('{"id":2,"result":{},"\u0072esult":{}}')
          elsif mode == :oversized_read_reply
            driver.text(JSON.generate({"id" => call.fetch("id"), "result" => {"text" => "x" * Transport::MESSAGE_LIMIT}}))
          elsif mode != :no_read_reply
            driver.text(JSON.generate({"id" => call.fetch("id"), "result" => read_history(mode)}))
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
    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      nil
    ensure
      server.close unless server.closed?
    end
    result = if operation == :observe
      Transport.new.observe(socket: client, thread: THREAD, client_id: CLIENT,
        payload_sha256: Digest::SHA256.hexdigest("same text"), deadline: monotonic + 0.5)
    else
      Transport.new.submit(socket: client, thread: THREAD, client_id: CLIENT,
        payload: "same text", deadline: monotonic + 2)
    end
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
