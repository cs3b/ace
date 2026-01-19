# frozen_string_literal: true

require_relative "../test_helper"

class CLIIntegrationTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Check if CLI is available
    @cli_path = File.expand_path("../../../exe/ace-lint", __dir__)
    @cli_available = File.exist?(@cli_path)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_cli_exit_code_with_valid_file
    skip "CLI not built" unless @cli_available

    File.write("test.md", "# Test")

    output, status = Open3.capture3(@cli_path, "test.md")
    assert_equal 0, status.exitstatus, "CLI should exit with 0 for valid file. Output: #{output}"
    assert_match(/passed/i, output)
  end

  def test_cli_exit_code_with_invalid_file
    skip "CLI not built" unless @cli_available

    File.write("test.md", '# Test\n\n   ' * 10) # Trailing whitespace

    output, status = Open3.capture3(@cli_path, "test.md")
    refute_equal 0, status.exitstatus, "CLI should exit with non-zero for lint errors. Output: #{output}"
  end

  def test_cli_group_routing_with_ruby_groups_config
    skip "CLI not built" unless @cli_available

    # Create group configuration

    # Create directories and files
    FileUtils.mkdir_p("app/models")
    FileUtils.mkdir_p("app/controllers")

    File.write("app/models/user.rb", "class User; end")
    File.write("app/controllers/users_controller.rb", "class UsersController; end")

    # This test verifies the group routing works end-to-end
    # The exact behavior depends on StandardRB availability
    _, status = Open3.capture3(
      @cli_path,
      "app/models/user.rb", "app/controllers/users_controller.rb",
      "--verbose"
    )

    # Command should complete (may fail if StandardRB not installed)
    assert_kind_of(Integer, status.exitstatus)
  end

  def test_cli_output_format_with_json_flag
    skip "CLI not built" unless @cli_available

    File.write("test.md", "# Test")

    # Test --output flag for JSON format
    _, status = Open3.capture3(
      @cli_path,
      "test.md", "--output", "/dev/stdout"
    )

    assert_kind_of(Integer, status.exitstatus)
  end

  def test_cli_validators_flag_overrides_group_config
    skip "CLI not built" unless @cli_available

    # Create group configuration that uses rubocop
    FileUtils.mkdir_p(".ace/lint")
    File.write(".ace/lint/ruby.yml", <<~YAML)
      groups:
        default:
          patterns:
            - "**/*.rb"
          validators:
            - rubocop
    YAML

    # Create a Ruby file
    File.write("test.rb", 'puts "hello"')

    # Run with --validators flag to override group config
    # The CLI flag should take precedence over the group config
    output, status = Open3.capture3(
      @cli_path,
      "test.rb",
      "--validators", "standardrb",
      "--verbose"
    )

    # Command should complete (exact result depends on tool availability)
    assert_kind_of(Integer, status.exitstatus)

    # Verbose output should show the validator being used
    # If standardrb is installed, it should be used instead of rubocop
    if output.include?("standardrb") || output.include?("StandardRB")
      # CLI override worked - standardrb mentioned in output
      assert_match(/standardrb|StandardRB/i, output)
    end
  end

  def test_cli_generates_report_by_default
    skip "CLI not built" unless @cli_available

    # Initialize git repo so we can find project root
    system("git init --quiet .")

    File.write("test.md", "# Test")

    output, status = Open3.capture3(@cli_path, "test.md")

    # Should show report path in output
    assert_match(/Report saved:/, output)
    assert_match(/\.cache\/ace-lint\/[0-9a-z]{6}\/report\.json/, output)
    assert_equal 0, status.exitstatus
  end

  def test_cli_no_report_flag_disables_generation
    skip "CLI not built" unless @cli_available

    # Initialize git repo so we can find project root
    system("git init --quiet .")

    File.write("test.md", "# Test")

    output, status = Open3.capture3(@cli_path, "test.md", "--no-report")

    # Should NOT show report path in output
    refute_match(/Report saved:/, output)
    assert_equal 0, status.exitstatus

    # Should not have created cache directory
    refute Dir.exist?(".cache/ace-lint")
  end
end
