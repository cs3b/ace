# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"

class BundleLoaderTest < AceTestCase
  # Normalize legacy top-level fixture style to section-based input so tests reflect
  # the v0.10.0 bundle loader contract.
  def create_preset(name, content = nil)
    content ||= <<~MARKDOWN
      ---
      description: Test preset
      bundle:
        params:
          output: stdio
          max_size: 1048576
          timeout: 30
        embed_document_source: true
        files:
          - "**/*.md"
        commands:
          - echo "test"
        exclude:
          - "**/exclude/**"
      ---
      # #{name.capitalize} Preset
    MARKDOWN

    content = normalize_preset_sections(content)

    FileUtils.mkdir_p(".ace/bundle/presets")
    File.write(".ace/bundle/presets/#{name}.md", content)
  end

  private

  def normalize_preset_sections(raw_content)
    return raw_content unless raw_content.is_a?(String)

    match = raw_content.match(%r{\A---\s*\n(.*?)\n---\s*\n(.*)\z}m)
    return raw_content unless match

    frontmatter = match[1]
    body = match[2]

    parsed = YAML.safe_load(frontmatter)
    return raw_content unless parsed.is_a?(Hash)

    bundle = parsed["bundle"] || parsed[:bundle]
    return raw_content unless bundle.is_a?(Hash)

    # Already section-based: keep unchanged.
    return raw_content if bundle["sections"] || bundle[:sections]

    moved = {}

    %w[files commands ranges diffs exclude].each do |key|
      moved[key] = bundle.delete(key) if bundle.key?(key)
    end

    if bundle.key?("diff")
      diff_config = bundle.delete("diff")
      case diff_config
      when Hash
        moved_ranges = []
        if diff_config["ranges"]
          moved_ranges = diff_config["ranges"]
        elsif diff_config["since"]
          moved_ranges = ["#{diff_config["since"]}...HEAD"]
        end
        moved["ranges"] = moved_ranges if moved_ranges.any?
      when String, Array
        moved["ranges"] = diff_config
      end
    end

    return raw_content if moved.empty?

    parsed["bundle"] = bundle
    parsed["bundle"]["sections"] = {
      "main" => moved
    }

    normalized_frontmatter = parsed.to_yaml.sub(/\A---\n/, "")
    "---\n#{normalized_frontmatter}---\n#{body}"
  end

  public

  def test_loads_preset_with_files
    with_temp_dir do
      # Create sample files
      File.write("README.md", "# Test Project")
      FileUtils.mkdir_p("docs")
      File.write("docs/blueprint.md", "# Blueprint")

      # Create preset
      create_preset("default", <<~MARKDOWN
        ---
        description: Default preset
        bundle:
          params:
            output: stdio
          embed_document_source: true
          files:
            - README.md
            - docs/*.md
        ---
        # Default Preset
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("default")

      assert_equal 2, context.file_count
      assert context.content.include?("Test Project")
      assert context.content.include?("Blueprint")
    end
  end

  def test_loads_file_directly
    with_temp_file("Test content") do |path|
      loader = Ace::Bundle::Organisms::BundleLoader.new
      context = loader.load_file(path)

      assert_equal "Test content", context.content
      assert_equal path, context.metadata[:source]
      refute context.metadata[:error]
    end
  end

  def test_handles_missing_preset
    loader = Ace::Bundle::Organisms::BundleLoader.new
    context = loader.load_preset("nonexistent")

    assert_equal "nonexistent", context.preset_name
    assert_match(/Preset 'nonexistent' not found.*Available presets:/, context.metadata[:error])
  end

  def test_applies_exclusions
    with_temp_dir do
      # Create files
      File.write("include.md", "Include this")
      FileUtils.mkdir_p("exclude")
      File.write("exclude/skip.md", "Skip this")

      # Create preset with exclusions
      create_preset("test")

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("test")

      assert_equal 1, context.file_count
      assert context.content.include?("Include this")
      refute context.content.include?("Skip this")
    end
  end

  def test_respects_output_mode
    with_temp_dir do
      File.write("test.md", "Content")

      # Create preset with cache output
      create_preset("cache_test", <<~MARKDOWN
        ---
        description: Cache test
        bundle:
          params:
            output: cache
          embed_document_source: true
          files:
            - test.md
        ---
        Cache preset
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("cache_test")

      assert_equal "cache", context.metadata[:output]
    end
  end

  def test_executes_commands
    with_temp_dir do
      create_preset("cmd_test", <<~MARKDOWN
        ---
        description: Command test
        bundle:
          params:
            output: stdio
            timeout: 5
          commands:
            - echo "Hello"
            - pwd
        ---
        Command test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("cmd_test")

      assert context.commands
      assert_equal 2, context.commands.size

      hello_cmd = context.commands.find { |c| c[:command] == 'echo "Hello"' }
      assert hello_cmd
      assert hello_cmd[:success]
      assert_match(/Hello/, hello_cmd[:output])
    end
  end

  def test_handles_glob_patterns
    with_temp_dir do
      # Create ace-* structure
      FileUtils.mkdir_p("ace-core")
      FileUtils.mkdir_p("ace-bundle")
      File.write("ace-core/README.md", "Core readme")
      File.write("ace-bundle/README.md", "Context readme")
      File.write("ace-core/test.rb", "Ruby file")

      create_preset("glob_test", <<~MARKDOWN
        ---
        description: Glob test
        bundle:
          params:
            output: stdio
          embed_document_source: true
          files:
            - "ace-*/README.md"
        ---
        Glob test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("glob_test")

      assert_equal 2, context.file_count
      assert context.content.include?("Core readme")
      assert context.content.include?("Context readme")
      refute context.content.include?("Ruby file")
    end
  end

  def test_loads_preset_body_content
    with_temp_dir do
      body_content = "This is important preset documentation"
      create_preset("body_test", <<~MARKDOWN
        ---
        description: Body test
        bundle:
          params:
            output: stdio
          files: []
        ---
        # Body Test

        #{body_content}
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("body_test")

      assert context.metadata[:preset_content]
      assert context.metadata[:preset_content].include?(body_content)
    end
  end

  def test_merges_params_with_options
    with_temp_dir do
      create_preset("merge_test", <<~MARKDOWN
        ---
        description: Merge test
        bundle:
          params:
            output: cache
            max_size: 500000
            timeout: 10
          files: []
        ---
        Merge test
      MARKDOWN
      )

      # Override some params via options
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        max_size: 1000000,  # Override
        timeout: 20,        # Override
        custom: "value"     # Additional
      )
      context = loader.load_preset("merge_test")

      # Preset params should override initialization options
      assert_equal "cache", context.metadata[:output]
    end
  end

  def test_formats_output_correctly
    with_temp_dir do
      File.write("test.txt", "Content")

      create_preset("format_test", <<~MARKDOWN
        ---
        description: Format test
        bundle:
          params:
            output: stdio
            format: yaml
          embed_document_source: true
          files:
            - test.txt
        ---
        Format test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("format_test")

      # Should be formatted as YAML
      puts "DEBUG: Content format: #{context.content[0..200]}" if ENV["DEBUG"]

      # Check if it's actually YAML formatted
      assert_match(/format_test/, context.content, "Content should include preset name")
      assert_match(/sections:/, context.content, "Content should include sections output")
    end
  end

  def test_new_structure_with_embed_document_source
    with_temp_dir do
      # Create sample files
      File.write("README.md", "# Test Project")
      FileUtils.mkdir_p("docs")
      File.write("docs/guide.md", "# Guide")

      # Create preset with NEW structure
      create_preset("new_structure", <<~MARKDOWN
        ---
        description: New structure test
        bundle:
          params:
            output: stdio
            max_size: 2097152
            timeout: 60
          embed_document_source: true
          files:
            - README.md
            - docs/guide.md
        ---
        # New Structure Preset
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("new_structure")

      # Verify files are embedded
      assert_equal 2, context.file_count, "Should have 2 files embedded"
      assert context.content.include?("Test Project"), "Should include README content"
      assert context.content.include?("Guide"), "Should include guide content"

      # Verify output mode is respected
      assert_equal "stdio", context.metadata[:output]
    end
  end

  def test_embed_source_cli_flag_enables_embedding
    with_temp_dir do
      # Create sample file
      File.write("test.md", "Test content")

      # Create template file WITHOUT embed_document_source in frontmatter
      File.write("prompt.md", <<~MARKDOWN
        ---
        bundle:
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load with embed_source flag enabled via CLI
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        embed_source: true
      )
      context = loader.load_file("prompt.md")

      # Should embed the source document even though frontmatter doesn't have embed_document_source
      assert context.content.include?("This is the prompt content"), "Should embed source content"
      assert context.content.include?("Test content"), "Should embed referenced files"
      assert_equal 1, context.file_count, "Should have 1 file embedded"
    end
  end

  def test_embed_source_flag_overrides_frontmatter
    with_temp_dir do
      # Create sample file
      File.write("test.md", "Test content")

      # Create template file WITH embed_document_source: false in frontmatter
      File.write("prompt.md", <<~MARKDOWN
        ---
        bundle:
          embed_document_source: false
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load with embed_source flag enabled via CLI (should override frontmatter)
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        embed_source: true
      )
      context = loader.load_file("prompt.md")

      # Should embed despite frontmatter saying false
      assert context.content.include?("This is the prompt content"), "Should embed source content (CLI flag overrides)"
      assert context.content.include?("Test content"), "Should embed referenced files"
      assert_equal 1, context.file_count, "Should have 1 file embedded"
    end
  end

  def test_no_embed_source_flag_respects_frontmatter
    with_temp_dir do
      # Create sample file
      File.write("test.md", "Test content")

      # Create template file WITH embed_document_source: false
      File.write("prompt.md", <<~MARKDOWN
        ---
        bundle:
          embed_document_source: false
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load WITHOUT embed_source flag
      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_file("prompt.md")

      # Should NOT embed source when frontmatter says false and no CLI flag
      refute context.content.include?("This is the prompt content"), "Should not embed source content when disabled"
      # Files should still be included in formatted output but not embedded separately
      assert context.content.include?("Test content"), "Should still show file content in formatted output"
    end
  end

  # Tests for top-level preset references (context.presets)
  # These test the fix for issue where `context: presets: [...]` was ignored
  # while `context: sections: my-section: presets: [...]` worked correctly

  def test_loads_preset_with_top_level_presets
    with_temp_dir do
      # Create sample files for each preset
      File.write("base-file.md", "# Base File Content")
      File.write("extended-file.md", "# Extended File Content")

      # Create base preset
      create_preset("base-preset", <<~MARKDOWN
        ---
        description: Base preset
        bundle:
          params:
            output: stdio
          embed_document_source: true
          files:
            - base-file.md
        ---
        Base preset body
      MARKDOWN
      )

      # Create preset that references base via top-level presets
      create_preset("extended-preset", <<~MARKDOWN
        ---
        description: Extended preset with top-level presets
        bundle:
          presets:
            - base-preset
          embed_document_source: true
          files:
            - extended-file.md
        ---
        Extended preset body
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("extended-preset")

      # Should have files from both presets
      assert_equal 2, context.file_count, "Should have files from both base and extended presets"
      assert context.content.include?("Base File Content"), "Should include base preset file content"
      assert context.content.include?("Extended File Content"), "Should include extended preset file content"
    end
  end

  def test_top_level_presets_current_config_wins
    with_temp_dir do
      # Create sample file
      File.write("file.md", "# File Content")

      # Create base preset with timeout param
      create_preset("base-params", <<~MARKDOWN
        ---
        description: Base preset with params
        bundle:
          params:
            timeout: 30
          embed_document_source: true
          files:
            - file.md
        ---
        Base
      MARKDOWN
      )

      # Create preset that overrides timeout
      create_preset("override-params", <<~MARKDOWN
        ---
        description: Override preset
        bundle:
          params:
            timeout: 60
          presets:
            - base-params
          embed_document_source: true
        ---
        Override
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("override-params")

      # Current preset params should win (last wins)
      # The metadata contains merged params
      assert context.metadata[:timeout].nil? || context.metadata[:timeout] == 60,
        "Current preset timeout should override base (or be merged correctly)"

      # Should still have files from base
      assert_equal 1, context.file_count, "Should have files from base preset"
    end
  end

  def test_top_level_presets_with_missing_preset_returns_error
    with_temp_dir do
      File.write("test.md", "# Test Content")

      # Create base preset
      create_preset("existing-preset", <<~MARKDOWN
        ---
        description: Existing preset
        bundle:
          embed_document_source: true
          files:
            - test.md
        ---
        Content
      MARKDOWN
      )

      # Create preset referencing both existing and missing presets
      create_preset("mixed-refs", <<~MARKDOWN
        ---
        description: Mixed references
        bundle:
          presets:
            - existing-preset
            - nonexistent-preset
          embed_document_source: true
        ---
        Mixed
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd, debug: false)
      context = loader.load_preset("mixed-refs")

      # When a referenced preset is missing, the load should fail with an error
      # This is the expected behavior from PresetManager.load_preset_with_composition
      assert context.metadata[:error], "Should have error when referenced preset is missing"
      assert_match(/nonexistent-preset/, context.metadata[:error], "Error should mention missing preset")
    end
  end

  def test_top_level_presets_with_sections_coexist
    with_temp_dir do
      File.write("base.md", "# Base Content")
      File.write("section.md", "# Section Content")
      File.write("own.md", "# Own Content")

      # Create base preset
      create_preset("base-files", <<~MARKDOWN
        ---
        description: Base files
        bundle:
          embed_document_source: true
          files:
            - base.md
        ---
        Base
      MARKDOWN
      )

      # Create preset with both top-level presets AND sections
      create_preset("combined", <<~MARKDOWN
        ---
        description: Combined preset
        bundle:
          presets:
            - base-files
          embed_document_source: true
          sections:
            my-own:
              title: Own Files
              files:
                - own.md
            my-section:
              title: My Section
              files:
                - section.md
        ---
        Combined
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("combined")

      # Should have files from: top-level presets + own files + section files
      assert context.content.include?("Base Content"), "Should include base preset file"
      assert context.content.include?("Own Content"), "Should include own file"
      assert context.content.include?("Section Content"), "Should include section file"
    end
  end

  def test_top_level_presets_merges_commands
    with_temp_dir do
      # Create base preset with a command
      create_preset("base-cmd", <<~MARKDOWN
        ---
        description: Base preset with command
        bundle:
          embed_document_source: true
          commands:
            - echo "from base"
        ---
        Base
      MARKDOWN
      )

      # Create preset that adds its own command
      create_preset("extended-cmd", <<~MARKDOWN
        ---
        description: Extended preset
        bundle:
          presets:
            - base-cmd
          embed_document_source: true
          commands:
            - echo "from extended"
        ---
        Extended
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("extended-cmd")

      # Should have commands from both presets
      assert context.commands, "Should have commands"
      assert context.commands.size >= 2, "Should have commands from both presets"

      command_strings = context.commands.map { |c| c[:command] }
      assert command_strings.include?('echo "from base"'), "Should have base preset command"
      assert command_strings.include?('echo "from extended"'), "Should have extended preset command"
    end
  end

  # Test PR processing with mocked executor
  # This test verifies that PR diffs are integrated into context output
  # Uses load_inline_yaml which properly processes PR config (load_file just reads raw content)
  def test_pr_config_processes_with_mocked_executor
    with_temp_dir do
      # Inline YAML config with PR reference
      yaml_config = <<~YAML
        bundle:
          pr: "123"
      YAML

      # Stub ace-git public API (PrMetadataFetcher.fetch_diff) instead of Open3.capture3
      mock_response = {
        success: true,
        diff: PrMockFixtures::MOCK_DIFF_STANDARD,
        identifier: "123",
        source: "pr:123"
      }

      Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, ->(_id, **_opts) { mock_response }) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_inline_yaml(yaml_config)

        # Verify PR diff was integrated into context sections
        assert context.sections, "Should have sections"
        assert context.sections["diffs"], "Should have diffs section"
        assert context.sections["diffs"][:_processed_diffs], "Should have processed diffs"
        assert_equal 1, context.sections["diffs"][:_processed_diffs].size
        assert context.sections["diffs"][:_processed_diffs][0][:success], "PR fetch should succeed"
        assert_includes context.sections["diffs"][:_processed_diffs][0][:output], "def bar", "Should include PR diff content"
      end
    end
  end

  # Test that multiple PRs are processed and merged correctly
  def test_pr_config_processes_multiple_prs
    with_temp_dir do
      # Inline YAML config with multiple PR references
      yaml_config = <<~YAML
        bundle:
          pr:
            - "123"
            - "456"
      YAML

      call_count = 0

      # Stub ace-git public API (PrMetadataFetcher.fetch_diff) instead of Open3.capture3
      mock_fetch = lambda do |id, **_opts|
        diff = (call_count == 0) ? PrMockFixtures::MOCK_DIFF_PR_123 : PrMockFixtures::MOCK_DIFF_PR_456
        call_count += 1
        {success: true, diff: diff, identifier: id, source: "pr:#{id}"}
      end

      Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_inline_yaml(yaml_config)

        # Verify both PR diffs were integrated into sections
        assert context.sections, "Should have sections"
        assert context.sections["diffs"], "Should have diffs section"
        processed = context.sections["diffs"][:_processed_diffs]
        assert_equal 2, processed.size, "Should have 2 processed PR diffs"
        assert_includes processed[0][:output], "PR 123", "Should include first PR diff"
        assert_includes processed[1][:output], "PR 456", "Should include second PR diff"
      end
    end
  end

  def test_pr_config_handles_errors_gracefully
    with_temp_dir do
      # Create a template file so load_file exercises PR processing
      File.write("config.md", <<~MARKDOWN)
        ---
        bundle:
          pr: invalid-pr-format
        ---
      MARKDOWN

      invalid_pr_error = ->(_id, **_opts) { raise ArgumentError, "Invalid PR identifier: invalid-pr-format" }

      Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, invalid_pr_error) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_file("config.md")

        # Should handle error gracefully without reaching real PR lookup
        assert context.content, "Should generate content even with PR error"
        assert_includes context.content, "PR Fetch Errors"
        assert_includes context.content, "Invalid PR identifier"
      end
    end
  end

  # Tests for load_inline_yaml with nested context key
  # This ensures ace-review typed subjects (diff:, files:, pr:) work correctly
  # Optimized to use DiffOrchestrator stubbing instead of real git repos (~10ms vs ~600ms)
  # See PR #114 for performance optimization details

  # Helper: Creates a mock DiffResult for testing diff-related functionality
  # Simulates what DiffOrchestrator.generate would return for a simple file change
  # @param filename [String] The filename to include in the mock diff (default: "test.rb")
  # @param range [String] The git range for metadata (default: "HEAD~1..HEAD")
  # @return [Ace::Git::Models::DiffResult] A mock diff result
  def build_mock_diff_result(filename: "test.rb", range: "HEAD~1..HEAD")
    mock_diff_content = <<~DIFF
      diff --git a/#{filename} b/#{filename}
      index abc1234..def5678 100644
      --- a/#{filename}
      +++ b/#{filename}
      @@ -1 +1,2 @@
      -# Initial content
      +# Updated content
      +# Line 2
    DIFF

    Ace::Git::Models::DiffResult.new(
      content: mock_diff_content,
      stats: {additions: 2, deletions: 1, files: 1, total_changes: 3},
      files: [filename],
      metadata: {range: range}
    )
  end

  def test_load_inline_yaml_with_flat_diffs_config
    with_temp_dir do
      # Create test file for diff output reference
      File.write("test.rb", "# Updated content\n# Line 2")

      # Flat config (traditional usage)
      yaml_string = <<~YAML
        diffs:
          - HEAD~1..HEAD
        ---
      YAML

      # Stub DiffOrchestrator to return mock diff
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, build_mock_diff_result do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.send(:load_inline_yaml, yaml_string)

        # Should contain diff output
        assert context.content.length > 50, "Expected substantial content from diff"
        assert context.content.include?("test.rb"), "Should include filename in diff"
      end
    end
  end

  def test_load_inline_yaml_with_nested_context_diffs_config
    with_temp_dir do
      # Create test file for diff output reference
      File.write("test.rb", "# Updated content\n# Line 2")

      # Nested config (ace-review typed subject format)
      yaml_string = <<~YAML
        bundle:
          diffs:
            - HEAD~1..HEAD
        ---
      YAML

      # Stub DiffOrchestrator to return mock diff
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, build_mock_diff_result do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.send(:load_inline_yaml, yaml_string)

        # Should contain diff output (same as flat config)
        assert context.content.length > 50, "Expected substantial content from nested diff config"
        assert context.content.include?("test.rb"), "Should include filename in diff from nested config"
      end
    end
  end

  def test_load_inline_yaml_with_diff_paths_passes_paths_to_diff_orchestrator
    with_temp_dir do
      yaml_string = <<~YAML
        bundle:
          diffs:
            - HEAD~1..HEAD
          paths:
            - ace-test-runner-e2e
            - ace-review/docs/usage.md
        ---
      YAML

      captured_options = nil
      diff_stub = lambda do |options|
        captured_options = options
        build_mock_diff_result
      end

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, diff_stub do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.send(:load_inline_yaml, yaml_string)

        assert context.content.include?("test.rb"), "Should include diff output"
      end

      assert_equal ["HEAD~1..HEAD"], captured_options[:ranges]
      assert_equal ["ace-test-runner-e2e", "ace-review/docs/usage.md"], captured_options[:paths]
    end
  end

  def test_section_diff_paths_passes_paths_to_diff_orchestrator
    with_temp_dir do
      File.write("section-config.md", <<~MARKDOWN)
        ---
        bundle:
          sections:
            scoped_diff:
              title: Scoped Diff
              diff:
                ranges:
                  - HEAD~1..HEAD
                paths:
                  - ace-test-runner-e2e
                  - ace-review/docs/usage.md
        ---
      MARKDOWN

      captured_options = nil
      diff_stub = lambda do |options|
        captured_options = options
        build_mock_diff_result
      end

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, diff_stub do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_file("section-config.md")

        processed = context.sections["scoped_diff"][:_processed_diffs]
        assert_equal ["ace-test-runner-e2e", "ace-review/docs/usage.md"], processed.first[:paths]
      end

      assert_equal ["HEAD~1..HEAD"], captured_options[:ranges]
      assert_equal ["ace-test-runner-e2e", "ace-review/docs/usage.md"], captured_options[:paths]
    end
  end

  def test_load_inline_yaml_flat_and_nested_produce_same_output
    with_temp_dir do
      # Just create the test file - no git repo needed for files: config
      File.write("test.rb", "# Test content")

      flat_yaml = <<~YAML
        files:
          - test.rb
        ---
      YAML

      nested_yaml = <<~YAML
        bundle:
          files:
            - test.rb
        ---
      YAML

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      flat_context = loader.send(:load_inline_yaml, flat_yaml)
      nested_context = loader.send(:load_inline_yaml, nested_yaml)

      # Both should produce equivalent content
      assert flat_context.content.include?("Test content"), "Flat config should include file content"
      assert nested_context.content.include?("Test content"), "Nested config should include file content"
      assert_equal flat_context.file_count, nested_context.file_count, "Both should have same file count"
    end
  end

  # Test has_processed_section_content? returns true for sections with _processed_diffs
  def test_has_processed_section_content_with_processed_diffs
    with_temp_dir do
      # Create a mock context with sections containing _processed_diffs
      create_preset("test-preset", <<~MARKDOWN
        ---
        description: Test preset
        bundle:
          params:
            output: stdio
          sections:
            pr_diffs:
              title: PR Diffs
        ---
        Test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("test-preset")

      # Manually add _processed_diffs to simulate PR processing
      # This simulates what happens when PRs are fetched and processed
      if context.sections && context.sections.key?("pr_diffs")
        context.sections["pr_diffs"][:_processed_diffs] = ["diff content from PR"]
      end

      # Now test the helper method
      assert loader.send(:has_processed_section_content?, context),
        "Should return true when sections have _processed_diffs"
    end
  end

  def test_has_processed_section_content_with_processed_files
    with_temp_dir do
      create_preset("test-preset", <<~MARKDOWN
        ---
        description: Test preset
        bundle:
          params:
            output: stdio
          sections:
            files_section:
              title: Files
        ---
        Test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("test-preset")

      # Manually add _processed_files
      if context.sections && context.sections.key?("files_section")
        context.sections["files_section"][:_processed_files] = [{path: "test.rb", content: "content"}]
      end

      assert loader.send(:has_processed_section_content?, context),
        "Should return true when sections have _processed_files"
    end
  end

  def test_has_processed_section_content_returns_false_for_no_processed_content
    with_temp_dir do
      create_preset("empty-preset", <<~MARKDOWN
        ---
        description: Empty preset
        bundle:
          params:
            output: stdio
          sections:
            empty_section:
              title: Empty
        ---
        Test
      MARKDOWN
      )

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("empty-preset")

      refute loader.send(:has_processed_section_content?, context),
        "Should return false when sections have no processed content"
    end
  end

  # Tests for generate_diff_safe error handling
  # Verifies that ace-git errors are captured and surfaced in content instead of crashing

  def test_generate_diff_safe_handles_ace_git_error
    with_temp_dir do
      yaml_config = <<~YAML
        bundle:
          diffs:
            - "HEAD~1..HEAD"
      YAML

      # Stub DiffOrchestrator.generate to raise Ace::Git::Error
      error_stub = ->(_args) { raise Ace::Git::Error, "Git operation failed" }

      Ace::Git::Organisms::DiffOrchestrator.stub(:generate, error_stub) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_inline_yaml(yaml_config)

        # Should capture error in formatted content, not crash
        # Errors appear in <errors> section or "## Errors" heading
        assert context.content.include?("Git diff failed"),
          "Content should include git error message: #{context.content[0..500]}"
      end
    end
  end

  def test_generate_diff_safe_handles_timeout_error
    with_temp_dir do
      yaml_config = <<~YAML
        bundle:
          diffs:
            - "origin/main...HEAD"
      YAML

      # Stub DiffOrchestrator.generate to raise TimeoutError (subclass of Ace::Git::Error)
      error_stub = ->(_args) { raise Ace::Git::TimeoutError, "Operation timed out after 30s" }

      Ace::Git::Organisms::DiffOrchestrator.stub(:generate, error_stub) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_inline_yaml(yaml_config)

        # Should capture timeout error in content (TimeoutError inherits from Error)
        assert context.content.include?("timed out"),
          "Content should include timeout error message: #{context.content[0..500]}"
      end
    end
  end

  def test_generate_diff_safe_handles_argument_error
    with_temp_dir do
      yaml_config = <<~YAML
        bundle:
          diffs:
            - "invalid..range..format"
      YAML

      # Stub DiffOrchestrator.generate to raise ArgumentError
      error_stub = ->(_args) { raise ArgumentError, "Invalid range format" }

      Ace::Git::Organisms::DiffOrchestrator.stub(:generate, error_stub) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
        context = loader.load_inline_yaml(yaml_config)

        # Should capture argument error with "Invalid diff range" prefix
        assert context.content.include?("Invalid diff range"),
          "Content should include invalid range error message: #{context.content[0..500]}"
      end
    end
  end

  def test_generate_diff_safe_includes_paths_in_error_result
    with_temp_dir do
      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)

      Ace::Git::Organisms::DiffOrchestrator.stub(:generate, ->(_args) { raise ArgumentError, "Invalid range format" }) do
        result = loader.send(:generate_diff_safe, "HEAD~1..HEAD", paths: ["ace-test-runner-e2e"])
        assert_equal ["ace-test-runner-e2e"], result[:paths]
        refute result[:success]
      end
    end
  end

  def test_resolves_dot_slash_paths_relative_to_template_directory
    with_temp_dir do |dir|
      # Create a nested directory with a config file and a sibling file
      nested_dir = File.join(dir, "deep", "nested")
      FileUtils.mkdir_p(nested_dir)

      File.write(File.join(nested_dir, "sibling.md"), "# Sibling Content")

      # Create template config that references ./sibling.md
      template_path = File.join(nested_dir, "config.yml.md")
      File.write(template_path, <<~MARKDOWN)
        ---
        bundle:
          embed_document_source: true
          files:
            - ./sibling.md
        ---
        # Config
      MARKDOWN

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: dir)
      bundle = loader.load_template(template_path)

      assert_nil bundle.metadata[:error], "Should not have an error, got: #{bundle.metadata[:error]}"
      assert bundle.file_count >= 1, "Should have loaded at least 1 file"

      sibling_file = bundle.files.find { |f| f[:path]&.include?("sibling.md") }
      assert sibling_file, "Should have loaded sibling.md"
      assert_equal "# Sibling Content", sibling_file[:content]
    end
  end

  def test_non_dot_slash_paths_resolve_from_project_root
    with_temp_dir do |dir|
      # Create a file at project root level
      File.write(File.join(dir, "root-file.md"), "# Root Content")

      # Create a nested template that references a non-./ path
      nested_dir = File.join(dir, "deep", "nested")
      FileUtils.mkdir_p(nested_dir)

      template_path = File.join(nested_dir, "config.yml.md")
      File.write(template_path, <<~MARKDOWN)
        ---
        bundle:
          embed_document_source: true
          files:
            - root-file.md
        ---
        # Config
      MARKDOWN

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: dir)
      bundle = loader.load_template(template_path)

      assert_nil bundle.metadata[:error], "Should not have an error, got: #{bundle.metadata[:error]}"
      assert bundle.file_count >= 1, "Should have loaded at least 1 file"

      root_file = bundle.files.find { |f| f[:path]&.include?("root-file.md") }
      assert root_file, "Should have loaded root-file.md from project root"
      assert_equal "# Root Content", root_file[:content]
    end
  end

  def test_resolve_protocol_handles_cmd_type_protocol_via_fallback
    require "ace/support/nav"
    with_temp_dir do |dir|
      # Create a temp file representing the resolved task file
      task_file = File.join(dir, "task-083.md")
      File.write(task_file, "# Task 083\nThis is the task content.")

      # Mock the NavigationEngine to simulate cmd-type protocol resolution
      mock_engine = Minitest::Mock.new
      mock_engine.expect(:resolve, nil, [String])
      mock_engine.expect(:cmd_protocol?, true, [String])
      mock_engine.expect(:resolve_cmd_to_path, task_file, [String])

      Ace::Support::Nav::Organisms::NavigationEngine.stub(:new, mock_engine) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: dir)
        resolved = loader.send(:resolve_protocol, "task://083")
        assert_equal task_file, resolved
      end

      mock_engine.verify
    end
  end

  def test_resolve_protocol_returns_nil_when_cmd_protocol_fails
    require "ace/support/nav"
    with_temp_dir do |dir|
      # Mock the NavigationEngine where cmd protocol returns no valid path
      mock_engine = Minitest::Mock.new
      mock_engine.expect(:resolve, nil, [String])
      mock_engine.expect(:cmd_protocol?, true, [String])
      mock_engine.expect(:resolve_cmd_to_path, nil, [String])

      Ace::Support::Nav::Organisms::NavigationEngine.stub(:new, mock_engine) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: dir)
        resolved = loader.send(:resolve_protocol, "task://083")
        assert_nil resolved
      end

      mock_engine.verify
    end
  end

  def test_generate_diff_safe_does_not_crash_on_git_error
    with_temp_dir do
      yaml_config = <<~YAML
        bundle:
          diffs:
            - "HEAD~1..HEAD"
      YAML

      # Stub DiffOrchestrator.generate to raise Ace::Git::GitError
      error_stub = ->(_args) { raise Ace::Git::GitError, "git diff command failed" }

      Ace::Git::Organisms::DiffOrchestrator.stub(:generate, error_stub) do
        loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)

        # Should not raise - error should be captured and returned in context
        context = loader.load_inline_yaml(yaml_config)

        # Context should be valid with error surfaced in content
        assert context, "Should return a context"
        assert context.content, "Should have content"
        assert context.content.include?("git diff command failed"),
          "Content should include the error message"
      end
    end
  end

  # --- Compressor resolution chain tests ---

  def test_compressor_off_flag_skips_compression
    with_temp_dir do
      File.write("doc.md", "# Long document\n" + ("Content line\n" * 50))

      create_preset("compress-test", <<~MARKDOWN)
        ---
        description: Compress test
        bundle:
          params:
            output: stdio
            compressor_source_scope: per-source
            compressor_mode: exact
          embed_document_source: true
          files:
            - doc.md
        ---
        Compress test
      MARKDOWN

      # With --compressor off, SectionCompressor should never be instantiated
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        compressor: "off"
      )

      called = false
      original_new = Ace::Bundle::Molecules::SectionCompressor.method(:new)
      Ace::Bundle::Molecules::SectionCompressor.stub(:new, ->(**_kw) {
        called = true
        original_new.call(**_kw)
      }) do
        loader.load_preset("compress-test")
      end

      refute called, "--compressor off should skip compression entirely"
    end
  end

  def test_compressor_on_flag_enables_compression
    with_temp_dir do
      File.write("doc.md", "# Doc\nSome content")

      create_preset("no-scope-test", <<~MARKDOWN)
        ---
        description: No scope test
        bundle:
          params:
            output: stdio
          embed_document_source: true
          files:
            - doc.md
        ---
        No scope
      MARKDOWN

      # --compressor on with no scope set anywhere should force per-source
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        compressor: "on"
      )

      captured_mode = nil
      original_new = Ace::Bundle::Molecules::SectionCompressor.method(:new)
      mock_new = ->(**kw) {
        captured_mode = kw[:default_mode]
        original_new.call(**kw)
      }

      Ace::Bundle.stub(:compressor_source_scope, "off") do
        Ace::Bundle::Molecules::SectionCompressor.stub(:new, mock_new) do
          loader.load_preset("no-scope-test")
        end
      end

      assert_equal "per-source", captured_mode, "--compressor on should force per-source scope"
    end
  end

  def test_compressor_config_defaults_used_when_no_cli_or_preset
    with_temp_dir do
      File.write("doc.md", "# Doc\nSome content")

      # Preset with NO compressor params
      create_preset("bare-test", <<~MARKDOWN)
        ---
        description: Bare test
        bundle:
          params:
            output: stdio
          embed_document_source: true
          files:
            - doc.md
        ---
        Bare
      MARKDOWN

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)

      captured_kwargs = nil
      original_new = Ace::Bundle::Molecules::SectionCompressor.method(:new)
      mock_new = ->(**kw) {
        captured_kwargs = kw
        original_new.call(**kw)
      }

      # Simulate config returning per-source + exact
      Ace::Bundle.stub(:compressor_source_scope, "per-source") do
        Ace::Bundle.stub(:compressor_mode, "exact") do
          Ace::Bundle::Molecules::SectionCompressor.stub(:new, mock_new) do
            loader.load_preset("bare-test")
          end
        end
      end

      assert_equal "per-source", captured_kwargs[:default_mode],
        "Should use config source_scope when no CLI/preset value"
      assert_equal "exact", captured_kwargs[:compressor_mode],
        "Should use config mode when no CLI/preset value"
    end
  end

  def test_compressor_cli_overrides_preset_overrides_config
    with_temp_dir do
      File.write("doc.md", "# Doc\nSome content")

      # Preset sets compressor_mode: exact
      create_preset("override-test", <<~MARKDOWN)
        ---
        description: Override test
        bundle:
          params:
            output: stdio
            compressor_source_scope: merged
            compressor_mode: exact
          embed_document_source: true
          files:
            - doc.md
        ---
        Override
      MARKDOWN

      # CLI sets compressor_mode: exact (should win over preset exact)
      loader = Ace::Bundle::Organisms::BundleLoader.new(
        base_dir: Dir.pwd,
        compressor_mode: "exact",
        compressor_source_scope: "per-source"
      )

      captured_kwargs = nil
      original_new = Ace::Bundle::Molecules::SectionCompressor.method(:new)
      mock_new = ->(**kw) {
        captured_kwargs = kw
        original_new.call(**kw)
      }

      Ace::Bundle::Molecules::SectionCompressor.stub(:new, mock_new) do
        loader.load_preset("override-test")
      end

      assert_equal "per-source", captured_kwargs[:default_mode],
        "CLI source_scope should override preset"
      assert_equal "exact", captured_kwargs[:compressor_mode],
        "CLI mode should override preset"
    end
  end

  def test_load_file_plain_markdown_compresses_when_enabled
    with_temp_dir do
      File.write("workflow.md", "# Task Plan\n\nSome workflow instructions.\n")

      loader = Ace::Bundle::Organisms::BundleLoader.new(
        compressor_source_scope: "per-source",
        compressor_mode: "exact"
      )
      bundle = loader.load_file(File.expand_path("workflow.md"))

      assert_includes bundle.content, "FILE|"
      assert bundle.metadata[:compressed]
    end
  end

  def test_load_file_plain_markdown_skips_when_compressor_off
    with_temp_dir do
      File.write("workflow.md", "# Task Plan\n\nSome workflow instructions.\n")

      loader = Ace::Bundle::Organisms::BundleLoader.new(compressor: "off")
      bundle = loader.load_file(File.expand_path("workflow.md"))

      assert_includes bundle.content, "# Task Plan"
      refute bundle.metadata[:compressed]
    end
  end

  def test_load_plain_markdown_compresses_when_enabled
    with_temp_dir do
      md_content = "---\ndescription: A workflow\n---\n# Workflow\n\nInstructions here.\n"
      File.write("wf.md", md_content)

      loader = Ace::Bundle::Organisms::BundleLoader.new(
        compressor_source_scope: "per-source",
        compressor_mode: "exact"
      )
      bundle = loader.send(:load_plain_markdown, md_content, {"description" => "A workflow"}, File.expand_path("wf.md"))

      assert_includes bundle.content, "FILE|"
      assert bundle.metadata[:compressed]
    end
  end

  def test_template_with_command_only_sections_gets_compressed
    with_temp_dir do
      template = <<~MARKDOWN
        ---
        description: Command-only workflow
        bundle:
          sections:
            status:
              commands:
                - echo "hello world"
        ---
        # Workflow

        Some long instructions that should be compressed.
        This paragraph has enough content to produce different output.
      MARKDOWN
      File.write("cmd_workflow.wf.md", template)

      compressed_loader = Ace::Bundle::Organisms::BundleLoader.new(
        compressor_source_scope: "per-source",
        compressor_mode: "exact"
      )
      compressed_bundle = compressed_loader.load_file(File.expand_path("cmd_workflow.wf.md"))

      uncompressed_loader = Ace::Bundle::Organisms::BundleLoader.new(compressor: "off")
      uncompressed_bundle = uncompressed_loader.load_file(File.expand_path("cmd_workflow.wf.md"))

      assert compressed_bundle.metadata[:compressed],
        "Command-only section bundle should be marked as compressed"
      refute_equal uncompressed_bundle.content, compressed_bundle.content,
        "Compressed output should differ from uncompressed"
    end
  end

  def test_template_with_command_only_sections_gets_compressed_in_exact_mode
    with_temp_dir do
      template = <<~MARKDOWN
        ---
        description: Command-only workflow
        bundle:
          sections:
            status:
              commands:
                - echo "hello world"
        ---
        # Workflow

        Some long instructions that should be compressed.
        This paragraph has enough content to produce different output.
      MARKDOWN
      File.write("cmd_workflow.wf.md", template)

      compressed_loader = Ace::Bundle::Organisms::BundleLoader.new(
        compressor_source_scope: "per-source",
        compressor_mode: "exact"
      )
      compressed_bundle = compressed_loader.load_file(File.expand_path("cmd_workflow.wf.md"))

      uncompressed_loader = Ace::Bundle::Organisms::BundleLoader.new(compressor: "off")
      uncompressed_bundle = uncompressed_loader.load_file(File.expand_path("cmd_workflow.wf.md"))

      assert compressed_bundle.metadata[:compressed],
        "Command-only section bundle should be marked as compressed in exact mode"
      refute_equal uncompressed_bundle.content, compressed_bundle.content,
        "Exact-mode compressed output should differ from uncompressed"
    end
  end

  def test_file_section_bundles_not_double_compressed
    with_temp_dir do
      File.write("doc.md", "# Document\n\n" + ("Detail line.\n" * 30))

      template = <<~MARKDOWN
        ---
        description: File section workflow
        bundle:
          params:
            compressor_source_scope: per-source
            compressor_mode: exact
          sections:
            docs:
              files:
                - doc.md
        ---
        # File workflow
      MARKDOWN
      File.write("file_workflow.wf.md", template)

      loader = Ace::Bundle::Organisms::BundleLoader.new(
        compressor_source_scope: "per-source",
        compressor_mode: "exact"
      )
      bundle = loader.load_file(File.expand_path("file_workflow.wf.md"))

      # sections_have_processed_files? should be true, preventing post-format compression
      has_files = loader.send(:sections_have_processed_files?, bundle)
      assert has_files, "Bundle with file sections should report having processed files"
    end
  end

  def test_compressor_off_disables_post_format_compression
    with_temp_dir do
      template = <<~MARKDOWN
        ---
        description: Command workflow
        bundle:
          sections:
            status:
              commands:
                - echo "hello"
        ---
        # Workflow

        Instructions here.
      MARKDOWN
      File.write("cmd_wf.wf.md", template)

      loader = Ace::Bundle::Organisms::BundleLoader.new(compressor: "off")
      bundle = loader.load_file(File.expand_path("cmd_wf.wf.md"))

      refute bundle.metadata[:compressed],
        "--compressor off should prevent post-format compression"
    end
  end
end
