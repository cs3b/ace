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

  def test_check_task_location_uses_configured_done_dir
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create custom config with different archive directory name
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)

        custom_config = <<~YAML
          taskflow:
            directories:
              completed: "_completed"
        YAML
        File.write(File.join(config_dir, "config.yml"), custom_config)

        # Create a done task in the custom archive directory
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0")
        task_dir = File.join(release_dir, "t", "001")
        custom_archive_dir = File.join(release_dir, "_completed", "t", "001")
        FileUtils.mkdir_p(custom_archive_dir)

        task_file = File.join(custom_archive_dir, "task.001.s.md")
        File.write(task_file, <<~TASK
          ---
          id: v.0.9.0+task.001
          status: done
          ---
          # Task in custom archive directory
        TASK
        )

        # Reload configuration to pick up the custom config
        Ace::Taskflow.reset_configuration!

        # Run doctor check
        doctor = Ace::Taskflow::Organisms::TaskflowDoctor.new
        result = doctor.run_diagnosis

        # Verify no warnings about task location (it's correctly in _completed/)
        location_warnings = result[:issues].select do |issue|
          issue[:type] == :warning && issue[:message].include?("not in _completed/ directory")
        end

        assert_empty location_warnings, "Should not warn about task in custom archive directory"
      end
    end
  end

  def test_check_task_location_reports_misplaced_done_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        # The test factory creates task.001 with "done" status in active directory
        # This should trigger a warning that it's not in _archive/ directory

        # Reload configuration to ensure clean state
        Ace::Taskflow.reset_configuration!

        # Run doctor check
        doctor = Ace::Taskflow::Organisms::TaskflowDoctor.new
        result = doctor.run_diagnosis

        # Verify warning about task location (done task not in archive)
        location_warnings = result[:issues].select do |issue|
          issue[:type] == :warning && issue[:message].include?("not in _archive/ directory") && issue[:message].include?("done")
        end

        assert location_warnings.any?, "Should warn about done task not in _archive/ directory"
      end
    end
  end

end
