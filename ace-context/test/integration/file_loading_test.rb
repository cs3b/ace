# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

module Ace
  module Context
    class FileLoadingTest < AceTestCase
      def setup
        @original_dir = Dir.pwd
      end

      def teardown
        Dir.chdir(@original_dir)
      end

      def test_load_yaml_file_as_preset
        yaml_content = <<~YAML
          description: Test YAML config
          context:
            files:
              - README.md
            commands:
              - echo "test"
            params:
              output: stdio
              format: yaml
        YAML

        Tempfile.create(['test-config', '.yml']) do |file|
          file.write(yaml_content)
          file.rewind

          context = Ace::Context.load_file_as_preset(file.path)

          assert_equal true, context.metadata[:loaded_from_file]
          assert_equal file.path, context.metadata[:file_path]
          refute_nil context.metadata[:source_type]
        end
      end

      def test_load_markdown_with_frontmatter_as_preset
        markdown_content = <<~MD
          ---
          description: Test markdown config
          context:
            files:
              - docs/test.md
            params:
              output: cache
          ---

          # Test Document

          This is test content.
        MD

        Tempfile.create(['test-config', '.md']) do |file|
          file.write(markdown_content)
          file.rewind

          context = Ace::Context.load_file_as_preset(file.path)

          assert_equal true, context.metadata[:loaded_from_file]
          assert_equal file.path, context.metadata[:file_path]
          assert_equal 'cache', context.metadata[:output]
        end
      end

      def test_load_multiple_inputs_with_files_and_presets
        yaml_content = <<~YAML
          context:
            files:
              - file1.txt
            commands:
              - echo "from file"
        YAML

        Tempfile.create(['test-config', '.yml']) do |file|
          file.write(yaml_content)
          file.rewind

          # Note: This will work even if 'default' preset doesn't exist
          # It will just merge the file configuration
          context = Ace::Context.load_multiple_inputs([], [file.path])

          refute_nil context
          refute context.metadata[:error], "Should not have errors"
        end
      end

      def test_inspect_config_with_file
        yaml_content = <<~YAML
          description: Test config inspection
          context:
            files:
              - README.md
              - "docs/**/*.md"
            params:
              format: markdown-xml
              max_size: 2097152
        YAML

        Tempfile.create(['test-config', '.yml']) do |file|
          file.write(yaml_content)
          file.rewind

          context = Ace::Context.inspect_config([file.path])

          assert_equal true, context.metadata[:inspect_mode]
          assert_includes context.content, 'README.md'
          assert_includes context.content, 'docs/**/*.md'
          assert_includes context.content, 'format: markdown-xml'
        end
      end

      def test_file_not_found_error
        context = Ace::Context.load_file_as_preset('/nonexistent/file.yml')

        assert context.metadata[:error]
        assert_includes context.metadata[:error], "File not found"
      end

      def test_invalid_yaml_error
        yaml_content = "invalid: yaml: content: [broken"

        Tempfile.create(['test-config', '.yml']) do |file|
          file.write(yaml_content)
          file.rewind

          context = Ace::Context.load_file_as_preset(file.path)

          assert context.metadata[:error]
          assert_includes context.metadata[:error], "Invalid YAML"
        end
      end

      def test_file_with_preset_composition
        # This test assumes no actual presets exist, but tests the composition logic
        markdown_content = <<~MD
          ---
          context:
            files:
              - custom.md
            presets:
              - base
              - extended
            params:
              output: stdio
          ---

          # Config with preset composition
        MD

        Tempfile.create(['test-config', '.md']) do |file|
          file.write(markdown_content)
          file.rewind

          context = Ace::Context.load_file_as_preset(file.path)

          assert_equal true, context.metadata[:loaded_from_file]
          # The preset composition will attempt to load but won't fail if presets don't exist
          refute_nil context
        end
      end
    end
  end
end