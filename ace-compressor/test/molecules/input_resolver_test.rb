# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class InputResolverTest < AceCompressorTestCase
  Status = Struct.new(:ok) do
    def success?
      ok
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_input_resolver")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_keeps_existing_file_path_without_bundle_resolution
    file_path = File.join(@tmp, "project")
    File.write(file_path, "# Local file wins")

    shell_calls = []
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      [file_path],
      shell_runner: lambda do |command|
        shell_calls << command
        ["", "", Status.new(true)]
      end
    )

    resolved = resolver.call

    assert_equal [{content_path: file_path, source_path: file_path, source_kind: "file"}], resolved
    assert_empty shell_calls
  end

  def test_resolves_preset_with_ace_bundle
    shell_calls = []
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      ["project"],
      shell_runner: lambda do |command|
        shell_calls << command
        output_path = command.last
        File.write(output_path, "# Bundled\n\ncontent")
        ["", "", Status.new(true)]
      end
    )

    resolved = resolver.call

    assert_equal 1, resolved.size
    assert File.file?(resolved.first[:content_path])
    assert_equal "project", resolved.first[:source_path]
    assert_equal "preset", resolved.first[:source_kind]
    assert_equal "ace-bundle", shell_calls.first.first
    assert_equal "project", shell_calls.first[1]
    assert_includes shell_calls.first, "--output"
  end

  def test_existing_yaml_config_file_is_resolved_with_ace_bundle
    config_path = File.join(@tmp, "custom-context.yml")
    File.write(config_path, "bundle:\n  files:\n    - docs/vision.md\n")
    shell_calls = []
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      [config_path],
      shell_runner: lambda do |command|
        shell_calls << command
        output_path = command.last
        File.write(output_path, "# Bundled\n\nyaml config")
        ["", "", Status.new(true)]
      end
    )

    resolved = resolver.call

    assert_equal 1, resolved.size
    assert File.file?(resolved.first[:content_path])
    assert_equal config_path, resolved.first[:source_path]
    assert_equal "bundle_config", resolved.first[:source_kind]
    assert_equal "ace-bundle", shell_calls.first.first
    assert_equal config_path, shell_calls.first[1]
  end

  def test_missing_config_file_fails_with_input_source_not_found
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      ["./missing-config.yml"],
      shell_runner: ->(*) { raise "shell should not be called" }
    )

    error = assert_raises(Ace::Compressor::Error) { resolver.call }
    assert_includes error.message, "Input source not found: ./missing-config.yml"
  end

  def test_mixed_preset_and_file_input_resolves_in_single_run
    local_file = File.join(@tmp, "custom-context.md")
    File.write(local_file, "# Local\n\ncontext")

    resolver = Ace::Compressor::Molecules::InputResolver.new(
      ["project", local_file],
      shell_runner: lambda do |command|
        output_path = command.last
        File.write(output_path, "# Bundled\n\npreset context")
        ["", "", Status.new(true)]
      end
    )

    resolved = resolver.call

    assert_equal 2, resolved.size
    assert File.file?(resolved.first[:content_path])
    assert_equal "project", resolved.first[:source_path]
    assert_equal local_file, resolved.last[:content_path]
    assert_equal local_file, resolved.last[:source_path]
  end

  def test_unknown_preset_propagates_input_name
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      ["unknown-preset"],
      shell_runner: lambda do |_command|
        ["", "Preset not found: unknown-preset", Status.new(false)]
      end
    )

    error = assert_raises(Ace::Compressor::Error) { resolver.call }
    assert_includes error.message, "Failed to resolve input 'unknown-preset'"
    assert_includes error.message, "Preset not found: unknown-preset"
  end

  def test_unresolved_protocol_propagates_url_in_error
    resolver = Ace::Compressor::Molecules::InputResolver.new(
      ["wfi://missing/workflow"],
      shell_runner: lambda do |_command|
        ["", "Workflow not found: wfi://missing/workflow", Status.new(false)]
      end
    )

    error = assert_raises(Ace::Compressor::Error) { resolver.call }
    assert_includes error.message, "Failed to resolve input 'wfi://missing/workflow'"
    assert_includes error.message, "Workflow not found: wfi://missing/workflow"
  end
end
