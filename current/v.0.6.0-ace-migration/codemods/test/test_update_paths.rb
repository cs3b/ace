#!/usr/bin/env ruby

require 'minitest/autorun'
require 'tempfile'
require 'fileutils'
require_relative '../update_paths'

class TestPathUpdateCodemod < Minitest::Test
  def setup
    @fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')
    @temp_dir = Dir.mktmpdir
    @mappings_file = File.join(File.dirname(__FILE__), '..', 'path_mappings.yml')

    # Copy fixtures to temp directory
    FileUtils.cp_r(Dir.glob(File.join(@fixtures_dir, '*')), @temp_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_ruby_file_replacements
    ruby_file = File.join(@temp_dir, 'sample.rb')
    content_before = File.read(ruby_file)

    # Run codemod in apply mode
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    content_after = File.read(ruby_file)

    # Check that paths were replaced
    refute_match(/.ace/tools\//, content_after, ".ace/tools/ should be replaced")
    refute_match(/.ace/handbook\//, content_after, ".ace/handbook/ should be replaced")
    refute_match(/.ace/taskflow\//, content_after, ".ace/taskflow/ should be replaced")
    refute_match(/dev-local\//, content_after, ".ace/local/ should be replaced")

    # Check that replacements are correct
    assert_match(/\.ace\/tools\//, content_after, ".ace/tools/ should be present")
    assert_match(/\.ace\/handbook\//, content_after, ".ace/handbook/ should be present")
    assert_match(/\.ace\/taskflow\//, content_after, ".ace/taskflow/ should be present")
    assert_match(/\.ace\/local\//, content_after, ".ace/local/ should be present")

    # Ensure quoted strings are preserved
    assert_match(/"\.ace\/handbook\/docs"/, content_after, "Quoted paths should preserve quotes")
    assert_match(/'\.ace\/tools\/bin'/, content_after, "Single quoted paths should preserve quotes")
  end

  def test_markdown_file_replacements
    md_file = File.join(@temp_dir, 'sample.md')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(md_file)

    # Check markdown links
    assert_match(/\[Tools Documentation\]\(\.ace\/tools\/docs\/README\.md\)/, content,
                 "Markdown links should be updated")
    assert_match(/\[handbook\]: \.ace\/handbook\/README\.md/, content,
                 "Reference-style links should be updated")

    # Check inline code
    assert_match(/`\.ace\/tools\/`/, content, "Inline code paths should be updated")

    # Check code blocks
    assert_match(/cd \.ace\/tools\//, content, "Paths in code blocks should be updated")
    assert_match(/require '\.ace\/tools\/lib\/tool'/, content, "Ruby code in markdown should be updated")

    # Check tables
    assert_match(/\| `\.ace\/tools\/` \|/, content, "Paths in tables should be updated")
  end

  def test_yaml_file_replacements
    yaml_file = File.join(@temp_dir, 'sample.yml')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(yaml_file)

    # Check various YAML value formats
    assert_match(/tools: \.ace\/tools\//, content, "Plain YAML values should be updated")
    assert_match(/tool_path: "\.ace\/tools\/"/, content, "Quoted YAML values should be updated")
    assert_match(/handbook_path: '\.ace\/handbook\/'/, content, "Single quoted YAML values should be updated")

    # Check arrays
    assert_match(/- \.ace\/tools\/bin/, content, "Array items should be updated")

    # Check comments
    assert_match(/# Located in \.ace\/tools\/config/, content, "Comments should be updated")

    # Check environment variables
    assert_match(/TOOLS_DIR: \$\{PWD\}\/\.ace\/tools\//, content, "Environment variables should be updated")

    # Check shell commands
    assert_match(/cd \.ace\/tools\/ && make build/, content, "Shell commands should be updated")
  end

  def test_dry_run_mode
    ruby_file = File.join(@temp_dir, 'sample.rb')
    content_before = File.read(ruby_file)

    # Run in dry-run mode
    options = { dry_run: true, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    content_after = File.read(ruby_file)

    # Content should not change in dry-run mode
    assert_equal content_before, content_after, "Files should not be modified in dry-run mode"
  end

  def test_backup_creation
    ruby_file = File.join(@temp_dir, 'sample.rb')

    # Run with backup enabled
    options = { dry_run: false, backup: true, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    backup_file = "#{ruby_file}.bak"
    assert File.exist?(backup_file), "Backup file should be created"

    # Backup should contain original content
    backup_content = File.read(backup_file)
    assert_match(/.ace/tools\//, backup_content, "Backup should contain original paths")
  end

  def test_statistics
    options = { dry_run: true, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    stats = codemod.stats

    assert stats[:files_scanned] > 0, "Should scan files"
    assert stats[:files_modified] > 0, "Should identify files to modify"
    assert stats[:total_replacements] > 0, "Should count replacements"
    assert_equal 0, stats[:errors].size, "Should not have errors for valid files"
  end

  def test_path_variations
    # Create a test file with edge cases
    test_file = File.join(@temp_dir, 'edge_cases.txt')
    File.write(test_file, <<~CONTENT)
      .ace/tools/
      .ace/tools
      ".ace/handbook/"
      '.ace/taskflow/'
      .ace/local/
      some.ace/tools/shouldnotchange
      .ace/toolsuffix/shouldnotchange
      https://example.com/.ace/tools/
      /absolute/.ace/handbook/path
      ./relative/.ace/taskflow/path
      ../parent/.ace/local/path
    CONTENT

    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = PathUpdateCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(test_file)

    # Should replace
    assert_match(/^\.ace\/tools\/$/, content, "Simple path with slash")
    assert_match(/^\.ace\/tools$/, content, "Simple path without slash")
    assert_match(/^"\.ace\/handbook\/"$/, content, "Quoted path")
    assert_match(/^'\.ace\/taskflow\/'$/, content, "Single quoted path")

    # Should not replace these
    assert_match(/some.ace/tools\/shouldnotchange/, content, "Should not replace partial matches")
    assert_match(/.ace/toolsuffix\/shouldnotchange/, content, "Should not replace suffixed matches")
  end
end

# Run tests if executed directly
if __FILE__ == $0
  # Check if minitest is available
  begin
    require 'minitest'
  rescue LoadError
    puts "Note: minitest gem not found. Install with: gem install minitest"
    puts "Running basic validation instead..."

    # Basic validation without minitest
    fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')
    mappings_file = File.join(File.dirname(__FILE__), '..', 'path_mappings.yml')

    if File.exist?(mappings_file) && Dir.exist?(fixtures_dir)
      puts "✓ Mappings file exists"
      puts "✓ Fixtures directory exists"

      # Test dry-run
      options = { dry_run: true, backup: false, root: fixtures_dir, verbose: true }
      codemod = PathUpdateCodemod.new(mappings_file, options)
      codemod.run

      puts "\n✓ Codemod runs successfully in dry-run mode"
      puts "\nTo run full tests, install minitest: gem install minitest"
    else
      puts "✗ Missing required files for testing"
      exit 1
    end
  end
end