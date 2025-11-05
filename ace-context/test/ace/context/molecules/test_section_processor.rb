# frozen_string_literal: true

require 'test_helper'
require '../../../lib/ace/context/molecules/section_processor'

module Ace
  module Context
    module Molecules
      class TestSectionProcessor < Minitest::Test
        def setup
          @processor = SectionProcessor.new
        end

        def test_process_sections_with_valid_config
          config = {
            'context' => {
              'sections' => {
                'focus' => {
                  'title' => 'Files Under Review',
                  'content_type' => 'files',
                  'priority' => 1,
                  'files' => ['src/**/*.rb']
                }
              }
            }
          }

          result = @processor.process_sections(config)

          assert_kind_of Hash, result
          assert_includes result, 'focus'
          assert_equal 'Files Under Review', result['focus']['title']
          assert_equal 'files', result['focus']['content_type']
          assert_equal 1, result['focus']['priority']
        end

        def test_process_sections_with_empty_config
          result = @processor.process_sections({})
          assert_empty result

          result = @processor.process_sections({ 'context' => {} })
          assert_empty result
        end

        def test_has_sections_detection
          config_with_sections = {
            'context' => {
              'sections' => {
                'focus' => { 'title' => 'Test', 'content_type' => 'files' }
              }
            }
          }

          config_without_sections = {
            'context' => {
              'files' => ['test.rb']
            }
          }

          assert @processor.has_sections?(config_with_sections)
          refute @processor.has_sections?(config_without_sections)
        end

        def test_migrate_legacy_to_sections
          legacy_config = {
            'context' => {
              'files' => ['src/**/*.rb'],
              'commands' => ['pwd'],
              'diffs' => ['origin/main...HEAD']
            }
          }

          result = @processor.migrate_legacy_to_sections(legacy_config)

          assert_includes result['context'], 'sections'
          sections = result['context']['sections']

          assert_includes sections, 'files'
          assert_equal 'Files', sections['files']['title']
          assert_equal 'files', sections['files']['content_type']
          assert_equal 100, sections['files']['priority']
          assert_equal ['src/**/*.rb'], sections['files']['files']

          assert_includes sections, 'commands'
          assert_equal 'Commands', sections['commands']['title']
          assert_equal 'commands', sections['commands']['content_type']
          assert_equal 200, sections['commands']['priority']
          assert_equal ['pwd'], sections['commands']['commands']

          assert_includes sections, 'diffs'
          assert_equal 'Diffs', sections['diffs']['title']
          assert_equal 'diffs', sections['diffs']['content_type']
          assert_equal 300, sections['diffs']['priority']
          assert_equal ['origin/main...HEAD'], sections['diffs']['ranges']
        end

        def test_merge_sections
          sections1 = {
            'focus' => {
              'title' => 'Files',
              'content_type' => 'files',
              'priority' => 1,
              'files' => ['src/**/*.rb']
            }
          }

          sections2 = {
            'style' => {
              'title' => 'Style Guidelines',
              'content_type' => 'files',
              'priority' => 2,
              'files' => ['.rubocop.yml']
            }
          }

          result = @processor.merge_sections(sections1, sections2)

          assert_includes result, 'focus'
          assert_includes result, 'style'
          assert_equal ['src/**/*.rb'], result['focus']['files']
          assert_equal ['.rubocop.yml'], result['style']['files']
        end

        def test_merge_sections_with_same_name
          sections1 = {
            'focus' => {
              'title' => 'Files',
              'content_type' => 'files',
              'priority' => 1,
              'files' => ['src/**/*.rb']
            }
          }

          sections2 = {
            'focus' => {
              'title' => 'All Files',
              'content_type' => 'files',
              'priority' => 2,
              'files' => ['test/**/*.rb']
            }
          }

          result = @processor.merge_sections(sections1, sections2)

          assert_equal 1, result.size
          assert_includes result, 'focus'
          # Files should be merged
          assert_includes result['focus']['files'], 'src/**/*.rb'
          assert_includes result['focus']['files'], 'test/**/*.rb'
          # Title should be overridden by second section
          assert_equal 'All Files', result['focus']['title']
        end

        def test_sorted_sections
          sections = {
            'low_priority' => {
              'title' => 'Low Priority',
              'content_type' => 'files',
              'priority' => 100
            },
            'high_priority' => {
              'title' => 'High Priority',
              'content_type' => 'files',
              'priority' => 1
            },
            'medium_priority' => {
              'title' => 'Medium Priority',
              'content_type' => 'files',
              'priority' => 50
            }
          }

          result = @processor.sorted_sections(sections)

          assert_equal 3, result.size
          assert_equal 'high_priority', result[0][0]
          assert_equal 'medium_priority', result[1][0]
          assert_equal 'low_priority', result[2][0]
        end

        def test_filter_sections_by_type
          sections = {
            'focus' => {
              'title' => 'Files',
              'content_type' => 'files',
              'files' => ['src/**/*.rb']
            },
            'commands' => {
              'title' => 'Commands',
              'content_type' => 'commands',
              'commands' => ['pwd']
            }
          }

          result = @processor.filter_sections_by_type(sections, 'files')

          assert_equal 1, result.size
          assert_includes result, 'focus'
          refute_includes result, 'commands'
        end

        def test_get_section_names_by_type
          sections = {
            'focus' => {
              'title' => 'Files',
              'content_type' => 'files',
              'files' => ['src/**/*.rb']
            },
            'style' => {
              'title' => 'Style',
              'content_type' => 'files',
              'files' => ['.rubocop.yml']
            }
          }

          result = @processor.get_section_names_by_type(sections, 'files')

          assert_equal 2, result.size
          assert_includes result, 'focus'
          assert_includes result, 'style'
        end
      end
    end
  end
end