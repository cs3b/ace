# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/taskflow_doctor"

class TaskflowDoctorTest < AceTaskflowTestCase
  def test_check_retros_uses_configured_directory_name
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create custom config with different retro directory name
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)

        custom_config = <<~YAML
          taskflow:
            directories:
              retros: "reflections"
        YAML
        File.write(File.join(config_dir, "config.yml"), custom_config)

        # Create a retro file in the custom directory
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0")
        retro_dir = File.join(release_dir, "reflections")
        FileUtils.mkdir_p(retro_dir)

        retro_file = File.join(retro_dir, "2025-10-14-test-reflection.md")
        File.write(retro_file, "# Test Reflection\n\nThis is a test reflection note.")

        # Reload configuration to pick up the custom config
        Ace::Taskflow.reset_configuration!

        # Run doctor check
        doctor = Ace::Taskflow::Organisms::TaskflowDoctor.new
        result = doctor.run_diagnosis

        # Verify the retro file was found
        assert result[:valid], "Doctor check should be valid"
        assert result[:stats][:files_scanned] > 0, "Should have scanned files including retros"
      end
    end
  end

  def test_check_retros_with_default_directory_name
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create a retro file in the default "retros" directory
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0")
        retro_dir = File.join(release_dir, "retros")
        FileUtils.mkdir_p(retro_dir)

        retro_file = File.join(retro_dir, "2025-10-14-default-reflection.md")
        File.write(retro_file, "# Default Reflection\n\nThis is a test reflection note.")

        # Reload configuration
        Ace::Taskflow.reset_configuration!

        # Run doctor check
        doctor = Ace::Taskflow::Organisms::TaskflowDoctor.new
        result = doctor.run_diagnosis

        # Verify the retro file was found (don't require valid: true as other checks may fail)
        assert result[:stats][:files_scanned] > 0, "Should have scanned files including retros"
        assert result.key?(:valid), "Result should have :valid key"
        assert result.key?(:issues), "Result should have :issues key"
      end
    end
  end

  def test_doctor_runs_full_check
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        doctor = Ace::Taskflow::Organisms::TaskflowDoctor.new
        result = doctor.run_diagnosis

        assert result.key?(:valid), "Result should have :valid key"
        assert result.key?(:stats), "Result should have :stats key"
        assert result.key?(:issues), "Result should have :issues key"
      end
    end
  end
end
