# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "yaml"

describe "AgyClient" do
  before do
    @client = Ace::LLM::Providers::CLI::AgyClient.new
  end

  def success_status
    Struct.new(:success?, :exitstatus).new(true, 0)
  end

  def failure_status
    Struct.new(:success?, :exitstatus).new(false, 1)
  end

  it "provider_name is agy" do
    assert_equal "agy", Ace::LLM::Providers::CLI::AgyClient.provider_name
  end

  it "loads provider defaults with documented aliases" do
    config = YAML.safe_load_file(
      File.expand_path("../../../.ace-defaults/llm/providers/agy.yml", __dir__),
      permitted_classes: [Date],
      aliases: true
    )

    assert_equal "agy:gemini-3.5-flash-medium", config.dig("aliases", "global", "agy")
    assert_equal "gemini-3.5-flash-medium", config.dig("aliases", "model", "flash")
  end

  it "formats system and user messages into a prompt" do
    prompt = @client.send(:format_messages_as_prompt, [
      {role: "system", content: "You are exact"},
      {role: "user", content: "Ping"}
    ])

    assert_includes prompt, "System: You are exact"
    assert_includes prompt, "User: Ping"
  end

  it "builds a JSON print command using the supported agy CLI contract" do
    cmd = @client.send(:build_agy_command, "Ping", {timeout: 45})

    assert_equal "agy", cmd[0]
    assert_includes cmd, "-p"
    assert_includes cmd, "--output-format"
    assert_includes cmd, "json"
    assert_includes cmd, "--model"
    assert_includes cmd, "gemini-3.5-flash-medium"
    refute_includes cmd, "--cwd"
    assert_includes cmd, "--print-timeout"
    assert_includes cmd, "45s"
  end

  it "passes documented session cli args through unchanged" do
    cmd = @client.send(
      :build_agy_command,
      "Continue",
      {cli_args: "--continue --conversation abc-123"}
    )

    assert_includes cmd, "--continue"
    assert_includes cmd, "--conversation"
    assert_includes cmd, "abc-123"
  end

  it "rejects unsupported generation options" do
    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:validate_supported_options!, {temperature: 0.2})
    end

    assert_includes error.message, "temperature"
  end

  it "rejects stream-json stdin mode because generate uses one-shot print mode" do
    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:build_agy_command, "Ping", {cli_args: "--input-format stream-json"})
    end

    assert_includes error.message, "--input-format"
  end

  it "rejects oversized prompts before subprocess launch" do
    client = Ace::LLM::Providers::CLI::AgyClient.new(max_prompt_length: 10)

    error = assert_raises(Ace::LLM::ProviderError) do
      client.send(:build_agy_command, "x" * 11, {})
    end

    assert_includes error.message, "prompt bytesize 11 exceeds configured limit 10"
  end

  it "rejects multibyte prompts that fit the character limit but exceed the byte limit" do
    client = Ace::LLM::Providers::CLI::AgyClient.new(max_prompt_length: 10)

    error = assert_raises(Ace::LLM::ProviderError) do
      client.send(:build_agy_command, "🙂🙂🙂", {})
    end

    assert_includes error.message, "prompt bytesize 12 exceeds configured limit 10"
  end

  it "raises when agy is unavailable" do
    @client.stub(:agy_available?, false) do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:validate_agy_availability!)
      end

      assert_match(/Antigravity CLI not found/, error.message)
    end
  end

  it "parses JSON responses and exposes conversation metadata" do
    response = {
      "conversation_id" => "conv-123",
      "status" => "SUCCESS",
      "response" => "Hello from Antigravity",
      "duration_seconds" => 3.2,
      "num_turns" => 1,
      "usage" => {
        "input_tokens" => 12,
        "output_tokens" => 5,
        "thinking_tokens" => 3,
        "cache_read_tokens" => 2,
        "total_tokens" => 17
      }
    }.to_json

    @client.stub(:agy_available?, true) do
      Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(
        :call,
        lambda { |*_args, **_kwargs| [response, "", success_status] }
      ) do
        result = @client.generate("Hi")
        assert_equal "Hello from Antigravity", result[:text]
        assert_equal "agy", result[:metadata][:provider]
        assert_equal "conv-123", result[:metadata][:conversation_id]
        assert_equal "conv-123", result[:metadata][:session_id]
        assert_equal 17, result[:metadata][:total_tokens]
      end
    end
  end

  it "uses the resolved working directory as the subprocess cwd without passing --cwd" do
    Dir.mktmpdir do |working_dir|
      fake_agy = <<~RUBY
        require "json"
        abort "unsupported --cwd" if ARGV.include?("--cwd")
        puts({status: "SUCCESS", response: Dir.pwd}.to_json)
      RUBY

      @client.stub(:agy_available?, true) do
        result = @client.generate(
          "Hi",
          working_dir: working_dir,
          subprocess_command_prefix: [RbConfig.ruby, "-e", fake_agy, "--"]
        )

        assert_equal working_dir, result[:text]
      end
    end
  end

  it "parses stream-json result envelopes" do
    response = <<~NDJSON
      {"event":"init","conversation_id":"conv-123","init":{"cwd":"/tmp/work"}}
      {"event":"step_update","step_update":{"state":"ACTIVE","step_type":"agent_response","text_delta":"Hello "}}
      {"event":"step_update","step_update":{"state":"DONE","step_type":"agent_response","text_delta":"world"}}
      {"event":"result","result":{"conversation_id":"conv-123","status":"SUCCESS","response":"Hello world","usage":{"input_tokens":10,"output_tokens":4,"total_tokens":14}}}
    NDJSON

    result = @client.send(:parse_agy_response, response, "", success_status, "Prompt")
    assert_equal "Hello world", result[:text]
    assert_equal "conv-123", result[:metadata][:conversation_id]
  end

  it "raises on error envelopes" do
    response = {
      "conversation_id" => "",
      "status" => "ERROR",
      "response" => "",
      "error" => "invalid model selection"
    }.to_json

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_agy_response, response, "", failure_status, "Prompt")
    end

    assert_includes error.message, "invalid model selection"
  end

  it "falls back to plain text output when JSON parsing fails" do
    result = @client.send(:parse_agy_response, "plain text answer", "", success_status, "Prompt")
    assert_equal "plain text answer", result[:text]
    assert_equal "agy", result[:metadata][:provider]
  end
end
