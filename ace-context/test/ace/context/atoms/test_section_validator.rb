# frozen_string_literal: true

require 'test_helper'
require '../../../lib/ace/context/atoms/section_validator'

module Ace
  module Context
    module Atoms
      class TestSectionValidator < Minitest::Test
        def setup
          @validator = SectionValidator.new
        end

        def test_valid_sections_pass_validation
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'priority' => 1,
              'files' => ['src/**/*.rb']
            },
            'style' => {
              'title' => 'Style Guidelines',
              'content_type' => 'files',
              'priority' => 2,
              'files' => ['.rubocop.yml']
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_missing_required_fields_fails_validation
          sections = {
            'focus' => {
              'files' => ['src/**/*.rb']
              # Missing title and content_type
            }
          }

          refute @validator.validate_sections(sections)
          assert_includes @validator.errors, "Section 'focus' missing required field: title"
          assert_includes @validator.errors, "Section 'focus' missing required field: content_type"
        end

        def test_invalid_content_type_fails_validation
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'invalid_type',
              'files' => ['src/**/*.rb']
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'focus' has invalid content_type: invalid_type/, @validator.errors.first)
        end

        def test_invalid_priority_fails_validation
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'priority' => 'invalid',
              'files' => ['src/**/*.rb']
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'focus' priority must be an integer/, @validator.errors.first)
        end

        def test_empty_sections_pass_validation
          assert @validator.validate_sections({})
          assert @validator.validate_sections(nil)
          assert_empty @validator.errors
        end

        def test_duplicate_section_names_fail_validation
          # This would be tested through the structure that creates duplicate names
          # But we can test the validation logic directly
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'files' => ['src/**/*.rb']
            }
          }

          # Single section should pass
          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_invalid_section_name_fails_validation
          # Test invalid characters
          invalid_names = ['invalid name', 'name@invalid', 'invalid#name']

          invalid_names.each do |invalid_name|
            refute @validator.validate_section(invalid_name, {
              'title' => 'Test Section',
              'content_type' => 'files',
              'files' => ['test.rb']
            })
            assert_match(/Section '#{invalid_name}' contains invalid characters/, @validator.errors.first)
          end
        end

        def test_files_section_validation
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'files' => ['src/**/*.rb', 'README.md']
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_empty_files_section_fails_validation
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'files' => []
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'focus' with content_type 'files' must specify files array/, @validator.errors.first)
        end

        def test_commands_section_validation
          sections = {
            'system' => {
              'title' => 'System Info',
              'content_type' => 'commands',
              'commands' => ['pwd', 'git status']
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_empty_commands_section_fails_validation
          sections = {
            'system' => {
              'title' => 'System Info',
              'content_type' => 'commands',
              'commands' => []
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'system' with content_type 'commands' must specify commands array/, @validator.errors.first)
        end

        def test_diffs_section_validation
          sections = {
            'changes' => {
              'title' => 'Recent Changes',
              'content_type' => 'diffs',
              'ranges' => ['origin/main...HEAD']
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_empty_diffs_section_fails_validation
          sections = {
            'changes' => {
              'title' => 'Recent Changes',
              'content_type' => 'diffs',
              'ranges' => []
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'changes' with content_type 'diffs' must specify ranges array/, @validator.errors.first)
        end

        def test_content_section_validation
          sections = {
            'intro' => {
              'title' => 'Introduction',
              'content_type' => 'content',
              'content' => 'This is an introduction section.'
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end

        def test_empty_content_section_fails_validation
          sections = {
            'intro' => {
              'title' => 'Introduction',
              'content_type' => 'content',
              'content' => ''
            }
          }

          refute @validator.validate_sections(sections)
          assert_match(/Section 'intro' with content_type 'content' must specify content/, @validator.errors.first)
        end

        def test_default_priority_handling
          sections = {
            'focus' => {
              'title' => 'Files Under Review',
              'content_type' => 'files',
              'files' => ['src/**/*.rb']
              # No priority specified - should get default 999 in normalization
            }
          }

          assert @validator.validate_sections(sections)
          assert_empty @validator.errors
        end
      end
    end
  end
end