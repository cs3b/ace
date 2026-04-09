# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/molecules/package_resolver"
require "tmpdir"
require "fileutils"
require "yaml"

class PackageResolverTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @project_root = File.expand_path("../..", __dir__)
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
  end

  # Test initialization and project root detection

  def test_finds_project_root
    resolver = Ace::TestRunner::Molecules::PackageResolver.new
    assert resolver.project_root, "Should find project root"
  end

  def test_accepts_custom_project_root
    Dir.mktmpdir do |dir|
      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: dir)
      assert_equal dir, resolver.project_root
    end
  end

  # Test resolve method with package names

  def test_resolves_package_by_exact_name
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve("ace-bundle")
    assert result, "Should resolve ace-bundle"
    assert result.end_with?("ace-bundle"), "Should end with package name"
    assert Dir.exist?(result), "Resolved path should exist"
  end

  def test_resolves_package_without_ace_prefix
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve("bundle")
    assert result, "Should resolve 'bundle' to 'ace-bundle'"
    assert result.end_with?("ace-bundle"), "Should resolve to ace-bundle"
  end

  def test_returns_nil_for_nonexistent_package
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve("nonexistent-package")
    assert_nil result, "Should return nil for nonexistent package"
  end

  # Test resolve method with paths

  def test_resolves_absolute_path
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    ace_context_path = File.join(mono_repo_root, "ace-bundle")
    result = resolver.resolve(ace_context_path)
    assert result, "Should resolve absolute path"
    assert_equal File.realpath(ace_context_path), result
  end

  def test_resolves_relative_path_with_dot_slash
    Dir.chdir(mono_repo_root) do
      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

      result = resolver.resolve("./ace-bundle")
      assert result, "Should resolve ./ace-bundle"
      assert result.end_with?("ace-bundle")
    end
  end

  def test_resolves_relative_path_with_double_dot
    ace_context_path = File.join(mono_repo_root, "ace-bundle")
    Dir.chdir(ace_context_path) do
      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

      result = resolver.resolve("../ace-support-nav")
      assert result, "Should resolve ../ace-support-nav"
      assert result.end_with?("ace-support-nav")
    end
  end

  def test_returns_nil_for_nonexistent_absolute_path
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve("/nonexistent/path/to/package")
    assert_nil result, "Should return nil for nonexistent path"
  end

  # Test package validation (test directory requirement)

  def test_returns_nil_for_package_without_test_dir
    Dir.mktmpdir do |tmpdir|
      # Create a package without test directory
      package_dir = File.join(tmpdir, "ace-no-tests")
      FileUtils.mkdir_p(package_dir)

      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: tmpdir)

      result = resolver.resolve("ace-no-tests")
      assert_nil result, "Should return nil for package without test directory"
    end
  end

  def test_resolves_package_with_test_dir
    Dir.mktmpdir do |tmpdir|
      # Create a package with test directory
      package_dir = File.join(tmpdir, "ace-with-tests")
      FileUtils.mkdir_p(File.join(package_dir, "test"))

      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: tmpdir)

      result = resolver.resolve("ace-with-tests")
      assert result, "Should resolve package with test directory"
    end
  end

  # Test available_packages method

  def test_available_packages_returns_list
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    packages = resolver.available_packages
    assert packages.is_a?(Array)
    assert packages.include?("ace-bundle"), "Should include ace-bundle"
    assert packages.include?("ace-support-nav"), "Should include ace-support-nav"
    assert packages.include?("ace-test-runner"), "Should include ace-test-runner"
  end

  def test_suite_config_includes_all_testable_packages
    suite_path = File.join(mono_repo_root, ".ace", "test", "suite.yml")
    suite_config = YAML.load_file(suite_path)
    configured = suite_config["test_suite"]["packages"].map { |pkg| pkg["name"] }

    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)
    available = resolver.available_packages

    missing = available - configured
    assert_equal [], missing, "Suite config is missing packages: #{missing.join(", ")}"
  end

  def test_available_packages_only_includes_packages_with_tests
    Dir.mktmpdir do |tmpdir|
      # Create packages with and without tests
      FileUtils.mkdir_p(File.join(tmpdir, "ace-with-tests", "test"))
      FileUtils.mkdir_p(File.join(tmpdir, "ace-without-tests"))

      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: tmpdir)

      packages = resolver.available_packages
      assert packages.include?("ace-with-tests")
      refute packages.include?("ace-without-tests")
    end
  end

  def test_available_packages_returns_empty_when_no_root
    # When initialized with explicit nil, fallback finder may still find root
    # We test this by using a non-existent path that won't have ace-* packages
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        # Override the finder to return nil by setting an empty project root
        resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: tmpdir)
        packages = resolver.available_packages
        assert_equal [], packages, "Should return empty array when no ace-* packages exist"
      end
    end
  end

  def test_available_packages_sorted
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    packages = resolver.available_packages
    assert_equal packages.sort, packages, "Packages should be sorted"
  end

  # Edge cases

  def test_resolve_with_nil_input
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve(nil)
    assert_nil result
  end

  def test_resolve_with_empty_string
    resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

    result = resolver.resolve("")
    assert_nil result
  end

  def test_resolve_current_directory_dot
    Dir.chdir(File.join(mono_repo_root, "ace-bundle")) do
      resolver = Ace::TestRunner::Molecules::PackageResolver.new(project_root: mono_repo_root)

      result = resolver.resolve(".")
      assert result, "Should resolve current directory with '.'"
      assert result.end_with?("ace-bundle")
    end
  end

  private

  def mono_repo_root
    # Navigate up from test file to find the mono-repo root
    @mono_repo_root ||= begin
      current = File.expand_path("../..", __dir__)
      loop do
        gemfile = File.join(current, "Gemfile")
        if File.exist?(gemfile) && Dir.glob(File.join(current, "ace-*")).size > 5
          break current
        end
        parent = File.dirname(current)
        raise "Could not find mono-repo root" if parent == current

        current = parent
      end
    end
  end
end
