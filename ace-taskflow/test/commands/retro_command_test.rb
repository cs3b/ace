# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/commands/retro_command"
require "fileutils"
require "tmpdir"

module Ace
  module Taskflow
    module Commands
      class RetroCommandTest < Minitest::Test
        def setup
          @original_pwd = Dir.pwd
          @test_dir = Dir.mktmpdir("retro_command_test")
          Dir.chdir(@test_dir)

          # Create basic structure
          FileUtils.mkdir_p(".ace-taskflow/v.0.9.0/retro")

          # Mock ConfigLoader
          test_dir = @test_dir
          Molecules::ConfigLoader.singleton_class.class_eval do
            alias_method :original_find_root, :find_root
            define_method(:find_root) { File.join(test_dir, ".ace-taskflow") }
          end

          @command = RetroCommand.new
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

        def test_create_retro
          # Capture stdout
          output = capture_io do
            @command.execute(["create", "test-retro"])
          end.join("\n")

          assert_match(/Reflection note created/, output)
          assert_match(/test-retro/, output)

          # Verify file was created
          retro_files = Dir.glob(".ace-taskflow/v.0.9.0/retro/*.md")
          assert_equal 1, retro_files.length
          assert_match(/test-retro/, retro_files.first)

          # Verify content has template
          content = File.read(retro_files.first)
          assert_match(/# Reflection:/, content)
          assert_match(/## What Went Well/, content)
          assert_match(/## Key Learnings/, content)
        end

        def test_create_retro_requires_title
          output, _error = capture_io do
            exit_code = @command.execute(["create"])
            assert_equal 1, exit_code
          end

          assert_match(/Usage: ace-taskflow retro create/, output)
        end

        def test_show_help
          output = capture_io do
            @command.execute(["--help"])
          end.join("\n")

          assert_match(/Usage: ace-taskflow retro/, output)
          assert_match(/create/, output)
          assert_match(/show/, output)
          assert_match(/done/, output)
        end
      end
    end
  end
end
