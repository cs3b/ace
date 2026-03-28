# frozen_string_literal: true

require "test_helper"
require "ace/docs/organisms/document_registry"
require "ace/docs/models/document"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module Organisms
      class DocumentRegistryTest < AceTestCase
        def setup
          @temp_dir = Dir.mktmpdir("ace-docs-test")
          @original_dir = Dir.pwd
          Dir.chdir(@temp_dir)

          # Reset config cache so each test gets fresh config resolution
          Ace::Docs.reset_config!
          Ace::Support::Config.reset_config!
        end

        def teardown
          Dir.chdir(@original_dir)
          FileUtils.rm_rf(@temp_dir) if @temp_dir

          # Clean up config cache after each test
          Ace::Docs.reset_config!
          Ace::Support::Config.reset_config!
        end

        def test_initialize_with_no_config
          registry = DocumentRegistry.new(project_root: @temp_dir)

          assert_instance_of DocumentRegistry, registry
          assert_equal [], registry.documents
          assert_includes registry.config["document_types"], "guide"
          assert_includes registry.config["global_rules"], "max_lines"
        end

        def test_initialize_with_custom_config
          config_content = <<~YAML
            document_types:
              custom:
                paths:
                  - "custom/**/*.md"
                defaults:
                  update_frequency: daily
            global_rules:
              max_lines: 500
          YAML

          FileUtils.mkdir_p(".ace/docs")
          File.write(".ace/docs/config.yml", config_content)

          registry = DocumentRegistry.new(project_root: @temp_dir)

          assert_includes registry.document_types, "custom"
          assert_equal 500, registry.global_rules["max_lines"]
        end

        def test_discover_explicit_documents
          # Create a document with ace-docs frontmatter
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test guide document
            update:
              frequency: weekly
              last-updated: 2024-10-01
            ---

            # Test Guide

            This is a test guide.
          MARKDOWN

          File.write("test-guide.md", content)

          registry = DocumentRegistry.new(project_root: @temp_dir)
          docs = registry.all

          assert_equal 1, docs.size
          assert_equal "guide", docs.first.doc_type
          assert_equal "Test guide document", docs.first.purpose
        end

        def test_discover_configured_documents
          # Create config for auto-discovery
          config_content = <<~YAML
            document_types:
              workflow:
                paths:
                  - "**/*.wf.md"
                defaults:
                  update_frequency: on-change
          YAML

          FileUtils.mkdir_p(".ace/docs")
          File.write(".ace/docs/config.yml", config_content)

          # Create a workflow file without frontmatter
          File.write("test.wf.md", "# Workflow Document\n\nContent here.")

          registry = DocumentRegistry.new(project_root: @temp_dir)
          docs = registry.all

          assert_equal 1, docs.size
          assert_equal "workflow", docs.first.doc_type
        end

        def test_ignores_specified_paths
          # Create documents in ignored directories
          FileUtils.mkdir_p("node_modules")
          FileUtils.mkdir_p(".git")
          FileUtils.mkdir_p("vendor")

          doc_content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Should be ignored
            ---

            Content
          MARKDOWN

          File.write("node_modules/ignored.md", doc_content)
          File.write(".git/ignored.md", doc_content)
          File.write("vendor/ignored.md", doc_content)

          # Create a valid document
          File.write("valid.md", doc_content.sub("Should be ignored", "Valid document"))

          registry = DocumentRegistry.new(project_root: @temp_dir)
          docs = registry.all

          assert_equal 1, docs.size
          assert_equal "Valid document", docs.first.purpose
        end

        def test_refresh
          # Create initial document
          content1 = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Initial document
            ---

            Content
          MARKDOWN

          File.write("doc1.md", content1)

          registry = DocumentRegistry.new(project_root: @temp_dir)
          assert_equal 1, registry.all.size

          # Add another document
          content2 = <<~MARKDOWN
            ---
            doc-type: api
            purpose: New document
            ---

            Content
          MARKDOWN

          File.write("doc2.md", content2)

          # Refresh the registry
          registry.refresh
          docs = registry.all

          assert_equal 2, docs.size
          purposes = docs.map(&:purpose)
          assert_includes purposes, "Initial document"
          assert_includes purposes, "New document"
        end

        def test_by_type
          create_test_documents

          registry = DocumentRegistry.new(project_root: @temp_dir)
          guide_docs = registry.by_type("guide")
          api_docs = registry.by_type("api")

          assert_equal 2, guide_docs.size
          assert_equal 1, api_docs.size
        end

        def test_needing_update
          # Create documents with different update dates
          outdated_content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Outdated document
            ace-docs:
              last-updated: 2024-01-01
            update:
              frequency: weekly
            ---

            Content
          MARKDOWN

          current_content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Current document
            ace-docs:
              last-updated: #{Date.today}
            update:
              frequency: weekly
            ---

            Content
          MARKDOWN

          File.write("outdated.md", outdated_content)
          File.write("current.md", current_content)

          registry = DocumentRegistry.new(project_root: @temp_dir)
          needing_update = registry.needing_update

          assert_equal 1, needing_update.size
          assert_equal "Outdated document", needing_update.first.purpose
        end

        def test_by_freshness
          create_freshness_test_documents

          registry = DocumentRegistry.new(project_root: @temp_dir)

          current_docs = registry.by_freshness(:current)
          registry.by_freshness(:stale)
          outdated_docs = registry.by_freshness(:outdated)

          assert current_docs.any? { |d| d.purpose == "Current document" }
          assert outdated_docs.any? { |d| d.purpose == "Outdated document" }
        end

        def test_find_by_path
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test document
            ---

            Content
          MARKDOWN

          File.write("test.md", content)

          registry = DocumentRegistry.new(project_root: @temp_dir)

          # Test with relative path
          doc = registry.find_by_path("test.md")
          assert_equal "Test document", doc.purpose

          # Test with absolute path
          doc = registry.find_by_path(File.join(@temp_dir, "test.md"))
          assert_equal "Test document", doc.purpose

          # Test with non-existent path
          doc = registry.find_by_path("non-existent.md")
          assert_nil doc
        end

        def test_grouped_by_type
          create_test_documents

          registry = DocumentRegistry.new(project_root: @temp_dir)
          grouped = registry.grouped_by_type

          assert_includes grouped, "guide"
          assert_includes grouped, "api"
          assert_equal 2, grouped["guide"].size
          assert_equal 1, grouped["api"].size
        end

        def test_grouped_by_directory
          # Create documents in different directories
          FileUtils.mkdir_p("docs")
          FileUtils.mkdir_p("api")

          guide_content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Guide in docs
            ---

            Content
          MARKDOWN

          api_content = <<~MARKDOWN
            ---
            doc-type: api
            purpose: API doc
            ---

            Content
          MARKDOWN

          File.write("docs/guide.md", guide_content)
          File.write("api/reference.md", api_content)

          registry = DocumentRegistry.new(project_root: @temp_dir)
          grouped = registry.grouped_by_directory

          assert_equal 2, grouped.size
          assert grouped.keys.any? { |k| k.include?("docs") }
          assert grouped.keys.any? { |k| k.include?("api") }
        end

        def test_stats
          create_test_documents
          create_freshness_test_documents

          registry = DocumentRegistry.new(project_root: @temp_dir)
          stats = registry.stats

          assert stats[:total] > 0
          assert_includes stats[:by_type], "guide"
          assert_includes stats[:by_type], "api"
          assert stats[:needing_update] >= 0
          assert stats[:managed] > 0
        end

        def test_handles_invalid_yaml_in_config
          config_content = "invalid: yaml: content: [["
          FileUtils.mkdir_p(".ace/docs")
          File.write(".ace/docs/config.yml", config_content)

          # Should not raise an error, but use default config
          registry = DocumentRegistry.new(project_root: @temp_dir)

          assert_instance_of DocumentRegistry, registry
          assert_includes registry.config["document_types"], "guide" # Default config
        end

        def test_avoids_duplicate_documents
          # Create a document that matches both explicit and configured discovery
          config_content = <<~YAML
            document_types:
              guide:
                paths:
                  - "**/*.md"
          YAML

          FileUtils.mkdir_p(".ace/docs")
          File.write(".ace/docs/config.yml", config_content)

          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test document
            ---

            Content
          MARKDOWN

          File.write("test.md", content)

          registry = DocumentRegistry.new(project_root: @temp_dir)
          docs = registry.all

          # Should only have one document, not duplicated
          assert_equal 1, docs.size
        end

        def test_scope_globs_limit_discovery
          FileUtils.mkdir_p("ace-assign/docs")
          FileUtils.mkdir_p("ace-git/docs")

          File.write("ace-assign/docs/usage.md", <<~MARKDOWN)
            ---
            doc-type: guide
            purpose: Assign docs
            ---

            Content
          MARKDOWN

          File.write("ace-git/docs/usage.md", <<~MARKDOWN)
            ---
            doc-type: guide
            purpose: Git docs
            ---

            Content
          MARKDOWN

          registry = DocumentRegistry.new(
            project_root: @temp_dir,
            scope_globs: ["ace-assign/**/*.md"]
          )

          docs = registry.all
          assert_equal 1, docs.size
          assert_match(%r{ace-assign/docs/usage\.md$}, docs.first.path)
        end

        def test_discovers_frontmatter_free_readme_without_yaml
          Ace::Docs.stub :config, Ace::Docs.config.merge("frontmatter_free" => ["**/README.md"]) do
            FileUtils.mkdir_p("ace-docs")
            File.write("ace-docs/README.md", "# ace-docs\n\ncontent")

            registry = DocumentRegistry.new(project_root: @temp_dir)
            doc = registry.find_by_path(File.join(@temp_dir, "ace-docs/README.md"))

            refute_nil doc
            assert_equal "readme", doc.doc_type
            assert_match(/User-facing introduction/, doc.purpose)
          end
        end

        def test_default_frontmatter_free_patterns_ignore_nested_fixture_readme
          FileUtils.mkdir_p("ace-review/test/e2e/fixture")
          File.write("ace-review/test/e2e/fixture/README.md", "# Fixture\n")

          registry = DocumentRegistry.new(project_root: @temp_dir)
          doc = registry.find_by_path(File.join(@temp_dir, "ace-review/test/e2e/fixture/README.md"))

          assert_nil doc
        end

        private

        def create_test_documents
          guide1 = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: First guide
            ---

            Content
          MARKDOWN

          guide2 = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Second guide
            ---

            Content
          MARKDOWN

          api = <<~MARKDOWN
            ---
            doc-type: api
            purpose: API reference
            ---

            Content
          MARKDOWN

          File.write("guide1.md", guide1)
          File.write("guide2.md", guide2)
          File.write("api.md", api)
        end

        def create_freshness_test_documents
          current = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Current document
            ace-docs:
              last-updated: #{Date.today}
            update:
              frequency: weekly
            ---

            Content
          MARKDOWN

          stale = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Stale document
            ace-docs:
              last-updated: #{Date.today - 10}
            update:
              frequency: weekly
            ---

            Content
          MARKDOWN

          outdated = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Outdated document
            ace-docs:
              last-updated: #{Date.today - 30}
            update:
              frequency: weekly
            ---

            Content
          MARKDOWN

          File.write("current.md", current)
          File.write("stale.md", stale)
          File.write("outdated.md", outdated)
        end
      end
    end
  end
end
