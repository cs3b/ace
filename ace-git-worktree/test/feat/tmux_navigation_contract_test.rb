# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTmuxContractTest < Minitest::Test
  include TestHelper

  def setup
    setup_temp_dir
    @original_path = ENV["PATH"]
    @original_log_path = ENV["ACE_FAKE_TMUX_INVOCATION_LOG"]

    @fake_bin = File.join(@temp_dir, "bin")
    @fake_tmux_script = File.join(@fake_bin, "ace-tmux")
    @fake_tmux_invocation_log = File.join(@temp_dir, "ace-tmux.invocation")

    FileUtils.mkdir_p(@fake_bin)
    File.write(@fake_tmux_script, fake_ace_tmux_script_content)
    FileUtils.chmod(0o755, @fake_tmux_script)

    ENV["ACE_FAKE_TMUX_INVOCATION_LOG"] = @fake_tmux_invocation_log
    ENV["PATH"] = [@fake_bin, @original_path].compact.join(":")
  end

  def teardown
    ENV["PATH"] = @original_path
    if @original_log_path
      ENV["ACE_FAKE_TMUX_INVOCATION_LOG"] = @original_log_path
    else
      ENV.delete("ACE_FAKE_TMUX_INVOCATION_LOG")
    end
    teardown_temp_dir
  end

  def test_tmux_command_contract_for_task_create_uses_start_subcommand
    original_tmux = ENV["TMUX"]
    ENV.delete("TMUX")

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree"]
    }, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)
    Kernel.stub(:exec, ->(*args) { Kernel.system(*args) }) do
      command.stub(:check_task_dependency_availability, {available: true, message: "mocked"}) do
        command.stub(:tmux_enabled?, true) do
          result = command.run(["--task", "081"])
          assert_equal 0, result
        end
      end
    end

    assert_equal "#{@fake_tmux_script}\nstart\n--root\n/path/to/worktree", invocation_log
    mock_worktree_manager.verify
  ensure
    if original_tmux
      ENV["TMUX"] = original_tmux
    else
      ENV.delete("TMUX")
    end
  end

  def test_tmux_command_contract_for_pr_create_uses_start_subcommand
    original_tmux = ENV["TMUX"]
    ENV.delete("TMUX")

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_pr, {
      success: true,
      pr_number: 26,
      pr_title: "Add authentication feature",
      worktree_path: "/path/to/worktree",
      branch: "pr-26",
      tracking: "origin/feature/auth",
      directory_name: "ace-pr-26"
    }, [Integer, Hash, Hash])

    fake_metadata = {
      success: true,
      metadata: {
        "number" => 26,
        "title" => "Add authentication feature",
        "headRefName" => "feature/auth",
        "baseRefName" => "main",
        "isCrossRepository" => false,
        "headRepositoryOwner" => {"login" => "owner"}
      }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, true) do
        Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_metadata, fake_metadata) do
          command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)
          Kernel.stub(:exec, ->(*args) { Kernel.system(*args) }) do
            command.stub(:tmux_enabled?, true) do
              result = command.run(["--pr", "26"])
              assert_equal 0, result
            end
          end
        end
      end
    end

    assert_equal "#{@fake_tmux_script}\nstart\n--root\n/path/to/worktree", invocation_log
    mock_worktree_manager.verify
  ensure
    if original_tmux
      ENV["TMUX"] = original_tmux
    else
      ENV.delete("TMUX")
    end
  end

  def test_tmux_command_contract_for_task_create_uses_window_subcommand_when_in_tmux
    original_tmux = ENV["TMUX"]
    ENV["TMUX"] = "/tmp/tmux-1000,12345,0"

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree"]
    }, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)
    Kernel.stub(:exec, ->(*args) { Kernel.system(*args) }) do
      command.stub(:check_task_dependency_availability, {available: true, message: "mocked"}) do
        command.stub(:tmux_enabled?, true) do
          result = command.run(["--task", "081"])
          assert_equal 0, result
        end
      end
    end

    assert_equal "#{@fake_tmux_script}\nwindow\n--root\n/path/to/worktree", invocation_log
    mock_worktree_manager.verify
  ensure
    if original_tmux
      ENV["TMUX"] = original_tmux
    else
      ENV.delete("TMUX")
    end
  end

  private

  def fake_ace_tmux_script_content
    <<~RUBY
      #!/usr/bin/env ruby
      require "fileutils"

      FileUtils.mkdir_p(File.dirname(ENV["ACE_FAKE_TMUX_INVOCATION_LOG"]))
      File.write(ENV["ACE_FAKE_TMUX_INVOCATION_LOG"], [ $0, *ARGV ].join("\\n"))
      exit 0
    RUBY
  end

  def invocation_log
    File.read(@fake_tmux_invocation_log)
  end
end
