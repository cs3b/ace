# frozen_string_literal: true

require_relative "test_helper"

module Ace
  module Test
    class TestTest < TestCase
      def test_version_defined
        assert_kind_of String, Ace::Test::VERSION
        refute_empty Ace::Test::VERSION
      end

      def test_handbook_directories_exist
        gem_root = File.expand_path("..", __dir__)

        %w[agents guides workflow-instructions].each do |dir|
          path = File.join(gem_root, "handbook", dir)
          assert Dir.exist?(path), "Expected handbook/#{dir} directory to exist"
        end
      end

      def test_key_guides_exist
        gem_root = File.expand_path("..", __dir__)
        guides_dir = File.join(gem_root, "handbook", "guides")

        %w[testing.g.md testing-philosophy.g.md mocking-patterns.g.md].each do |guide|
          path = File.join(guides_dir, guide)
          assert File.exist?(path), "Expected guide #{guide} to exist"
        end
      end

      def test_agents_have_valid_frontmatter
        gem_root = File.expand_path("..", __dir__)
        agents_dir = File.join(gem_root, "handbook", "agents")

        Dir.glob(File.join(agents_dir, "*.ag.md")).each do |agent_file|
          content = File.read(agent_file)
          assert content.start_with?("---"), "#{File.basename(agent_file)} should start with YAML frontmatter"
          assert content.include?("name:"), "#{File.basename(agent_file)} should have name in frontmatter"
        end
      end

      def test_protocol_config_files_exist
        gem_root = File.expand_path("..", __dir__)
        protocols_dir = File.join(gem_root, ".ace-defaults", "nav", "protocols")

        # Check that each protocol type has its config file
        %w[guide-sources agent-sources tmpl-sources wfi-sources].each do |protocol_type|
          config_file = File.join(protocols_dir, protocol_type, "ace-test.yml")
          assert File.exist?(config_file), "Expected protocol config #{config_file} to exist"
        end
      end

      def test_guide_protocol_paths_resolvable
        gem_root = File.expand_path("..", __dir__)
        protocols_dir = File.join(gem_root, ".ace-defaults", "nav", "protocols")

        # Read guide protocol config
        guide_config = File.join(protocols_dir, "guide-sources", "ace-test.yml")
        assert File.exist?(guide_config), "Guide protocol config should exist"

        content = File.read(guide_config)
        # Extract relative_path from config
        relative_path = content.match(/relative_path:\s*(\S+)/)&.[](1)

        assert relative_path, "Guide protocol config should have relative_path"

        # Verify the path exists
        guides_path = File.join(gem_root, relative_path)
        assert Dir.exist?(guides_path), "Guide path #{guides_path} should exist"

        # Verify at least one guide file matches the pattern
        pattern = content.match(/pattern:\s*"(\S+)"/)&.[](1) || "*.g.md"
        guide_files = Dir.glob(File.join(guides_path, pattern))

        refute_empty guide_files, "Should find at least one guide file matching #{pattern}"
      end

      def test_agent_protocol_paths_resolvable
        gem_root = File.expand_path("..", __dir__)
        protocols_dir = File.join(gem_root, ".ace-defaults", "nav", "protocols")

        # Read agent protocol config
        agent_config = File.join(protocols_dir, "agent-sources", "ace-test.yml")
        assert File.exist?(agent_config), "Agent protocol config should exist"

        content = File.read(agent_config)
        # Extract relative_path from config
        relative_path = content.match(/relative_path:\s*(\S+)/)&.[](1)

        assert relative_path, "Agent protocol config should have relative_path"

        # Verify the path exists
        agents_path = File.join(gem_root, relative_path)
        assert Dir.exist?(agents_path), "Agent path #{agents_path} should exist"

        # Verify at least one agent file matches the pattern
        pattern = content.match(/pattern:\s*"(\S+)"/)&.[](1) || "*.ag.md"
        agent_files = Dir.glob(File.join(agents_path, pattern))

        refute_empty agent_files, "Should find at least one agent file matching #{pattern}"
      end

      def test_template_protocol_paths_resolvable
        gem_root = File.expand_path("..", __dir__)
        protocols_dir = File.join(gem_root, ".ace-defaults", "nav", "protocols")

        # Read template protocol config
        template_config = File.join(protocols_dir, "tmpl-sources", "ace-test.yml")
        assert File.exist?(template_config), "Template protocol config should exist"

        content = File.read(template_config)
        # Extract relative_path from config
        relative_path = content.match(/relative_path:\s*(\S+)/)&.[](1)

        assert relative_path, "Template protocol config should have relative_path"

        # Verify the path exists
        templates_path = File.join(gem_root, relative_path)
        assert Dir.exist?(templates_path), "Template path #{templates_path} should exist"

        # Verify at least one template file matches the pattern
        pattern = content.match(/pattern:\s*"(\S+)"/)&.[](1) || "**/*.template.md"
        template_files = Dir.glob(File.join(templates_path, pattern))

        refute_empty template_files, "Should find at least one template file matching #{pattern}"
      end

      def test_wfi_protocol_paths_resolvable
        gem_root = File.expand_path("..", __dir__)
        protocols_dir = File.join(gem_root, ".ace-defaults", "nav", "protocols")

        # Read workflow protocol config
        wfi_config = File.join(protocols_dir, "wfi-sources", "ace-test.yml")
        assert File.exist?(wfi_config), "Workflow protocol config should exist"

        content = File.read(wfi_config)
        relative_path = content.match(/relative_path:\s*(\S+)/)&.[](1)
        assert relative_path, "Workflow protocol config should have relative_path"

        workflows_path = File.join(gem_root, relative_path)
        assert Dir.exist?(workflows_path), "Workflow path #{workflows_path} should exist"

        pattern = content.match(/pattern:\s*"(\S+)"/)&.[](1) || "*.wf.md"
        workflow_files = Dir.glob(File.join(workflows_path, "**", pattern))
        refute_empty workflow_files, "Should find at least one workflow file matching #{pattern}"
      end
    end
  end
end
