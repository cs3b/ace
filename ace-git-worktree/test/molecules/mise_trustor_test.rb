# frozen_string_literal: true

require_relative "../test_helper"

class MiseTrustorTest < Minitest::Test
  def setup
    setup_temp_dir
    @trustor = Ace::Git::Worktree::Molecules::MiseTrustor.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_mise_available_when_command_exists
    # Mock successful mise command
    Open3.stub(:capture3, ["mise 2024.1.1", "", 0]) do
      assert @trustor.mise_available?
    end
  end

  def test_mise_unavailable_when_command_fails
    # Mock failed mise command
    Open3.stub(:capture3, ["", "command not found: mise", 1]) do
      refute @trustor.mise_available?
    end
  end

  def test_mise_version_extraction
    # Mock mise version output
    Open3.stub(:capture3, ["mise 2024.1.1", "", 0]) do
      assert_equal "2024.1.1", @trustor.mise_version
    end
  end

  def test_mise_version_nil_when_unavailable
    # Mock failed mise command
    Open3.stub(:capture3, ["", "command not found: mise", 1]) do
      assert_nil @trustor.mise_version
    end
  end

  def test_trust_worktree_with_no_mise_files
    # Empty directory, no mise.toml files
    result = @trustor.trust_worktree(@temp_dir)

    assert result[:success]
    assert_match(/No mise\.toml files found/, result[:message])
    assert_nil result[:error]
  end

  def test_trust_worktree_with_mise_file
    # Create a mise.toml file
    mise_file = File.join(@temp_dir, "mise.toml")
    File.write(mise_file, "[tools]\nnode = '20'\n")

    # Mock successful mise trust command
    Open3.stub(:capture3, ["Trusted /tmp/test", "", 0]) do
      result = @trustor.trust_worktree(@temp_dir)

      assert result[:success]
      assert_match(/Trusted 1 mise\.toml file/, result[:message])
      assert_equal [mise_file], result[:trusted_files]
    end
  end

  def test_trust_worktree_handles_mise_unavailable
    # Create a mise.toml file
    mise_file = File.join(@temp_dir, "mise.toml")
    File.write(mise_file, "[tools]\nnode = '20'\n")

    # Mock mise as unavailable
    Open3.stub(:capture3, ["", "command not found: mise", 1]) do
      result = @trustor.trust_worktree(@temp_dir)

      assert result[:success]
      assert_match(/mise not available, skipping trust/, result[:message])
    end
  end

  def test_trust_worktree_with_nonexistent_directory
    result = @trustor.trust_worktree("/nonexistent/directory")

    refute result[:success]
    assert_match(/does not exist/, result[:error])
  end

  def test_trust_specific_mise_file
    # Create a mise.toml file
    mise_file = File.join(@temp_dir, "mise.toml")
    File.write(mise_file, "[tools]\nnode = '20'\n")

    # Mock successful mise trust command
    Open3.stub(:capture3, ["Trusted /tmp/test", "", 0]) do
      result = @trustor.trust_mise_file(mise_file)

      assert result[:success]
      assert_match(/trusted successfully/, result[:message])
      assert_equal mise_file, result[:file]
    end
  end

  def test_trust_specific_file_handles_mise_unavailable
    # Create a mise.toml file
    mise_file = File.join(@temp_dir, "mise.toml")
    File.write(mise_file, "[tools]\nnode = '20'\n")

    # Mock mise as unavailable
    Open3.stub(:capture3, ["", "command not found: mise", 1]) do
      result = @trustor.trust_mise_file(mise_file)

      assert result[:success]
      assert_match(/mise not available, skipping trust/, result[:message])
    end
  end

  def test_find_mise_config_files
    # Create mise.toml files
    File.write(File.join(@temp_dir, "mise.toml"), "[tools]\nnode = '20'\n")
    subdir = File.join(@temp_dir, "subdir")
    Dir.mkdir(subdir)
    File.write(File.join(subdir, "mise.toml"), "[tools]\npython = '3.11'\n")

    # Non-recursive search
    files = @trustor.find_mise_config_files(@temp_dir, recursive: false)
    assert_equal 1, files.length
    assert files.first.include?("mise.toml")

    # Recursive search
    files = @trustor.find_mise_config_files(@temp_dir, recursive: true)
    assert_equal 2, files.length
  end

  def test_mise_file_trusted_check
    mise_file = File.join(@temp_dir, "mise.toml")
    File.write(mise_file, "[tools]\nnode = '20'\n")

    # Mock mise trust list command
    Open3.stub(:capture3, [File.dirname(mise_file), "", 0]) do
      assert @trustor.mise_file_trusted?(mise_file)
    end
  end

  def test_trust_multiple_worktrees
    # Create directories with mise.toml files
    dir1 = File.join(@temp_dir, "worktree1")
    dir2 = File.join(@temp_dir, "worktree2")
    [dir1, dir2].each { |dir| Dir.mkdir(dir) }

    File.write(File.join(dir1, "mise.toml"), "[tools]\nnode = '20'\n")
    File.write(File.join(dir2, "mise.toml"), "[tools]\npython = '3.11'\n")

    # Mock successful mise trust commands
    Open3.stub(:capture3, ["Trusted", "", 0]) do
      result = @trustor.trust_multiple_worktrees([dir1, dir2])

      assert result[:success]
      assert_equal 2, result[:trusted].length
      assert_empty result[:failed]
    end
  end

  def test_security_validation_blocks_dangerous_arguments
    dangerous_inputs = [
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "path\x00with\x00nulls",
      "path\nwith\nnewlines",
      "path\rwith\rcarriage\rreturns"
    ]

    dangerous_inputs.each do |dangerous_input|
      # Mock command execution to validate arguments
      trustor = Ace::Git::Worktree::Molecules::MiseTrustor.new

      assert_raises(ArgumentError, /dangerous characters/) do
        # The validation should happen during argument sanitization
        trustor.send(:sanitize_arguments, [dangerous_input])
      end
    end
  end

  def test_command_validation_blocks_unallowed_commands
    trustor = Ace::Git::Worktree::Molecules::MiseTrustor.new

    assert_raises(ArgumentError, /Command not allowed/) do
      trustor.send(:validate_command, "rm")
    end

    assert_raises(ArgumentError, /Command not allowed/) do
      trustor.send(:validate_command, "evil-command")
    end

    # Should allow mise command
    assert_nothing_raised do
      trustor.send(:validate_command, "mise")
    end
  end

  def test_argument_length_validation
    trustor = Ace::Git::Worktree::Molecules::MiseTrustor.new

    # Create an argument longer than MAX_ARG_LENGTH
    long_arg = "a" * 1001  # MAX_ARG_LENGTH is 1000

    assert_raises(ArgumentError, /too long/) do
      trustor.send(:sanitize_arguments, [long_arg])
    end
  end

  def test_safe_directory_validation
    trustor = Ace::Git::Worktree::Molecules::MiseTrustor.new

    # Should raise error for non-existent directory
    assert_raises(ArgumentError, /does not exist/) do
      trustor.send(:execute_command, "mise", "trust", chdir: "/nonexistent/directory")
    end
  end

  def test_command_timeout_handling
    # Mock command timeout
    Open3.stub(:capture3) do |*args|
      raise Open3::CommandTimeout
    end

    result = @trustor.trust_worktree(@temp_dir)
    refute result[:success]
    assert_match(/timed out/, result[:error])
  end
end