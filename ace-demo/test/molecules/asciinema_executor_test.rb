# frozen_string_literal: true

require_relative "../test_helper"

class AsciinemaExecutorTest < AceDemoTestCase
  class FakeStatus
    def initialize(success, code)
      @success = success
      @code = code
    end

    def success?
      @success
    end

    def exitstatus
      @code
    end
  end

  def setup
    super
    @executor = Ace::Demo::Molecules::AsciinemaExecutor.new
  end

  def test_asciinema_available_false_when_binary_missing
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      refute @executor.asciinema_available?
    end
  end

  def test_run_returns_execution_result_on_success
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["ok", "", FakeStatus.new(true, 0)]
    }) do
      result = @executor.run(["asciinema", "rec", "demo.cast"])
      assert result.success?
      assert_equal "ok", result.stdout
    end
  end

  def test_run_raises_asciinema_not_found
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::AsciinemaNotFoundError) { @executor.run(["asciinema", "rec", "demo.cast"]) }
      assert_includes error.message, "Install:"
    end
  end

  def test_run_raises_asciinema_not_found_with_configured_binary_name
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::AsciinemaNotFoundError) { @executor.run(["asciinema-custom", "rec", "demo.cast"]) }
      assert_includes error.message, "(asciinema-custom)"
    end
  end

  def test_run_raises_execution_error_on_non_zero
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["", "boom", FakeStatus.new(false, 1)]
    }) do
      error = assert_raises(Ace::Demo::AsciinemaExecutionError) { @executor.run(["asciinema", "rec", "demo.cast"]) }
      assert_includes error.message, "boom"
    end
  end

  def test_run_interactive_writes_commands_and_exit
    reader, writer = IO.pipe
    sleeper = Object.new
    sleeps = []
    sleeper.define_singleton_method(:sleep) { |duration| sleeps << duration }
    writer.write("bash-5.3$ ")
    writer.flush

    fake_open3 = Object.new
    fake_open3.define_singleton_method(:capture3) { |_a, *_rest| ["ok", "", FakeStatus.new(true, 0)] }
    fake_pty = Object.new
    pid = Process.pid
    fake_pty.define_singleton_method(:spawn) do |_env, *_cmd, **_options|
      [reader, writer, pid]
    end

    Process.stub(:wait2, [pid, FakeStatus.new(true, 0)]) do
      executor = Ace::Demo::Molecules::AsciinemaExecutor.new(open3: fake_open3, sleeper: sleeper, pty: fake_pty)
      result = executor.run_interactive(
        ["asciinema", "rec", "demo.cast"],
        commands: [
          {command: "echo hi", sleep: 1.5},
          {command: "pwd", sleep: 2.0}
        ],
        env: {"PS1" => "$ "}
      )

      assert result.success?
      assert_equal "bash-5.3$ echo hi\npwd\nexit", result.stdout
      assert_equal [1.5, 2.0], sleeps
    end
  ensure
    reader.close unless reader.closed?
    writer.close unless writer.closed?
  end
end
