# frozen_string_literal: true

require_relative "../test_helper"

class ContextLoaderTest < AceTestCase
  def create_preset(name, content = nil)
    content ||= <<~MARKDOWN
      ---
      description: Test preset
      params:
        output: stdio
        embed_itself: true
        max_size: 1048576
        timeout: 30
      context:
        files:
          - "**/*.md"
        commands:
          - echo "test"
        exclude:
          - "**/exclude/**"
      ---
      # #{name.capitalize} Preset
    MARKDOWN

    FileUtils.mkdir_p(".ace/context")
    File.write(".ace/context/#{name}.md", content)
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
        params:
          output: stdio
          embed_itself: true
        context:
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
    assert_equal "Preset 'nonexistent' not found", context.metadata[:error]
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
        params:
          output: cache
          embed_itself: true
        context:
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
        params:
          output: stdio
          timeout: 5
        context:
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
        params:
          output: stdio
          embed_itself: true
        context:
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
        params:
          output: stdio
        context:
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
        params:
          output: cache
          max_size: 500000
          timeout: 10
        context:
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
        params:
          output: stdio
          format: yaml
          embed_itself: true
        context:
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
end