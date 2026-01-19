# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::GroupResolverTest < Minitest::Test
  def test_resolve_with_default_groups
    resolver = Ace::Lint::Molecules::GroupResolver.new

    result = resolver.resolve("test.rb")

    assert_equal :default, result[:group_name]
    assert_includes result[:validators], :standardrb
    assert_includes result[:fallback_validators], :rubocop
  end

  def test_resolve_matches_most_specific_group
    groups = {
      strict: {patterns: ["lib/**/*.rb"], validators: [:standardrb, :rubocop]},
      default: {patterns: ["**/*.rb"], validators: [:standardrb]}
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    result = resolver.resolve("lib/ace/lint.rb")

    assert_equal :strict, result[:group_name]
    assert_equal [:standardrb, :rubocop], result[:validators]
  end

  def test_resolve_falls_back_to_default
    groups = {
      lib: {patterns: ["lib/**/*.rb"], validators: [:standardrb]},
      default: {patterns: ["**/*.rb"], validators: [:rubocop]}
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    result = resolver.resolve("app/model.rb")

    assert_equal :default, result[:group_name]
    assert_equal [:rubocop], result[:validators]
  end

  def test_resolve_returns_nil_when_no_match
    groups = {
      lib: {patterns: ["lib/**/*.rb"], validators: [:standardrb]}
      # No default group
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    result = resolver.resolve("app/model.rb")

    assert_nil result
  end

  def test_resolve_batch_groups_files_correctly
    groups = {
      lib: {patterns: ["lib/**/*.rb"], validators: [:standardrb, :rubocop]},
      tests: {patterns: ["test/**/*.rb"], validators: [:rubocop]},
      default: {patterns: ["**/*.rb"], validators: [:standardrb]}
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    files = [
      "lib/ace/lint.rb",
      "lib/ace/core.rb",
      "test/test_helper.rb",
      "scripts/run.rb"
    ]

    result = resolver.resolve_batch(files)

    assert_equal 3, result.keys.size
    assert_equal ["lib/ace/lint.rb", "lib/ace/core.rb"], result[:lib][:files]
    assert_equal ["test/test_helper.rb"], result[:tests][:files]
    assert_equal ["scripts/run.rb"], result[:default][:files]
  end

  def test_resolve_batch_handles_unmatched_files
    groups = {
      lib: {patterns: ["lib/**/*.rb"], validators: [:standardrb]}
      # No default group
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    files = ["lib/test.rb", "app/model.rb"]
    result = resolver.resolve_batch(files)

    assert_includes result.keys, :_unmatched_
    assert_equal ["app/model.rb"], result[:_unmatched_][:files]
  end

  def test_normalize_handles_string_keys
    groups = {
      "strict" => {
        "patterns" => ["lib/**/*.rb"],
        "validators" => ["standardrb", "rubocop"]
      }
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    result = resolver.resolve("lib/test.rb")

    assert_equal :strict, result[:group_name]
    assert_equal [:standardrb, :rubocop], result[:validators]
  end

  def test_normalize_handles_single_validator_as_string
    groups = {
      default: {
        patterns: ["**/*.rb"],
        validators: "standardrb"  # Single string instead of array
      }
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    result = resolver.resolve("test.rb")

    assert_equal [:standardrb], result[:validators]
  end

  def test_groups_accessor_returns_normalized_groups
    groups = {
      "test" => {"patterns" => ["test/**/*.rb"], "validators" => ["rubocop"]}
    }
    resolver = Ace::Lint::Molecules::GroupResolver.new(groups)

    assert_equal [:test], resolver.groups.keys
  end
end
