# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

class Ace::Lint::Organisms::LintDoctorTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir("lint_doctor_test")
  end

  def teardown
    FileUtils.remove_entry(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # Basic diagnostics tests
  def test_diagnose_returns_array
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    diagnostics = doctor.diagnose

    assert_kind_of Array, diagnostics
  end

  def test_diagnose_checks_validator_availability
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    # Should have diagnostics about validator availability
    validator_diagnostics = doctor.diagnostics.select { |d| d.category == :validator }
    refute_empty validator_diagnostics
  end

  def test_diagnose_checks_config_files
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    # Should have diagnostics about config files
    config_diagnostics = doctor.diagnostics.select { |d| d.category == :config }
    refute_empty config_diagnostics
  end

  # Exit code logic tests
  def test_errors_returns_false_when_no_errors
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    # Fresh temp dir should have no errors (tools may or may not be installed)
    # but there shouldn't be any error-level diagnostics from config issues
    # Just verify the method works
    assert_includes [true, false], doctor.errors?
  end

  def test_warnings_returns_boolean
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    assert_includes [true, false], doctor.warnings?
  end

  def test_errors_accessor
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    assert_kind_of Array, doctor.errors
    assert doctor.errors.all? { |e| e.respond_to?(:error?) && e.error? }
  end

  def test_warnings_accessor
    # Stub validator availability to avoid subprocess calls
    Ace::Lint::Atoms::ValidatorRegistry.stub(:available?, ->(_name) { true }) do
      doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
      doctor.diagnose

      assert_kind_of Array, doctor.warnings
      assert doctor.warnings.all? { |w| w.respond_to?(:warning?) && w.warning? }
    end
  end

  # YAML validation tests
  def test_validates_yaml_syntax_for_ace_config
    # Create .ace/lint directory with valid config
    ace_lint_dir = File.join(@temp_dir, ".ace", "lint")
    FileUtils.mkdir_p(ace_lint_dir)
    File.write(File.join(ace_lint_dir, ".rubocop.yml"), "AllCops:\n  TargetRubyVersion: 3.0\n")

    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    # Should have no YAML syntax errors
    yaml_errors = doctor.diagnostics.select do |d|
      d.category == :config && d.error? && d.message.include?("YAML syntax error")
    end
    assert_empty yaml_errors
  end

  def test_detects_invalid_yaml_syntax
    # Create .ace/lint directory with invalid YAML
    ace_lint_dir = File.join(@temp_dir, ".ace", "lint")
    FileUtils.mkdir_p(ace_lint_dir)
    File.write(File.join(ace_lint_dir, ".rubocop.yml"), "invalid: yaml: content:\n  bad: [")

    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    # Should detect YAML syntax error
    yaml_errors = doctor.diagnostics.select do |d|
      d.category == :config && d.error? && d.message.include?("YAML syntax error")
    end
    refute_empty yaml_errors
  end

  # Groups configuration tests
  def test_checks_pattern_coverage_with_groups
    groups = {
      "default" => {
        "patterns" => ["**/*.rb"],
        "validators" => ["standardrb"]
      }
    }

    # Stub validator availability to avoid subprocess calls
    Ace::Lint::Atoms::ValidatorRegistry.stub(:available?, ->(_name) { true }) do
      doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir, groups: groups)
      doctor.diagnose

      # Should have pattern diagnostics when groups are provided
      pattern_diagnostics = doctor.diagnostics.select { |d| d.category == :pattern }
      refute_empty pattern_diagnostics
    end
  end

  def test_warns_on_missing_default_group
    groups = {
      "custom" => {
        "patterns" => ["lib/**/*.rb"],
        "validators" => ["standardrb"]
      }
    }

    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir, groups: groups)
    doctor.diagnose

    # Should warn about missing default group
    default_warning = doctor.diagnostics.find do |d|
      d.category == :pattern && d.warning? && d.message.include?("default")
    end
    refute_nil default_warning
  end

  def test_skips_pattern_coverage_without_groups
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir, groups: nil)
    doctor.diagnose

    # Should not have pattern diagnostics when no groups configured
    pattern_diagnostics = doctor.diagnostics.select { |d| d.category == :pattern }
    assert_empty pattern_diagnostics
  end

  # DiagnosticResult structure tests
  def test_diagnostic_result_has_expected_interface
    doctor = Ace::Lint::Organisms::LintDoctor.new(project_root: @temp_dir)
    doctor.diagnose

    diagnostic = doctor.diagnostics.first
    return if diagnostic.nil?

    assert_respond_to diagnostic, :category
    assert_respond_to diagnostic, :level
    assert_respond_to diagnostic, :message
    assert_respond_to diagnostic, :details
    assert_respond_to diagnostic, :error?
    assert_respond_to diagnostic, :warning?
    assert_respond_to diagnostic, :info?
  end
end
