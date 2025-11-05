# frozen_string_literal: true

require 'test_helper'
require '../../../lib/ace/context/models/context_data'

module Ace
  module Context
    module Models
      class TestContextData < Minitest::Test
        def setup
          @context = ContextData.new
        end

        def test_initialization_with_sections
          sections = {
            'focus' => { 'title' => 'Files', 'content_type' => 'files' },
            'style' => { 'title' => 'Style', 'content_type' => 'files' }
          }

          context = ContextData.new(sections: sections)

          assert_equal sections, context.sections
          assert_equal 2, context.section_count
        end

        def test_add_section
          section_data = {
            'title' => 'Files Under Review',
            'content_type' => 'files',
            'files' => ['src/**/*.rb']
          }

          @context.add_section('focus', section_data)

          assert @context.has_sections?
          assert_equal 1, @context.section_count
          assert_equal section_data, @context.get_section('focus')
        end

        def test_get_section
          section_data = { 'title' => 'Test Section' }
          @context.add_section('test', section_data)

          assert_equal section_data, @context.get_section('test')
          assert_nil @context.get_section('nonexistent')
        end

        def test_has_sections
          refute @context.has_sections?

          @context.add_section('test', { 'title' => 'Test' })
          assert @context.has_sections?
        end

        def test_section_count
          assert_equal 0, @context.section_count

          @context.add_section('test1', { 'title' => 'Test1' })
          assert_equal 1, @context.section_count

          @context.add_section('test2', { 'title' => 'Test2' })
          assert_equal 2, @context.section_count
        end

        def test_section_names
          @context.add_section('focus', { 'title' => 'Files' })
          @context.add_section('style', { 'title' => 'Style' })

          names = @context.section_names
          assert_equal 2, names.size
          assert_includes names, 'focus'
          assert_includes names, 'style'
        end

        def test_sorted_sections
          @context.add_section('low', { 'title' => 'Low', 'priority' => 100 })
          @context.add_section('high', { 'title' => 'High', 'priority' => 1 })
          @context.add_section('medium', { 'title' => 'Medium', 'priority' => 50 })

          sorted = @context.sorted_sections

          assert_equal 3, sorted.size
          assert_equal 'high', sorted[0][0]
          assert_equal 'medium', sorted[1][0]
          assert_equal 'low', sorted[2][0]
        end

        def test_clear_sections
          @context.add_section('test', { 'title' => 'Test' })
          assert @context.has_sections?

          @context.clear_sections
          refute @context.has_sections?
          assert_equal 0, @context.section_count
        end

        def test_to_h_includes_sections
          sections = {
            'focus' => { 'title' => 'Files', 'content_type' => 'files' }
          }

          @context.add_section('focus', sections['focus'])
          hash = @context.to_h

          assert_includes hash.keys, :sections
          assert_equal sections, hash[:sections]
        end

        def test_backward_compatibility_without_sections
          # Test that existing functionality still works
          @context.preset_name = 'test'
          @context.add_file('test.rb', 'content')
          @context.metadata[:key] = 'value'
          @context.commands = [{ command: 'pwd', output: '/path' }]

          hash = @context.to_h

          assert_equal 'test', hash[:preset_name]
          assert_equal 1, hash[:files].size
          assert_equal 'content', hash[:files].first[:content]
          assert_equal 'value', hash[:metadata][:key]
          assert_equal 1, hash[:commands].size
        end
      end
    end
  end
end