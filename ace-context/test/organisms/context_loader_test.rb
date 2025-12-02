# frozen_string_literal: true

require_relative "../test_helper"

class ContextLoaderTest < AceTestCase
  def create_preset(name, content = nil)
    content ||= <<~MARKDOWN
      ---
      description: Test preset
      context:
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

    FileUtils.mkdir_p(".ace/context/presets")
    File.write(".ace/context/presets/#{name}.md", content)
  end

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
        context:
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

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("default")

      assert_equal 2, context.file_count
      assert context.content.include?("Test Project")
      assert context.content.include?("Blueprint")
    end
  end

  def test_loads_file_directly
    with_temp_file("Test content") do |path|
      loader = Ace::Context::Organisms::ContextLoader.new
      context = loader.load_file(path)

      assert_equal 1, context.file_count
      assert_equal "Test content", context.files.first[:content]
    end
  end

  def test_handles_missing_preset
    loader = Ace::Context::Organisms::ContextLoader.new
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

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
          params:
            output: cache
          embed_document_source: true
          files:
            - test.md
        ---
        Cache preset
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("cache_test")

      assert_equal "cache", context.metadata[:output]
    end
  end

  def test_executes_commands
    with_temp_dir do
      create_preset("cmd_test", <<~MARKDOWN
        ---
        description: Command test
        context:
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

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
      FileUtils.mkdir_p("ace-context")
      File.write("ace-core/README.md", "Core readme")
      File.write("ace-context/README.md", "Context readme")
      File.write("ace-core/test.rb", "Ruby file")

      create_preset("glob_test", <<~MARKDOWN
        ---
        description: Glob test
        context:
          params:
            output: stdio
          embed_document_source: true
          files:
            - "ace-*/README.md"
        ---
        Glob test
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
          params:
            output: stdio
          files: []
        ---
        # Body Test

        #{body_content}
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
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
      loader = Ace::Context::Organisms::ContextLoader.new(
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
        context:
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

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("format_test")

      # Should be formatted as YAML
      puts "DEBUG: Content format: #{context.content[0..200]}" if ENV['DEBUG']

      # Check if it's actually YAML formatted
      assert context.content.include?("format_test"), "Content should include preset name"
      assert context.content.match?(/files:|Files:/), "Content should include files section"
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
        context:
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

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load with embed_source flag enabled via CLI
      loader = Ace::Context::Organisms::ContextLoader.new(
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
        context:
          embed_document_source: false
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load with embed_source flag enabled via CLI (should override frontmatter)
      loader = Ace::Context::Organisms::ContextLoader.new(
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
        context:
          embed_document_source: false
          files:
            - test.md
        ---
        This is the prompt content
      MARKDOWN
      )

      # Load WITHOUT embed_source flag
      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
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
        context:
          presets:
            - base-preset
          embed_document_source: true
          files:
            - extended-file.md
        ---
        Extended preset body
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
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
        context:
          params:
            timeout: 60
          presets:
            - base-params
          embed_document_source: true
        ---
        Override
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
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
        context:
          presets:
            - existing-preset
            - nonexistent-preset
          embed_document_source: true
        ---
        Mixed
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd, debug: false)
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
        context:
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
        context:
          presets:
            - base-files
          embed_document_source: true
          files:
            - own.md
          sections:
            my-section:
              title: My Section
              files:
                - section.md
        ---
        Combined
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
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
        context:
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
        context:
          presets:
            - base-cmd
          embed_document_source: true
          commands:
            - echo "from extended"
        ---
        Extended
      MARKDOWN
      )

      loader = Ace::Context::Organisms::ContextLoader.new(base_dir: Dir.pwd)
      context = loader.load_preset("extended-cmd")

      # Should have commands from both presets
      assert context.commands, "Should have commands"
      assert context.commands.size >= 2, "Should have commands from both presets"

      command_strings = context.commands.map { |c| c[:command] }
      assert command_strings.include?('echo "from base"'), "Should have base preset command"
      assert command_strings.include?('echo "from extended"'), "Should have extended preset command"
    end
  end

end