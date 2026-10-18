# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class ConfigLoaderTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-cfg")
          @loader = ConfigLoader.new(project_root: @dir)
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_missing_config_raises_not_ready_with_specific_path
          error = assert_raises(Error) { @loader.load }
          assert_equal "not ready: .ace-local/coworker/config.yml not found", error.message
        end

        def test_ready_predicates
          refute @loader.ready?
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          assert @loader.ready?
        end

        def test_loads_valid_config
          path = CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          cfg = @loader.load
          assert_equal "worker", cfg.role
          assert_equal "abc123", cfg.assignment
          assert_equal "8xg.t.sbz.2", cfg.task
          assert_equal "hitl", cfg.reporting_channel
          assert_equal "report", cfg.on_failure
          assert_equal path, cfg.source_path
        end

        def test_invalid_config_lists_field_specific_errors
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt: "Drive it."
            assignment: abc123
          YAML

          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "missing required field 'task'"
          assert_includes error.message, "missing required field 'overseer'"
        end

        def test_non_mapping_config_errors
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "- just\n- a list\n")
          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "expected a mapping"
        end

        def test_explicit_path_and_config_path_default
          custom = File.join(@dir, "custom.yml")
          CoworkerFixture.build_config(@dir, assignment: "zzz", task: "t1")
          FileUtils.mv(File.join(@dir, ".ace-local", "coworker", "config.yml"), custom)
          refute @loader.ready?
          assert @loader.ready?(path: custom)
          assert_equal "zzz", @loader.load(path: custom).assignment
        end

        def test_start_prompt_file_content_is_loaded_as_prompt
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          prompt_file = File.join(@dir, "prompts", "start.md")
          FileUtils.mkdir_p(File.dirname(prompt_file))
          File.write(prompt_file, "Drive assignment abc123 as worker.\n")
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt_file: prompts/start.md
            task: 8xg.t.sbz.2
            assignment: abc123
            overseer: overseer@lab
          YAML

          cfg = @loader.load
          assert_equal "Drive assignment abc123 as worker.", cfg.start_prompt
          assert_equal "prompts/start.md", cfg.start_prompt_file
        end

        def test_missing_start_prompt_file_errors_specifically
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt_file: prompts/missing.md
            task: 8xg.t.sbz.2
            assignment: abc123
            overseer: overseer@lab
          YAML

          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "start_prompt_file 'prompts/missing.md' not found"
        end

        def test_empty_start_prompt_file_errors_specifically
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xg.t.sbz.2")
          prompt_file = File.join(@dir, "prompts", "empty.md")
          FileUtils.mkdir_p(File.dirname(prompt_file))
          File.write(prompt_file, "   \n")
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt_file: prompts/empty.md
            task: 8xg.t.sbz.2
            assignment: abc123
            overseer: overseer@lab
          YAML

          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "start_prompt_file 'prompts/empty.md' is empty"
        end

        def test_malformed_yaml_errors_as_invalid_config
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "role: [unclosed\n")
          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "invalid config"
        end

        def test_scalar_nested_sections_error_as_invalid_config
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt: "Drive it."
            task: t1
            assignment: a1
            overseer: overseer@lab
            errors: stop
          YAML
          error = assert_raises(Error) { @loader.load }
          assert_includes error.message, "'errors' must be a mapping"
        end
      end
    end
  end
end
