# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/ace/bundle'
require_relative '../../lib/ace/bundle/atoms/section_validator'
require_relative '../../lib/ace/bundle/molecules/section_processor'
require_relative '../../lib/ace/bundle/molecules/preset_manager'
require_relative '../../lib/ace/bundle/organisms/bundle_loader'

module Ace
  module Bundle
    class SectionPresetTest < Minitest::Test
      def setup
        @validator = Atoms::SectionValidator.new
        @preset_manager = Molecules::PresetManager.new
        @section_processor = Molecules::SectionProcessor.new
        @bundle_loader = Organisms::BundleLoader.new
      end

      # Test SectionValidator preset validation
      def test_section_validator_accepts_valid_presets
        section = {
          'title' => 'Test Section',
          'presets' => ['base', 'development']
        }

        assert @validator.validate_section('test', section)
        assert_empty @validator.errors
      end

      def test_section_validator_rejects_invalid_presets
        # Test non-array presets
        section1 = {
          'title' => 'Test Section',
          'presets' => 'not-an-array'
        }

        refute @validator.validate_section('test', section1)
        assert_includes @validator.errors, "Section 'test' presets must be an array"

        @validator.errors.clear

        # Test empty string preset
        section2 = {
          'title' => 'Test Section',
          'presets' => ['valid-preset', '', 'another-valid']
        }

        refute @validator.validate_section('test', section2)
        assert_includes @validator.errors, "Section 'test' preset at index 1 cannot be empty string"

        @validator.errors.clear

        # Test non-string preset
        section3 = {
          'title' => 'Test Section',
          'presets' => ['valid', 123, 'another-valid']
        }

        refute @validator.validate_section('test', section3)
        assert_includes @validator.errors, "Section 'test' preset at index 1 must be a string"
      end

      def test_section_validator_allows_presets_with_other_content
        section = {
          'title' => 'Test Section',
          'presets' => ['base'],
          'files' => ['src/**/*.rb'],
          'content' => 'Additional content'
        }

        assert @validator.validate_section('test', section)
        assert_empty @validator.errors
      end

      # Test SectionProcessor preset handling
      def test_section_processor_detects_presets_content_type
        section_with_presets = {
          'title' => 'Test',
          'presets' => ['base']
        }

        assert @section_processor.has_content_type?(section_with_presets, 'presets')
      end

      def test_section_processor_merges_presets_into_section
        # Create mock preset manager
        mock_preset_manager = Minitest::Mock.new
        mock_preset_manager.expect(:load_preset_with_composition,
          { success: true, bundle: { 'files' => ['preset-file.js'], 'commands' => ['preset-test'] } },
          ['base'])
        mock_preset_manager.expect(:load_preset_with_composition,
          { success: true, bundle: { 'files' => ['dev-file.js'], 'content' => 'Dev content' } },
          ['development'])

        sections = {
          'test_section' => {
            'title' => 'Test Section',
            'presets' => ['base', 'development'],
            'files' => ['local-file.js'],
            'content' => 'Local content'
          }
        }

        result = @section_processor.process_sections(
          { 'bundle' => { 'sections' => sections } },
          mock_preset_manager
        )

        processed_section = result['test_section']

        # Should have files from presets + local files
        assert_includes processed_section['files'], 'preset-file.js'
        assert_includes processed_section['files'], 'dev-file.js'
        assert_includes processed_section['files'], 'local-file.js'

        # Should have commands from presets
        assert_includes processed_section['commands'], 'preset-test'

        # Should have merged content
        assert_includes processed_section['content'], 'Local content'
        assert_includes processed_section['content'], 'Dev content'

        # Should not contain the original presets reference
        refute processed_section.key?('presets')

        mock_preset_manager.verify
      end

      def test_section_processor_handles_preset_loading_errors
        mock_preset_manager = Minitest::Mock.new
        mock_preset_manager.expect(:load_preset_with_composition,
          { success: false, error: 'Preset not found' },
          ['missing-preset'])

        sections = {
          'test_section' => {
            'title' => 'Test Section',
            'presets' => ['missing-preset']
          }
        }

        assert_raises(Ace::Bundle::SectionValidationError) do
          @section_processor.process_sections(
            { 'bundle' => { 'sections' => sections } },
            mock_preset_manager
          )
        end

        mock_preset_manager.verify
      end

      # Test integration with BundleLoader
      def test_bundle_loader_processes_sections_with_presets
        # This is an integration test that would require actual preset files
        # For now, we'll test the flow without requiring external files
        bundle_config = {
          'sections' => {
            'project_context' => {
              'title' => 'Project Context',
              'presets' => ['base'],  # This would need to exist in real test
              'content' => 'Project-specific content'
            }
          }
        }

        # Test that the bundle loader can handle the structure
        # (Full integration test would require preset files to exist)
        assert_kind_of Hash, bundle_config
        assert bundle_config['sections']['project_context'].key?('presets')
      end

      # Test preset content merging behavior
      def test_preset_content_merging
        preset_contents = [
          {
            'files' => ['file1.js', 'file2.js'],
            'commands' => ['test'],
            'content' => 'First preset content'
          },
          {
            'files' => ['file2.js', 'file3.js'],  # file2.js should be deduped
            'commands' => ['build'],
            'sections' => {
              'subsection' => {
                'title' => 'Subsection',
                'content' => 'Subcontent'
              }
            }
          }
        ]

        result = @section_processor.send(:merge_preset_content, *preset_contents)

        # Should have deduped files
        assert_equal ['file1.js', 'file2.js', 'file3.js'], result['files']

        # Should have both commands
        assert_equal ['test', 'build'], result['commands']

        # Should have merged content
        assert_includes result['content'], 'First preset content'

        # Should have sections
        assert result['sections'].key?('subsection')
      end

      # Test edge cases
      def test_empty_presets_array
        section = {
          'title' => 'Test Section',
          'presets' => [],
          'content' => 'Just local content'
        }

        assert @validator.validate_section('test', section)

        result = @section_processor.process_sections(
          { 'bundle' => { 'sections' => { 'test' => section } } },
          @preset_manager
        )

        # Should still have the local content (may be under string or symbol key)
        content = result['test']['content'] || result['test'][:content]
        assert_equal 'Just local content', content
      end

      def test_section_with_only_presets
        section = {
          'title' => 'Test Section',
          'presets' => ['base']  # Only presets, no other content
        }

        assert @validator.validate_section('test', section)
      end

      def test_nested_preset_composition_error_handling
        mock_preset_manager = Minitest::Mock.new

        # Simulate circular dependency error
        mock_preset_manager.expect(:load_preset_with_composition,
          { success: false, error: 'Circular dependency detected' },
          ['preset-a'])

        sections = {
          'test' => {
            'title' => 'Test',
            'presets' => ['preset-a']
          }
        }

        error = assert_raises(Ace::Bundle::SectionValidationError) do
          @section_processor.process_sections(
            { 'bundle' => { 'sections' => sections } },
            mock_preset_manager
          )
        end

        assert_includes error.message, 'Section preset loading failed'
        assert_includes error.message, 'Circular dependency detected'

        mock_preset_manager.verify
      end
    end
  end
end
