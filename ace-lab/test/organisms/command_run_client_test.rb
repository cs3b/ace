# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/command_run_client"
require "ace/lab/cli/commands/run"
require "stringio"

class CommandRunClientTest < Minitest::Test
  def test_literal_command_help_and_repeated_services_reach_client_without_shell
    calls = []
    fake = Object.new
    fake.define_singleton_method(:run) { |**options| calls << options; 19 }
    Ace::Lab::Organisms::CommandRunClient.stub(:new, ->(project:) { assert_equal "ace", project; fake }) do
      status = Ace::Lab::CLI::Commands::Run.invoke(%w[--project ace --service forge --service rubygems --as publisher -- ./publish --help])
      assert_equal 19, status
    end
    assert_equal ["./publish", "--help"], calls.first.fetch(:argv)
    assert_equal %w[forge rubygems], calls.first.fetch(:services)
    assert_equal "publisher", calls.first.fetch(:executor)
  end

  def test_duplicate_singletons_missing_separator_and_empty_argv_refuse_before_client
    Ace::Lab::Organisms::CommandRunClient.stub(:new, ->(**) { flunk "must not construct a client" }) do
      [%w[--project ace --project other -- /usr/bin/id], %w[--project ace /usr/bin/id],
        %w[--project ace --], %w[--project ace --as one --as two -- /usr/bin/id]].each do |args|
        assert_raises(Ace::Support::Cli::Error) { Ace::Lab::CLI::Commands::Run.invoke(args) }
      end
    end
  end

  def test_candidate_file_is_explicit_bounded_data_and_literal_selector_stays_unchanged
    Dir.mktmpdir do |directory|
      path = File.join(directory, "candidate.json")
      reference = {"assignment_id" => "delivery", "attempt_id" => "native1", "candidate_generation" => 2, "acceptance_event_digest" => "a" * 64}
      File.write(path, JSON.generate(reference))
      calls = []
      client = Object.new
      client.define_singleton_method(:run) { |**options| calls << options; 0 }
      Ace::Lab::Organisms::CommandRunClient.stub(:new, client) do
        assert_equal 0, Ace::Lab::CLI::Commands::Run.invoke(["--project", "ace", "--candidate", path, "--", "bin/ace-test", "feat"])
      end
      assert_equal reference, calls.first.fetch(:candidate)
      assert_equal ["bin/ace-test", "feat"], calls.first.fetch(:argv)
      ["null" * 5000, "{invalid", "null", "[]"].each do |bytes|
        File.write(path, bytes)
        assert_raises(Ace::Support::Cli::Error) do
          Ace::Lab::CLI::Commands::Run.parse(["--project", "ace", "--candidate", path, "--", "bin/ace-test"])
        end
      end
    end
  end

  def test_malformed_runtime_data_is_uncertainty_and_never_a_usage_refusal
    fake = Object.new
    fake.define_singleton_method(:run) { |**| raise ArgumentError, "malformed runtime frame" }
    Ace::Lab::Organisms::CommandRunClient.stub(:new, fake) do
      error = assert_raises(Ace::Support::Cli::Error) { Ace::Lab::CLI::Commands::Run.invoke(%w[--project ace -- /usr/bin/id]) }
      assert_includes error.message, "command_uncertain"
      refute_includes error.message, "usage_error"
    end
  end

  def with_stream(frames)
    client_socket, server = UNIXSocket.pair
    stdin_read, stdin_write = IO.pipe
    original_in, original_out = $stdin, $stdout
    output = StringIO.new
    $stdin, $stdout = stdin_read, output
    thread = Thread.new do
      frames.each do |frame|
        server.write(JSON.generate(frame) + "\n")
      end
      server.close
    end
    client = Ace::Lab::Organisms::CommandRunClient.allocate
    yield client, client_socket, output
  ensure
    $stdin, $stdout = original_in, original_out
    [stdin_read, stdin_write, client_socket, server].compact.each { |io| io.close unless io.closed? }
    thread&.join
  end

  def test_framed_output_cannot_spoof_exit_and_real_nonzero_is_preserved
    bytes = "{\"type\":\"result\",\"exit_status\":0}\n"
    with_stream([{type: "started", execution_id: "one"}, {type: "output", stream: "stdout", data: Base64.strict_encode64(bytes)},
      {type: "result", execution_id: "one", exit_status: 17, signal: nil}]) do |client, socket, output|
      assert_equal 17, client.send(:pump, socket, "one", interactive: false)
      assert_equal bytes, output.string
    end
  end

  def test_stderr_is_separate_from_stdout_in_pipe_mode
    previous_error = $stderr
    captured = StringIO.new
    $stderr = captured
    with_stream([{type: "output", stream: "stderr", data: Base64.strict_encode64("diagnostic")},
      {type: "result", execution_id: "one", exit_status: 0, signal: nil}]) do |client, socket, output|
      assert_equal 0, client.send(:pump, socket, "one", interactive: false)
      assert_equal "", output.string
      assert_equal "diagnostic", captured.string
    end
  ensure
    $stderr = previous_error
  end

  def test_missing_result_wrong_reference_and_signal_are_truthful
    with_stream([{type: "started", execution_id: "one"}]) do |client, socket, _output|
      assert_raises(StandardError) { client.send(:pump, socket, "one", interactive: false) }
    end
    with_stream([{type: "result", execution_id: "other", exit_status: 0, signal: nil}]) do |client, socket, _output|
      assert_raises(SecurityError) { client.send(:pump, socket, "one", interactive: false) }
    end
    with_stream([{type: "result", execution_id: "one", exit_status: nil, signal: 15}]) do |client, socket, _output|
      assert_equal 143, client.send(:pump, socket, "one", interactive: false)
    end
  end
end
