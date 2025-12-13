#!/usr/bin/env ruby

require 'minitest/autorun'
require 'tempfile'
require 'fileutils'
require_relative '../rename_ruby_module'

class TestRubyModuleRenameCodemod < Minitest::Test
  def setup
    @fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')
    @temp_dir = Dir.mktmpdir
    @mappings_file = File.join(File.dirname(__FILE__), '..', 'module_mappings.yml')

    # Copy fixtures to temp directory
    FileUtils.cp_r(Dir.glob(File.join(@fixtures_dir, '*')), @temp_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_module_name_replacements
    ruby_file = File.join(@temp_dir, 'sample_module.rb')
    content_before = File.read(ruby_file)

    # Run codemod in apply mode
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content_after = File.read(ruby_file)

    # Check that module names were replaced
    refute_match(/module CodingAgentTools\b/, content_after, "module CodingAgentTools should be replaced")
    refute_match(/class CodingAgentTools\b/, content_after, "class CodingAgentTools should be replaced")
    refute_match(/CodingAgentTools::/, content_after, "CodingAgentTools:: should be replaced")
    refute_match(/::CodingAgentTools/, content_after, "::CodingAgentTools should be replaced")

    # Check that replacements are correct
    assert_match(/module AceTools\b/, content_after, "module AceTools should be present")
    assert_match(/AceTools::Configuration/, content_after, "AceTools::Configuration should be present")
    assert_match(/::AceTools::Error/, content_after, "::AceTools::Error should be present")
  end

  def test_path_replacements
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check snake_case replacements
    refute_match(/require 'coding_agent_tools'/, content, "require 'coding_agent_tools' should be replaced")
    refute_match(/require_relative 'coding_agent_tools/, content, "require_relative 'coding_agent_tools should be replaced")
    refute_match(/'coding_agent_tools\//, content, "paths with coding_agent_tools/ should be replaced")

    assert_match(/require 'ace_tools'/, content, "require 'ace_tools' should be present")
    assert_match(/require_relative 'ace_tools\/version'/, content, "require_relative 'ace_tools/version' should be present")
    assert_match(/'ace_tools\/config'/, content, "'ace_tools/config' should be present")

    # Check dash-case replacements
    refute_match(/coding-agent-tools/, content, "coding-agent-tools should be replaced")
    assert_match(/ace-tools/, content, "ace-tools should be present")
  end

  def test_inheritance_and_includes
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check inheritance
    assert_match(/class CustomClient < AceTools::Client/, content, "Inheritance should use AceTools")
    assert_match(/class Client < AceTools::BaseClient/, content, "BaseClient inheritance should use AceTools")

    # Check includes/extends/prepends
    assert_match(/include AceTools\b/, content, "include should use AceTools")
    assert_match(/extend AceTools::Cli/, content, "extend should use AceTools::Cli")
    assert_match(/prepend AceTools::HTTPHelpers/, content, "prepend should use AceTools::HTTPHelpers")
    assert_match(/include AceTools::HTTPHelpers/, content, "include in class should use AceTools")
  end

  def test_string_and_comment_replacements
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check string replacements
    assert_match(/expect\(described_class\.name\)\.to eq\("AceTools"\)/, content, "String 'AceTools' should be present")
    assert_match(/'module' => 'AceTools'/, content, "Hash value 'AceTools' should be present")
    assert_match(/@name = "AceTools Client"/, content, "String with AceTools should be updated")

    # Check comment replacements
    assert_match(/# The AceTools module provides/, content, "Comment should use AceTools")
    assert_match(/# See ace_tools documentation/, content, "Comment should use ace_tools")
    assert_match(/# Run with: ace-tools --help/, content, "Comment should use ace-tools")
  end

  def test_method_calls_and_constants
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check method calls
    assert_match(/AceTools\.configure/, content, "AceTools.configure should be present")
    assert_match(/AceTools\.process_data/, content, "AceTools.process_data should be present")
    assert_match(/AceTools::Logger\.info/, content, "AceTools::Logger.info should be present")
    assert_match(/AceTools::Client\.new/, content, "AceTools::Client.new should be present")
    assert_match(/AceTools::VERSION/, content, "AceTools::VERSION should be present")
  end

  def test_autoload_statements
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check autoload
    assert_match(/autoload :AceTools, 'ace_tools'/, content, "autoload should use :AceTools and 'ace_tools'")
  end

  def test_gem_specification
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run codemod
    options = { dry_run: false, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content = File.read(ruby_file)

    # Check gem specification
    assert_match(/spec\.name = "ace_tools"/, content, "Gem name should be ace_tools")
    assert_match(/spec\.require_paths = \["lib\/ace_tools"\]/, content, "Require paths should use ace_tools")
    assert_match(/spec\.executables = \["ace-tools"\]/, content, "Executables should use ace-tools")
  end

  def test_dry_run_mode
    ruby_file = File.join(@temp_dir, 'sample_module.rb')
    content_before = File.read(ruby_file)

    # Run in dry-run mode
    options = { dry_run: true, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    content_after = File.read(ruby_file)

    # Content should not change in dry-run mode
    assert_equal content_before, content_after, "Files should not be modified in dry-run mode"
  end

  def test_backup_creation
    ruby_file = File.join(@temp_dir, 'sample_module.rb')

    # Run with backup enabled
    options = { dry_run: false, backup: true, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    backup_file = "#{ruby_file}.bak"
    assert File.exist?(backup_file), "Backup file should be created"

    # Backup should contain original content
    backup_content = File.read(backup_file)
    assert_match(/module CodingAgentTools/, backup_content, "Backup should contain original module name")
  end

  def test_statistics
    options = { dry_run: true, backup: false, root: @temp_dir, verbose: false }
    codemod = RubyModuleRenameCodemod.new(@mappings_file, options)
    codemod.run

    stats = codemod.stats

    assert stats[:files_scanned] > 0, "Should scan files"
    assert stats[:files_modified] > 0, "Should identify files to modify"
    assert stats[:total_replacements] > 0, "Should count replacements"
    assert_equal 0, stats[:errors].size, "Should not have errors for valid files"

    # Check that we have detailed replacement tracking
    assert stats[:replacements_by_type].any?, "Should track replacements by type"
    assert stats[:replacements_by_type].key?("CodingAgentTools->AceTools"), "Should track module replacements"
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
    mappings_file = File.join(File.dirname(__FILE__), '..', 'module_mappings.yml')

    if File.exist?(mappings_file) && Dir.exist?(fixtures_dir)
      puts "✓ Mappings file exists"
      puts "✓ Fixtures directory exists"

      # Test dry-run
      options = { dry_run: true, backup: false, root: fixtures_dir, verbose: true }
      codemod = RubyModuleRenameCodemod.new(mappings_file, options)
      codemod.run

      puts "\n✓ Module rename codemod runs successfully in dry-run mode"
      puts "\nTo run full tests, install minitest: gem install minitest"
    else
      puts "✗ Missing required files for testing"
      exit 1
    end
  end
end