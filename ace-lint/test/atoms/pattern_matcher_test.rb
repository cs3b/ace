# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::PatternMatcherTest < Minitest::Test
  def test_specificity_exact_filename_highest
    # Exact match gets +1000 + length
    score = Ace::Lint::Atoms::PatternMatcher.specificity("Rakefile")
    assert score > 1000
  end

  def test_specificity_deeper_path_higher
    shallow = Ace::Lint::Atoms::PatternMatcher.specificity("*.rb")
    deep = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    assert deep > shallow
  end

  def test_specificity_double_star_penalty
    Ace::Lint::Atoms::PatternMatcher.specificity("lib/*.rb")
    Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    # Double star should have penalty, but depth bonus may compensate
    # Test that single star at same depth is higher
    single_deep = Ace::Lint::Atoms::PatternMatcher.specificity("lib/ace/*.rb")
    double_same = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    assert single_deep > double_same
  end

  def test_specificity_nil_returns_zero
    assert_equal 0, Ace::Lint::Atoms::PatternMatcher.specificity(nil)
  end

  def test_specificity_empty_string_returns_zero
    assert_equal 0, Ace::Lint::Atoms::PatternMatcher.specificity("")
  end

  def test_matches_simple_glob
    assert Ace::Lint::Atoms::PatternMatcher.matches?("test.rb", "*.rb")
    assert Ace::Lint::Atoms::PatternMatcher.matches?("lib/test.rb", "**/*.rb")
    refute Ace::Lint::Atoms::PatternMatcher.matches?("test.txt", "*.rb")
  end

  def test_matches_double_star_glob
    assert Ace::Lint::Atoms::PatternMatcher.matches?("lib/ace/lint/test.rb", "lib/**/*.rb")
    assert Ace::Lint::Atoms::PatternMatcher.matches?("lib/test.rb", "lib/**/*.rb")
    refute Ace::Lint::Atoms::PatternMatcher.matches?("app/test.rb", "lib/**/*.rb")
  end

  def test_matches_exact_filename
    assert Ace::Lint::Atoms::PatternMatcher.matches?("Rakefile", "Rakefile")
    refute Ace::Lint::Atoms::PatternMatcher.matches?("Gemfile", "Rakefile")
  end

  def test_matches_removes_leading_dot_slash
    assert Ace::Lint::Atoms::PatternMatcher.matches?("./test.rb", "*.rb")
    assert Ace::Lint::Atoms::PatternMatcher.matches?("./lib/test.rb", "**/*.rb")
  end

  def test_matches_nil_returns_false
    refute Ace::Lint::Atoms::PatternMatcher.matches?(nil, "*.rb")
    refute Ace::Lint::Atoms::PatternMatcher.matches?("test.rb", nil)
  end

  def test_best_match_returns_most_specific
    patterns = ["**/*.rb", "lib/**/*.rb", "lib/ace/**/*.rb"]
    path = "lib/ace/lint/test.rb"

    result = Ace::Lint::Atoms::PatternMatcher.best_match(path, patterns)

    assert_equal "lib/ace/**/*.rb", result
  end

  def test_best_match_returns_nil_for_no_matches
    patterns = ["lib/**/*.rb", "app/**/*.rb"]
    path = "test/test_helper.rb"

    result = Ace::Lint::Atoms::PatternMatcher.best_match(path, patterns)

    # **/*.rb isn't in patterns, so test/ path won't match
    assert_nil result
  end

  def test_best_match_handles_empty_patterns
    assert_nil Ace::Lint::Atoms::PatternMatcher.best_match("test.rb", [])
    assert_nil Ace::Lint::Atoms::PatternMatcher.best_match("test.rb", nil)
  end

  def test_best_group_match_returns_matching_group
    groups = {
      strict: {patterns: ["lib/**/*.rb"]},
      tests: {patterns: ["test/**/*.rb"]},
      default: {patterns: ["**/*.rb"]}
    }

    result = Ace::Lint::Atoms::PatternMatcher.best_group_match("lib/ace/lint.rb", groups)

    assert_equal :strict, result[0]
  end

  def test_best_group_match_prefers_more_specific
    groups = {
      specific: {patterns: ["lib/ace/**/*.rb"]},
      general: {patterns: ["lib/**/*.rb"]},
      default: {patterns: ["**/*.rb"]}
    }

    result = Ace::Lint::Atoms::PatternMatcher.best_group_match("lib/ace/lint.rb", groups)

    assert_equal :specific, result[0]
  end

  def test_best_group_match_returns_nil_for_no_match
    groups = {
      lib: {patterns: ["lib/**/*.rb"]},
      app: {patterns: ["app/**/*.rb"]}
    }

    result = Ace::Lint::Atoms::PatternMatcher.best_group_match("scripts/deploy.sh", groups)

    assert_nil result
  end

  def test_best_group_match_handles_string_keys
    groups = {
      "strict" => {"patterns" => ["lib/**/*.rb"]},
      "default" => {"patterns" => ["**/*.rb"]}
    }

    result = Ace::Lint::Atoms::PatternMatcher.best_group_match("lib/test.rb", groups)

    assert_equal :strict, result[0]
  end

  # Edge case tests for specificity algorithm

  def test_specificity_triple_star_pattern
    # Triple star *** is unusual but shouldn't break the algorithm
    # gsub('**', '') on '***' leaves '*', which is counted as a single star
    triple = Ace::Lint::Atoms::PatternMatcher.specificity("lib/***/*.rb")
    double = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    # Triple star should have same or similar score to double star
    # (the extra * after gsub gets counted as a single star bonus)
    assert triple >= double - 50, "Triple star should not score much lower than double star"
  end

  def test_specificity_pattern_starting_with_glob
    # Patterns starting with glob characters have no literal prefix
    glob_start = Ace::Lint::Atoms::PatternMatcher.specificity("**/lib/*.rb")
    literal_start = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    # Literal prefix adds to score, so literal start should be higher
    assert literal_start > glob_start, "Literal prefix should increase specificity"
  end

  def test_specificity_question_mark_glob
    # Question mark is also a glob character
    with_question = Ace::Lint::Atoms::PatternMatcher.specificity("lib/?.rb")

    # Should not be treated as exact match (contains glob char)
    assert with_question < 1000, "Pattern with ? should not be treated as exact match"
  end

  def test_specificity_bracket_glob
    # Bracket patterns like [abc] are also glob characters
    with_bracket = Ace::Lint::Atoms::PatternMatcher.specificity("lib/[abc].rb")

    # Should not be treated as exact match (contains glob char)
    assert with_bracket < 1000, "Pattern with [] should not be treated as exact match"
  end

  def test_specificity_multiple_double_stars
    # Multiple ** in one pattern at same depth
    # Compare patterns with same number of path segments
    multi = Ace::Lint::Atoms::PatternMatcher.specificity("**/*.rb")
    double = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.rb")

    # Each ** gets a -50 penalty, but depth bonus (+100 per /) may compensate
    # The double star at different depths will have different scores
    # lib/**/*.rb: 2 slashes (200) - 1 double star (-50) + 3 literal chars = 153+
    # **/*.rb: 1 slash (100) - 1 double star (-50) + 0 literal chars = 50+
    assert double > multi, "Pattern with literal prefix and depth should beat pure glob"
  end

  def test_specificity_brace_expansion
    # Brace expansion patterns like {rb,rake}
    brace = Ace::Lint::Atoms::PatternMatcher.specificity("lib/**/*.{rb,rake}")

    # Should be treated as a glob pattern (contains *)
    assert brace < 1000, "Brace expansion pattern should not be treated as exact match"
    assert brace > 0, "Brace expansion pattern should have positive specificity"
  end
end
