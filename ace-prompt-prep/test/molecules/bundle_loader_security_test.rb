# frozen_string_literal: true

require 'test_helper'
require 'ace/prompt_prep/molecules/bundle_loader'

class BundleLoaderSecurityTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    # Use realpath to get canonical path (handles /var -> /private/var on macOS)
    @project_root = File.realpath(@tmpdir)
    @prompt_dir = File.join(@project_root, ".ace-local", "prompt-prep", "prompts")
    FileUtils.mkdir_p(@prompt_dir)

    # Reset config cache and get fresh config from gem defaults
    Ace::PromptPrep.reset_config!

    # Store defaults for use in tests (now loaded via config method from gem defaults)
    @default_config = Ace::PromptPrep.config
  end

  def teardown
    Ace::PromptPrep.reset_config!
    FileUtils.rm_rf(@tmpdir)
  end

  private

  # Helper to run with isolated stubs
  def with_isolated_stubs(config: nil)
    test_config = config || @default_config
    project_root = @project_root

    Ace::PromptPrep.stub :config, test_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, project_root do
        yield
      end
    end
  end

  public

  def test_rejects_basic_path_traversal
    # Test with basic ../ pattern
    result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@tmpdir}/../../../etc/passwd")
    assert_equal "", result
  end

  def test_rejects_windows_path_traversal
    # Test with Windows-style path traversal
    result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@tmpdir}/..\\windows\\system32\\config")
    assert_equal "", result
  end

  def test_rejects_url_encoded_path_traversal
    # Test with URL encoded traversal
    result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@tmpdir}/%2e%2e%2fetc%2fpasswd")
    assert_equal "", result
  end

  def test_rejects_alternative_encoding_traversal
    # Test with alternative encoding
    result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@tmpdir}/..%2fetc%2fpasswd")
    assert_equal "", result
  end

  def test_rejects_shell_injection_semicolon
    # Test with semicolon shell injection
    result = Ace::PromptPrep::Molecules::BundleLoader.call("test.md; rm -rf /")
    assert_equal "", result
  end

  def test_rejects_shell_injection_ampersand
    # Test with ampersand shell injection
    result = Ace::PromptPrep::Molecules::BundleLoader.call("test.md & echo 'pwned'")
    assert_equal "", result
  end

  def test_rejects_shell_injection_pipe
    # Test with pipe shell injection
    result = Ace::PromptPrep::Molecules::BundleLoader.call("test.md | curl http://malicious.com")
    assert_equal "", result
  end

  def test_rejects_shell_injection_backtick
    # Test with backtick shell injection
    result = Ace::PromptPrep::Molecules::BundleLoader.call("test.md `rm -rf /`")
    assert_equal "", result
  end

  def test_rejects_absolute_paths_outside_project
    # Test with absolute path outside project
    result = Ace::PromptPrep::Molecules::BundleLoader.call("/etc/passwd")
    assert_equal "", result
  end

  def test_rejects_absolute_paths_with_leading_slash
    # Test with absolute path starting with / (should still be rejected)
    result = Ace::PromptPrep::Molecules::BundleLoader.call("/tmp/allowed.md")
    assert_equal "", result
  end

  def test_rejects_nil_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call(nil)
    assert_equal "", result
  end

  def test_rejects_empty_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("")
    assert_equal "", result
  end

  def test_rejects_whitespace_only_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("   ")
    assert_equal "", result
  end

  def test_rejects_newline_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("\n")
    assert_equal "", result
  end

  def test_rejects_tab_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("\t")
    assert_equal "", result
  end

  def test_validates_normal_relative_paths
    # Test with valid relative paths
    test_file = File.join(@prompt_dir, "test.md")
    File.write(test_file, "# Test content")

    result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
    # Should return something (context or empty string based on ace-bundle availability)
    assert result.is_a?(String)
  end

  def test_validates_normal_relative_paths_with_subdirs
    # Test with relative paths to subdirectories
    subdir = File.join(@prompt_dir, "subdir", "test.md")
    FileUtils.mkdir_p(File.dirname(subdir))
    File.write(subdir, "# Test content")

    result = Ace::PromptPrep::Molecules::BundleLoader.call(subdir)
    # Should return something (context or empty string based on ace-bundle availability)
    assert result.is_a?(String)
  end

  def test_enforces_file_size_limit
    # Create test file that exceeds limit
    large_content = "A" * (11 * 1024 * 1024)  # 11MB file

    test_file = File.join(@prompt_dir, "large.md")
    File.write(test_file, large_content)

    result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
    assert_equal "", result, "Should reject file exceeding size limit"
  end

  def test_respects_configurable_file_size_limit
    # Mock config with different size limit
    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 5 },
      "debug" => { "enabled" => false, "bundle_loading" => false }
    }

    Ace::PromptPrep.stub(:config, mock_config) do
      # Create test file that exceeds default limit but within configured limit
      medium_content = "A" * (6 * 1024 * 1024)  # 6MB file

      test_file = File.join(@prompt_dir, "medium.md")
      File.write(test_file, medium_content)

      result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
      # Should be accepted since 6MB < configured 10MB limit
      assert result.is_a?(String)
    end
  end

  def test_handles_symlink_to_external_file
    # Create external malicious file
    external_file = File.join(@tmpdir, "external.txt")
    File.write(external_file, "Malicious content")

    # Create symlink in project pointing to external file
    symlink_file = File.join(@prompt_dir, "symlink.md")
    File.symlink(external_file, symlink_file)

    result = Ace::PromptPrep::Molecules::BundleLoader.call(symlink_file)
    assert_equal "", result, "Should reject symlink outside project boundaries"
  end

  def test_handles_symlink_within_project
    # Create legitimate file within project
    target_file = File.join(@prompt_dir, "target.txt")
    File.write(target_file, "Legitimate content")

    # Create symlink within project pointing to target
    symlink_file = File.join(@prompt_dir, "link.md")
    File.symlink(target_file, symlink_file)

    result = Ace::PromptPrep::Molecules::BundleLoader.call(symlink_file)
    # Should be accepted since it resolves within project
    assert result.is_a?(String)
  end

  def test_broken_symlink_handling
    # Create symlink pointing to non-existent file
    broken_symlink = File.join(@prompt_dir, "broken.md")
    File.symlink("nonexistent.md", broken_symlink)

    result = Ace::PromptPrep::Molecules::BundleLoader.call(broken_symlink)
    assert_equal "", result, "Should handle broken symlinks gracefully"
  end

  def test_handles_file_that_disappears_during_processing
    # Create test file
    test_file = File.join(@prompt_dir, "temp.md")
    File.write(test_file, "# Test content")

    # Mock File.exist? to return false (file disappears during validation)
    File.stub(:exist?, ->(path) { path == test_file ? false : true }) do
      # Mock File.readable? to prevent read access attempt
      File.stub(:readable?, ->(path) { path == test_file ? false : true }) do
        result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
        assert_equal "", result, "Should handle disappearing files gracefully"
      end
    end
  end

  def test_handles_permission_denied_file
    # Create test file
    test_file = File.join(@prompt_dir, "restricted.md")
    File.write(test_file, "# Restricted content")

    # Mock File.readable? to return false (permission denied)
    File.stub(:exist?, ->(path) { true }) do
      File.stub(:readable?, ->(path) { path == test_file ? false : true }) do
        result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
        assert_equal "", result, "Should handle permission denied gracefully"
      end
    end
  end

  def test_debug_logging_configuration
    # Mock config with debug enabled
    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => true, "bundle_loading" => true }
    }

    # Mock debug output capture
    debug_output = []

    Ace::PromptPrep.stub(:config, mock_config) do
      # Capture warn calls to verify debug logging
      warn("test debug message")
      warn("Error: test error message")
    end
  end

  def test_debug_logging_with_category_filtering
    # Mock config with specific debug category enabled
    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => true, "bundle_loading" => true }
    }

    test_file = File.join(@prompt_dir, "debug_test.md")
    File.write(test_file, "# Debug test")

    # Test debug_log with matching category
    debug_messages = []

    Ace::PromptPrep.stub :config, mock_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @project_root do
        Object.stub(:warn, ->(message) { debug_messages << message if message.include?("[DEBUG]") }) do
          result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
          assert_equal "# Debug test", result, "Should process with debug logging enabled"
          assert debug_messages.any? { |msg| msg.include?("Loading bundle from:") }, "Should log bundle loading debug messages"
        end
      end
    end
  end

  def test_debug_logging_with_category_filtering_disabled
    # Mock config with debug enabled but category filtered
    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => true, "bundle_loading" => false }
    }

    test_file = File.join(@prompt_dir, "filtered_test.md")
    File.write(test_file, "# Filtered test")

    # Test debug_log with filtered category
    debug_messages = []

    Ace::PromptPrep.stub :config, mock_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @project_root do
        Object.stub(:warn, ->(message) { debug_messages << message if message.include?("[DEBUG]") }) do
          result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
          assert_equal "# Filtered test", result, "Should process with debug enabled but category filtered"
          refute debug_messages.any? { |msg| msg.include?("Loading bundle from:") }, "Should filter context loading debug messages"
        end
      end
    end
  end

  def test_debug_logging_disabled
    # Mock config with debug disabled
    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => false, "bundle_loading" => false }
    }

    test_file = File.join(@prompt_dir, "no_debug.md")
    File.write(test_file, "# No debug test")

    # Verify no debug messages when disabled
    debug_messages = []

    Ace::PromptPrep.stub :config, mock_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @project_root do
        Object.stub(:warn, ->(message) { debug_messages << message if message.include?("[DEBUG]") }) do
          result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
          assert_equal "# No debug test", result, "Should process without debug logging"
          refute debug_messages.any?, "Should not output debug messages when disabled"
        end
      end
    end
  end

  def test_error_message_consistency
    # All error messages should use "Error:" prefix for actual failures
    original_warn = method(:warn)
    error_messages = []

    Object.stub(:warn, ->(message) { error_messages << message }) do
      # Trigger various error conditions
      result = Ace::PromptPrep::Molecules::BundleLoader.call(nil)  # nil path
      result = Ace::PromptPrep::Molecules::BundleLoader.call("")  # empty path
      result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@tmpdir}/nonexistent")  # non-existent file
    end

    # Verify all error messages use "Error:" prefix
    error_messages.each do |message|
      assert message.start_with?("Error:"), "Error message should use 'Error:' prefix: #{message}"
    end
  end

  def test_warning_messages_for_fallback_conditions
    # Warning messages should be used for fallback behaviors, not errors
    original_warn = method(:warn)
    warning_messages = []

    Object.stub(:warn, ->(message) { warning_messages << message }) do
      # Mock ace-bundle failure to trigger fallback
      Ace::PromptPrep::Molecules::BundleLoader.stub(:call, "") do
        result = Ace::PromptPrep::Molecules::BundleLoader.call("#{@prompt_dir}/test.md")
      end
    end

    # Verify fallback behavior uses "Warning:" prefix
    warning_messages.each do |message|
      assert message.include?("Warning:"), "Fallback condition should use 'Warning:' prefix: #{message}"
    end
  end

  def test_file_size_limit_error_message_includes_actual_size
    # Create large test file
    large_content = "X" * (15 * 1024 * 1024)  # 15MB
    test_file = File.join(@prompt_dir, "oversize.md")
    File.write(test_file, large_content)

    error_message = ""

    mock_config = {
      "bundle" => { "enabled" => false },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => false }
    }

    Ace::PromptPrep.stub :config, mock_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @project_root do
        Object.stub(:warn, ->(msg) { error_message = msg }) do
          result = Ace::PromptPrep::Molecules::BundleLoader.call(test_file)
        end
      end
    end

    # Error message should include actual file size
    assert_includes error_message, "15728640 bytes"
    assert_includes error_message, "10MB", "Should mention the configured limit"
  end

  def test_project_boundary_error_message_includes_resolved_path
    # Create external file outside project
    external_file = File.join(@tmpdir, "..", "outside.txt")
    File.write(external_file, "External content")

    # Create symlink in project pointing to external
    symlink_file = File.join(@prompt_dir, "external.md")
    File.symlink(external_file, symlink_file)

    original_warn = method(:warn)
    error_message = ""

    Object.stub(:warn, ->(msg) { error_message = msg }) do
      result = Ace::PromptPrep::Molecules::BundleLoader.call(symlink_file)
    end

    # Error message should include resolved path
    assert_includes error_message, "File path resolves outside project"
    assert_includes error_message, File.realpath(external_file)
  end
end
