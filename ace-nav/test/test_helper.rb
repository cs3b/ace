# frozen_string_literal: true

require "ace/nav"

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"

module TestHelper
  # Create a temporary directory structure for testing
  def create_temp_ace_directory
    Dir.mktmpdir("ace_nav_test")
  end

  # Clean up temporary directory
  def cleanup_temp_directory(dir)
    FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
  end

  # Create a test protocol configuration
  def create_test_protocol(dir, protocol_name, config = {})
    protocols_dir = File.join(dir, ".ace", "protocols")
    FileUtils.mkdir_p(protocols_dir)

    protocol_config = {
      "protocol" => protocol_name,
      "name" => config["name"] || protocol_name.capitalize,
      "description" => config["description"] || "Test protocol",
      "enabled" => config.fetch("enabled", true),
      "extensions" => config["extensions"] || [".#{protocol_name}.md"],
      "capabilities" => config["capabilities"] || {
        "searchable" => true,
        "supports_glob" => true
      }
    }

    File.write(
      File.join(protocols_dir, "#{protocol_name}.yml"),
      protocol_config.to_yaml
    )
  end

  # Create a test source registration
  def create_test_source(dir, protocol_name, source_name, config = {})
    sources_dir = File.join(dir, ".ace", "nav/protocols", "#{protocol_name}-sources")
    FileUtils.mkdir_p(sources_dir)

    source_config = {
      "name" => source_name,
      "type" => config["type"] || "directory",
      "path" => config["path"] || File.join(dir, "test-resources", protocol_name),
      "description" => config["description"] || "Test source"
    }

    # Only add priority if explicitly provided
    source_config["priority"] = config["priority"] if config.key?("priority")

    File.write(
      File.join(sources_dir, "#{source_name}.yml"),
      source_config.to_yaml
    )
  end

  # Create test resource files
  def create_test_resource(dir, protocol_name, resource_name, content = nil)
    resource_dir = File.join(dir, "test-resources", protocol_name)
    FileUtils.mkdir_p(resource_dir)

    extension = ".#{protocol_name}.md"
    file_path = File.join(resource_dir, "#{resource_name}#{extension}")

    File.write(file_path, content || "# Test Resource: #{resource_name}\nTest content")
    file_path
  end

  # Create a complete test environment with protocols and resources
  def setup_test_environment
    temp_dir = create_temp_ace_directory

    # Create some test protocols
    create_test_protocol(temp_dir, "test", {
      "extensions" => [".test.md", ".tst.md"]
    })

    create_test_protocol(temp_dir, "example", {
      "extensions" => [".example.md", ".ex.md"]
    })

    # Create test sources
    create_test_source(temp_dir, "test", "local", {
      "priority" => 10
    })

    create_test_source(temp_dir, "example", "local", {
      "priority" => 10
    })

    # Create some test resources
    create_test_resource(temp_dir, "test", "sample")
    create_test_resource(temp_dir, "test", "demo")
    create_test_resource(temp_dir, "example", "tutorial")

    temp_dir
  end

  # Mock ConfigLoader that uses a test directory
  def create_test_config_loader(test_dir)
    # Create config loader with test directory without changing dirs
    config_loader = Ace::Nav::Molecules::ConfigLoader.new(
      File.join(test_dir, ".ace", "nav")
    )

    # Monkey patch to use test directory for protocol discovery
    config_loader.instance_variable_set(:@test_dir, test_dir)
    def config_loader.discover_project_protocol_dirs
      test_dir = @test_dir
      dirs = []
      protocol_dir = File.join(test_dir, ".ace", "protocols")
      dirs << protocol_dir if Dir.exist?(protocol_dir)
      dirs
    end

    config_loader
  end

  # Assert that a file exists with optional content check
  def assert_file_exists(path, message = nil)
    assert File.exist?(path), message || "Expected file #{path} to exist"
  end

  # Assert file contains specific content
  def assert_file_contains(path, content, message = nil)
    assert_file_exists(path)
    file_content = File.read(path)
    assert file_content.include?(content),
           message || "Expected #{path} to contain '#{content}'"
  end
end

class Minitest::Test
  include TestHelper
end