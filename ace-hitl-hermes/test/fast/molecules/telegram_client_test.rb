# frozen_string_literal: true

require "test_helper"

class TelegramClientTest < AceHermesTestCase
  T = Ace::Hitl::Hermes::Transport

  def with_client(response_status: 200, response_body: nil)
    with_hermes_dir do |folder|
      token = File.join(folder, "token")
      File.write(token, "123:controlled_token")
      File.chmod(0o600, token)
      calls = []
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("sendMessage") do |env|
          calls << JSON.parse(env.body)
          [response_status, {}, response_body || JSON.generate({"ok" => true, "result" => {
            "chat" => {"id" => -424242}, "message_id" => 100}})]
        end
        stub.post("getUpdates") do |env|
          calls << JSON.parse(env.body)
          [200, {}, JSON.generate({"ok" => true, "result" => []})]
        end
      end
      connection = Faraday.new { |f| f.adapter :test, stubs }
      yield T::Telegram.new(token_file: token, connection: connection), calls, token
    end
  end

  def test_api_shapes_send_identity_and_bounded_poll_cursor
    with_client do |client, calls, _|
      ack = client.call({"chat_id" => "-424242"}, "Proceed?")
      assert_equal({"success" => true, "chat_id" => "-424242", "message_id" => "100"}, ack)
      assert_empty client.updates(offset: 42)
      assert_equal({"chat_id" => "-424242", "text" => "Proceed?"}, calls[0])
      assert_equal 42, calls[1]["offset"]
      assert_equal ["message"], calls[1]["allowed_updates"]
      refute_includes JSON.generate(calls), "controlled_token"
    end
  end

  def test_definite_api_refusal_and_malformed_response_are_classified_without_secret_errors
    with_client(response_status: 400, response_body: '{"ok":false,"description":"controlled_token"}') do |client, calls, _|
      error = assert_raises(T::SubmitFailed) { client.call({"chat_id" => "-424242"}, "Proceed?") }
      refute_includes error.message, "controlled_token"
      assert_equal 1, calls.size
    end
    with_client(response_body: "controlled_token") do |client, _, _|
      error = assert_raises(Ace::Hitl::Hermes::ContractError) { client.call({"chat_id" => "-424242"}, "Proceed?") }
      refute_includes error.message, "controlled_token"
    end
  end

  def test_token_file_permissions_are_required_before_transport_setup
    with_client do |_, _, token|
      File.chmod(0o644, token)
      assert_raises(Ace::Hitl::Hermes::ContractError) { T::Telegram.new(token_file: token) }
    end
  end
end
