# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/commands/retros_command"
require "fileutils"
require "tmpdir"

module Ace
  module Taskflow
    module Commands
      class RetrosCommandTest < Minitest::Test
        def setup
          @original_pwd = Dir.pwd
          @test_dir = Dir.mktmpdir("retros_command_test")
          Dir.chdir(@test_dir)

          # Create basic structure
          FileUtils.mkdir_p(".ace-taskflow/v.0.9.0/retro")
          FileUtils.mkdir_p(".ace-taskflow/v.0.9.0/retro/done")

          # Create test retros
          File.write(
            ".ace-taskflow/v.0.9.0/retro/2025-10-02-test-retro-1.md",
            "# Reflection: Test 1\n\nContent"
          )
          File.write(
            ".ace-taskflow/v.0.9.0/retro/2025-10-01-test-retro-2.md",
            "# Reflection: Test 2\n\nContent"
          )
          File.write(
            ".ace-taskflow/v.0.9.0/retro/done/2025-09-30-done-retro.md",
            "# Reflection: Done\n\nContent"
          )

          # Mock ConfigLoader
          test_dir = @test_dir
          Molecules::ConfigLoader.singleton_class.class_eval do
            alias_method :original_find_root, :find_root
            define_method(:find_root) { File.join(test_dir, ".ace-taskflow") }
          end

          @command = RetrosCommand.new
        end

        def teardown
          Dir.chdir(@original_pwd)
          FileUtils.rm_rf(@test_dir)

          # Restore original methods
          Molecules::ConfigLoader.singleton_class.class_eval do
            alias_method :find_root, :original_find_root
            remove_method :original_find_root
          end
        end

        def test_list_active_retros
          output = capture_io do
            @command.execute([])
          end.join("\n")

          assert_match(/Active Retrospective Notes/, output)
          assert_match(/test-retro-1/, output)
          assert_match(/test-retro-2/, output)
          refute_match(/done-retro/, output)
          assert_match(/Total: 2 retros/, output)
        end

        def test_list_all_retros
          output = capture_io do
            @command.execute(["--all"])
          end.join("\n")

          assert_match(/Retrospective Notes/, output)
          assert_match(/Active:/, output)
          assert_match(/Done:/, output)
          assert_match(/test-retro-1/, output)
          assert_match(/done-retro/, output)
          assert_match(/Total: 3 retros/, output)
        end

        def test_list_done_retros_only
          output = capture_io do
            @command.execute(["--done"])
          end.join("\n")

          assert_match(/Done Retrospective Notes/, output)
          assert_match(/done-retro/, output)
          refute_match(/test-retro-1/, output)
          assert_match(/Total: 1 retro/, output)
        end

        def test_empty_list
          # Remove all retros
          FileUtils.rm_rf(".ace-taskflow/v.0.9.0/retro")
          FileUtils.mkdir_p(".ace-taskflow/v.0.9.0/retro")

          output = capture_io do
            @command.execute([])
          end.join("\n")

          assert_match(/No active retrospective notes found/, output)
          assert_match(/create your first reflection note/, output)
        end

        def test_show_help
          output = capture_io do
            @command.execute(["--help"])
          end.join("\n")

          assert_match(/Usage: ace-taskflow retros/, output)
          assert_match(/--all/, output)
          assert_match(/--done/, output)
          assert_match(/--limit/, output)
        end
      end
    end
  end
end
