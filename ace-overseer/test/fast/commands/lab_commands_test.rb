# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative "../../test_helper"

class LabCommandsTest < AceOverseerTestCase
  class FakeLabClient
    attr_reader :calls

    def initialize(result: "ok", error: nil)
      @result = result
      @error = error
      @calls = []
    end

    def call(*arguments, **options)
      @calls << {arguments: arguments, options: options}
      raise @error if @error

      @result
    end
  end

  class TtyInput
    def tty?
      true
    end

    def read
      raise "interactive input must not be read"
    end
  end

  def test_projects_and_agents_forward_json_commands
    projects = FakeLabClient.new(result: [{"name" => "ace"}])
    agents = FakeLabClient.new(result: [{"name" => "builder-codex"}])

    capture_io { Ace::Overseer::CLI::Commands::Projects.new(client: projects).call }
    capture_io { Ace::Overseer::CLI::Commands::Agents.new(client: agents).call }

    assert_equal %w[project list --json], projects.calls.first[:arguments]
    assert_equal %w[agents --json], agents.calls.first[:arguments]
  end

  def test_prompt_forwards_stdin_without_process_argument
    client = FakeLabClient.new
    command = Ace::Overseer::CLI::Commands::Prompt.new(client: client, input: StringIO.new("review this\n"))

    capture_io { command.call(work: "W321") }

    assert_equal %w[work prompt W321], client.calls.first[:arguments]
    assert_equal "review this\n", client.calls.first[:options][:stdin_data]
    assert_equal false, client.calls.first[:options][:json]
  end

  def test_prompt_rejects_tty_and_blank_stdin
    tty_error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Overseer::CLI::Commands::Prompt.new(client: FakeLabClient.new, input: TtyInput.new).call(work: "W321")
    end
    assert_equal "prompt text is required via --file or stdin", tty_error.message

    blank_error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Overseer::CLI::Commands::Prompt.new(client: FakeLabClient.new, input: StringIO.new(" \n\t")).call(work: "W321")
    end
    assert_equal "prompt text must contain non-whitespace characters", blank_error.message
  end

  def test_prompt_reads_direct_file_without_reading_tty
    client = FakeLabClient.new
    command = Ace::Overseer::CLI::Commands::Prompt.new(client: client, input: TtyInput.new)

    Dir.mktmpdir("overseer-prompt") do |dir|
      path = File.join(dir, "prompt.md")
      File.write(path, "continue safely\n")
      capture_io { command.call(work: "W321", file: path) }
    end

    assert_equal "continue safely\n", client.calls.first[:options][:stdin_data]
  end

  def test_review_and_stop_forward_exact_work_arguments
    review = FakeLabClient.new
    stop = FakeLabClient.new

    capture_io { Ace::Overseer::CLI::Commands::Review.new(client: review).call(work: "W321", pr: 3) }
    capture_io { Ace::Overseer::CLI::Commands::Stop.new(client: stop).call(work: "W321") }

    assert_equal ["work", "review", "W321", "--pr", 3], review.calls.first[:arguments]
    assert_equal %w[work stop W321], stop.calls.first[:arguments]
  end

  def test_lab_command_errors_are_wrapped_for_cli_users
    client = FakeLabClient.new(error: Ace::Overseer::Error.new("Lab unavailable"))

    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Overseer::CLI::Commands::Stop.new(client: client).call(work: "W321")
    end

    assert_equal "Lab unavailable", error.message
  end
end
