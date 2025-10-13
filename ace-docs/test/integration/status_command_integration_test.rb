# frozen_string_literal: true

require "test_helper"
require "ace/docs/commands/status_command"
require "ace/docs/organisms/document_registry"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module Commands
      class StatusCommandIntegrationTest < AceTestCase
        def setup
          @temp_dir = Dir.mktmpdir("ace-docs-test")
          @original_dir = Dir.pwd
          Dir.chdir(@temp_dir)

          # Create test documents
          create_test_documents
        end

        def teardown
          Dir.chdir(@original_dir)
          FileUtils.rm_rf(@temp_dir) if @temp_dir
        end

        def test_status_command_with_no_options
          command = StatusCommand.new({})

          # Capture output
          output = capture_io do
            command.execute
          end.first

          assert output.include?("Document Status")
          assert output.include?("guide1.md")
          assert output.include?("guide")
        end

        def test_status_command_with_type_filter
          command = StatusCommand.new({ "type" => "api" })

          output = capture_io do
            command.execute
          end.first

          assert output.include?("api.md")
          refute output.include?("guide1.md")
        end

        def test_status_command_with_needs_update_filter
          command = StatusCommand.new({ "needs_update" => true })

          output = capture_io do
            command.execute
          end.first

          # Should show outdated document
          assert output.include?("outdated.md")
        end

        def test_status_command_with_freshness_filter
          command = StatusCommand.new({ "freshness" => "current" })

          output = capture_io do
            command.execute
          end.first

          assert output.include?("current.md")
          refute output.include?("outdated.md")
        end

        def test_status_command_with_no_documents
          # Remove all documents
          Dir.glob("*.md").each { |f| File.delete(f) }

          command = StatusCommand.new({})

          output = capture_io do
            command.execute
          end.first

          assert output.include?("No documents found")
        end

        private

        def create_test_documents
          # Current document
          File.write("current.md", <<~MARKDOWN)
            ---
            doc-type: guide
            purpose: Current guide document
            update:
              frequency: weekly
              last-updated: #{Date.today}
            ---

            # Current Guide

            This is current.
          MARKDOWN

          # Outdated document
          File.write("outdated.md", <<~MARKDOWN)
            ---
            doc-type: guide
            purpose: Outdated guide document
            update:
              frequency: weekly
              last-updated: #{Date.today - 30}
            ---

            # Outdated Guide

            This needs updating.
          MARKDOWN

          # API document
          File.write("api.md", <<~MARKDOWN)
            ---
            doc-type: api
            purpose: API reference
            update:
              frequency: on-change
            ---

            # API Reference

            API documentation.
          MARKDOWN

          # Another guide
          File.write("guide1.md", <<~MARKDOWN)
            ---
            doc-type: guide
            purpose: First guide
            ---

            # First Guide

            Content here.
          MARKDOWN
        end
      end
    end
  end
end