# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/molecules/pattern_resolver"
require "ace/test_runner/models/test_configuration"

class PatternResolverTest < Minitest::Test
  def setup
    @config = Ace::TestRunner::Models::TestConfiguration.new(
      patterns: {
        atoms: "test/{fast/,}atoms/**/*_test.rb",
        molecules: "test/{fast/,}molecules/**/*_test.rb",
        organisms: "test/{fast/,}organisms/**/*_test.rb",
        models: "test/{fast/,}models/**/*_test.rb",
        feat_tests: "test/{feat,integration}/**/*_test.rb"
      },
      groups: {
        fast: %w[atoms molecules organisms models],
        feat: %w[feat_tests],
        unit: %w[fast],
        integration: %w[feat],
        int: %w[feat],
        quick: %w[atoms molecules]
      }
    )
    @resolver = Ace::TestRunner::Molecules::PatternResolver.new(@config)
  end

  def test_resolve_target_with_known_pattern
    # Mock Dir.glob to return test files
    Dir.stub :glob, ["test/fast/atoms/foo_test.rb", "test/fast/atoms/bar_test.rb"] do
      File.stub :file?, true do
        files = @resolver.resolve_target("atoms")
        assert_equal 2, files.size
        assert_includes files, "test/fast/atoms/foo_test.rb"
      end
    end
  end

  def test_resolve_target_with_known_group
    # Mock Dir.glob for multiple patterns
    glob_returns = {
      "test/{fast/,}atoms/**/*_test.rb" => ["test/fast/atoms/foo_test.rb"],
      "test/{fast/,}molecules/**/*_test.rb" => ["test/fast/molecules/bar_test.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = @resolver.resolve_target("quick")
        assert_equal 2, files.size
        assert_includes files, "test/fast/atoms/foo_test.rb"
        assert_includes files, "test/fast/molecules/bar_test.rb"
      end
    end
  end

  def test_resolve_target_with_existing_file
    File.stub :exist?, true do
      files = @resolver.resolve_target("test/some_test.rb")
      assert_equal ["test/some_test.rb"], files
    end
  end

  def test_resolve_target_with_unknown_target
    error = assert_raises(ArgumentError) do
      @resolver.resolve_target("unknown")
    end
    assert_match(/Unknown target: unknown/, error.message)
    assert_match(/Available targets:/, error.message)
  end

  def test_resolve_target_with_nonexistent_file_path_with_slash
    File.stub :exist?, false do
      error = assert_raises(ArgumentError) do
        @resolver.resolve_target("test/nonexistent_test.rb")
      end
      assert_match(/File not found: test\/nonexistent_test\.rb/, error.message)
      assert_match(/Make sure you're running from the correct directory/, error.message)
    end
  end

  def test_resolve_target_with_nonexistent_rb_file
    File.stub :exist?, false do
      error = assert_raises(ArgumentError) do
        @resolver.resolve_target("nonexistent_test.rb")
      end
      assert_match(/File not found: nonexistent_test\.rb/, error.message)
    end
  end

  def test_resolve_target_with_deep_nonexistent_path
    File.stub :exist?, false do
      error = assert_raises(ArgumentError) do
        @resolver.resolve_target("foo/bar/baz/test.rb")
      end
      assert_match(/File not found: foo\/bar\/baz\/test\.rb/, error.message)
    end
  end

  def test_resolve_target_with_all
    Dir.stub :glob, ["test/foo_test.rb", "test/bar_test.rb"] do
      File.stub :file?, true do
        files = @resolver.resolve_target("all")
        assert files.size > 0
      end
    end
  end

  def test_resolve_target_defaults_to_fast_when_nil
    glob_returns = {
      "test/{fast/,}atoms/**/*_test.rb" => ["test/fast/atoms/foo_test.rb"],
      "test/{fast/,}molecules/**/*_test.rb" => ["test/fast/molecules/bar_test.rb"],
      "test/{fast/,}organisms/**/*_test.rb" => [],
      "test/{fast/,}models/**/*_test.rb" => []
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = @resolver.resolve_target(nil)
        assert_equal 2, files.size
        assert_includes files, "test/fast/atoms/foo_test.rb"
        assert_includes files, "test/fast/molecules/bar_test.rb"
      end
    end
  end

  def test_rejects_e2e_target_with_guidance
    error = assert_raises(ArgumentError) do
      @resolver.resolve_target("e2e")
    end

    assert_equal "Unsupported target: e2e. Use `ace-test-e2e <package>`.", error.message
  end

  def test_rejects_removed_legacy_targets
    %w[system all-with-e2e].each do |target|
      error = assert_raises(ArgumentError) do
        @resolver.resolve_target(target)
      end

      assert_match(/Unsupported target: #{Regexp.escape(target)}/, error.message)
    end
  end

  def test_resolve_multiple_targets
    glob_returns = {
      "test/{fast/,}atoms/**/*_test.rb" => ["test/fast/atoms/foo_test.rb"],
      "test/{fast/,}molecules/**/*_test.rb" => ["test/fast/molecules/bar_test.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = @resolver.resolve_multiple_targets(["atoms", "molecules"])
        assert_equal 2, files.size
        assert_includes files, "test/fast/atoms/foo_test.rb"
        assert_includes files, "test/fast/molecules/bar_test.rb"
      end
    end
  end

  def test_available_targets
    targets = @resolver.available_targets
    assert_includes targets, "atoms"
    assert_includes targets, "molecules"
    assert_includes targets, "fast"
    assert_includes targets, "feat"
    assert_includes targets, "quick"
  end

  def test_classify_file
    assert_equal "atoms", @resolver.classify_file("test/fast/atoms/foo_test.rb")
    assert_equal "molecules", @resolver.classify_file("test/fast/molecules/bar_test.rb")
    assert_equal "feat", @resolver.classify_file("test/feat/cli_contract_test.rb")
    assert_equal "other", @resolver.classify_file("test/some_other_test.rb")
  end

  def test_recursive_group_expansion
    config = Ace::TestRunner::Models::TestConfiguration.new(
      patterns: {
        atoms: "test/{fast/,}atoms/**/*_test.rb",
        molecules: "test/{fast/,}molecules/**/*_test.rb"
      },
      groups: {
        quick: %w[atoms],
        fast: %w[quick molecules],
        all: %w[fast]
      }
    )
    resolver = Ace::TestRunner::Molecules::PatternResolver.new(config)

    glob_returns = {
      "test/{fast/,}atoms/**/*_test.rb" => ["test/atoms.rb"],
      "test/{fast/,}molecules/**/*_test.rb" => ["test/molecules.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = resolver.resolve_target("all")
        assert_equal 2, files.size
        assert_includes files, "test/atoms.rb"
        assert_includes files, "test/molecules.rb"
      end
    end
  end

  def test_normalizes_legacy_targets_to_new_groups
    glob_returns = {
      "test/{feat,integration}/**/*_test.rb" => ["test/feat/cli_contract_test.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        assert_equal ["test/feat/cli_contract_test.rb"], @resolver.resolve_target("integration")
        assert_equal ["test/feat/cli_contract_test.rb"], @resolver.resolve_target("int")
      end
    end
  end
end
