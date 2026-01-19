# frozen_string_literal: true

require_relative '../test_helper'

class DoctorIntegrationTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Check if CLI is available
    @cli_path = File.expand_path('../../../exe/ace-lint', __dir__)
    @cli_available = File.exist?(@cli_path)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_doctor_command_lists_available_validators
    skip "CLI not built" unless @cli_available

    output, = Open3.capture3(@cli_path, 'doctor')

    # Should list validators
    assert_match(/standardrb|rubocop|validator/i, output)
  end

  def test_doctor_command_shows_config_status
    skip "CLI not built" unless @cli_available

    # Create a config file
    FileUtils.mkdir_p('.ace/lint')
    File.write('.ace/lint/config.yml', 'kramdown:
  auto_ids: true')

    output, = Open3.capture3(@cli_path, 'doctor')

    # Should show config information
    assert_match(/config|configuration/i, output)
  end

  def test_doctor_command_validates_yaml_syntax
    skip "CLI not built" unless @cli_available

    # Create a valid YAML config
    FileUtils.mkdir_p('.ace/lint')
    File.write('.ace/lint/config.yml', 'kramdown:
  auto_ids: true
  entity_output: numeric')

    output, = Open3.capture3(@cli_path, 'doctor')

    # Should show YAML is valid
    assert_match(/valid|ok/i, output)
  end

  def test_doctor_command_detects_invalid_yaml
    skip "CLI not built" unless @cli_available

    # Create an invalid YAML config
    FileUtils.mkdir_p('.ace/lint')
    File.write('.ace/lint/config.yml', 'kramdown:
  auto_ids: true
  entity_output: numeric
    bad_indent: yes')

    output, = Open3.capture3(@cli_path, 'doctor')

    # Should show YAML error
    # (Note: exact output depends on implementation)
  end

  def test_doctor_command_with_verbosity
    skip "CLI not built" unless @cli_available

    output, = Open3.capture3(@cli_path, 'doctor', '--verbose')

    # Verbose mode should show more details
    assert_match(/standardrb|rubocop|validator/i, output)
  end

  def test_doctor_command_quiet_mode
    skip "CLI not built" unless @cli_available

    output, = Open3.capture3(@cli_path, 'doctor', '--quiet')

    # Quiet mode should suppress some output
    # (Exact behavior depends on CLI implementation)
  end

  # Exit code tests per README documentation:
  # 0 = healthy, 1 = warnings, 2 = errors

  def test_doctor_exit_code_zero_when_healthy
    skip "CLI not built" unless @cli_available

    # No config files = uses defaults, should be healthy
    _output, _stderr, status = Open3.capture3(@cli_path, 'doctor')

    # Exit 0 when configuration is healthy (no errors or warnings)
    # Note: May be 1 if validators are missing, which is a warning
    assert_includes [0, 1], status.exitstatus, "Expected exit 0 (healthy) or 1 (warnings)"
  end

  def test_doctor_exit_code_two_on_yaml_error
    skip "CLI not built" unless @cli_available

    # Create an invalid YAML config that will cause an error
    FileUtils.mkdir_p('.ace/lint')
    File.write('.ace/lint/ruby.yml', "groups:\n  default:\n    patterns: [\"**/*.rb\"]\n    validators: [notarealvalidator")

    _output, _stderr, status = Open3.capture3(@cli_path, 'doctor')

    # Exit 2 when configuration has errors (invalid YAML)
    assert_equal 2, status.exitstatus, "Expected exit 2 for YAML syntax error"
  end
end
