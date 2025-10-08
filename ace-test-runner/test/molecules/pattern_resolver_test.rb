# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/molecules/pattern_resolver"
require "ace/test_runner/models/test_configuration"

class PatternResolverTest < Minitest::Test
  def setup
    @config = Ace::TestRunner::Models::TestConfiguration.new(
      patterns: {
        atoms: "test/unit/atoms/**/*_test.rb",
        molecules: "test/unit/molecules/**/*_test.rb",
        organisms: "test/unit/organisms/**/*_test.rb",
        models: "test/unit/models/**/*_test.rb"
      },
      groups: {
        unit: %w[atoms molecules organisms models],
        quick: %w[atoms molecules]
      }
    )
    @resolver = Ace::TestRunner::Molecules::PatternResolver.new(@config)
  end

  def test_resolve_target_with_known_pattern
    # Mock Dir.glob to return test files
    Dir.stub :glob, ["test/unit/atoms/foo_test.rb", "test/unit/atoms/bar_test.rb"] do
      File.stub :file?, true do
        files = @resolver.resolve_target("atoms")
        assert_equal 2, files.size
        assert_includes files, "test/unit/atoms/foo_test.rb"
      end
    end
  end

  def test_resolve_target_with_known_group
    # Mock Dir.glob for multiple patterns
    glob_returns = {
      "test/unit/atoms/**/*_test.rb" => ["test/unit/atoms/foo_test.rb"],
      "test/unit/molecules/**/*_test.rb" => ["test/unit/molecules/bar_test.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = @resolver.resolve_target("quick")
        assert_equal 2, files.size
        assert_includes files, "test/unit/atoms/foo_test.rb"
        assert_includes files, "test/unit/molecules/bar_test.rb"
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
    assert_raises(ArgumentError) do
      @resolver.resolve_target("unknown")
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

  def test_resolve_multiple_targets
    glob_returns = {
      "test/unit/atoms/**/*_test.rb" => ["test/unit/atoms/foo_test.rb"],
      "test/unit/molecules/**/*_test.rb" => ["test/unit/molecules/bar_test.rb"]
    }

    Dir.stub :glob, ->(pattern) { glob_returns[pattern] || [] } do
      File.stub :file?, true do
        files = @resolver.resolve_multiple_targets(["atoms", "molecules"])
        assert_equal 2, files.size
        assert_includes files, "test/unit/atoms/foo_test.rb"
        assert_includes files, "test/unit/molecules/bar_test.rb"
      end
    end
  end

  def test_available_targets
    targets = @resolver.available_targets
    assert_includes targets, "atoms"
    assert_includes targets, "molecules"
    assert_includes targets, "unit"
    assert_includes targets, "quick"
  end

  def test_classify_file
    assert_equal "atoms", @resolver.classify_file("test/unit/atoms/foo_test.rb")
    assert_equal "molecules", @resolver.classify_file("test/unit/molecules/bar_test.rb")
    assert_equal "other", @resolver.classify_file("test/some_other_test.rb")
  end

  def test_recursive_group_expansion
    config = Ace::TestRunner::Models::TestConfiguration.new(
      patterns: {
        atoms: "test/unit/atoms/**/*_test.rb",
        molecules: "test/unit/molecules/**/*_test.rb"
      },
      groups: {
        quick: %w[atoms],
        unit: %w[quick molecules],
        all: %w[unit]
      }
    )
    resolver = Ace::TestRunner::Molecules::PatternResolver.new(config)

    glob_returns = {
      "test/unit/atoms/**/*_test.rb" => ["test/atoms.rb"],
      "test/unit/molecules/**/*_test.rb" => ["test/molecules.rb"]
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
end