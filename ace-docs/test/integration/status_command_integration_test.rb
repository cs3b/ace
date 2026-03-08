# frozen_string_literal: true

require_relative "../test_helper"
require "ace/docs/cli/commands/status"
require "ace/docs/organisms/document_registry"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module CLI
      module Commands
        class StatusIntegrationTest < AceTestCase
          def setup
            @temp_dir = Dir.mktmpdir("ace-docs-test")
            @original_dir = Dir.pwd
            Dir.chdir(@temp_dir)

            # Create config to prevent registry from walking up and to discover test documents
            FileUtils.mkdir_p(".ace/docs")
            File.write(".ace/docs/config.yml", <<~YAML)
              document_types:
                guide:
                  paths:
                    - "*.md"
                api:
                  paths:
                    - "*.md"
            YAML

            # Create test documents
            create_test_documents
          end

          def teardown
            Dir.chdir(@original_dir)
            FileUtils.rm_rf(@temp_dir) if @temp_dir
          end

          def test_status_command_with_no_options
            command = Status.new

            # Capture output
            output = capture_io do
              command.call(project_root: @temp_dir)
            end.first

            assert output.include?("Managed Documents")
            assert output.include?("guide1.md")
            assert output.include?("guide")
          end

          def test_status_command_with_type_filter
            command = Status.new

            output = capture_io do
              command.call(type: "api", project_root: @temp_dir)
            end.first

            assert output.include?("api.md")
            refute output.include?("guide1.md")
          end

          def test_status_command_with_needs_update_filter
            command = Status.new

            output = capture_io do
              command.call(needs_update: true, project_root: @temp_dir)
            end.first

            # Should show outdated document
            assert output.include?("outdated.md")
          end

          def test_status_command_with_freshness_filter
            command = Status.new

            output = capture_io do
              command.call(freshness: "current", project_root: @temp_dir)
            end.first

            assert output.include?("current.md")
            refute output.include?("outdated.md")
          end

          def test_status_command_with_no_documents
            # Remove all documents
            Dir.glob("*.md").each { |f| File.delete(f) }

            command = Status.new

            # With exception-based pattern, command completes successfully without raising
            output = capture_io do
              command.call(project_root: @temp_dir)
            end

            # Check stderr for "No managed documents found"
            combined = output.join
            assert combined.include?("No managed documents found")
          end

          def test_status_command_with_package_scope
            FileUtils.mkdir_p("ace-assign/docs")
            File.write("ace-assign/docs/usage.md", <<~MARKDOWN)
              ---
              doc-type: guide
              purpose: Package usage docs
              ---

              # Usage
            MARKDOWN

            command = Status.new
            output = capture_io do
              command.call(package: ["ace-assign"], project_root: @temp_dir)
            end.first

            assert output.include?("usage.md")
            refute output.include?("current.md")
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
end
