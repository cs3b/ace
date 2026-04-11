# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Atoms
        class PathRuleMatcherTest < TestCase
          def test_matches_simple_glob
            matcher = PathRuleMatcher.new({
              "docs" => {"glob" => "docs/**", "model" => "gflash"}
            })

            result = matcher.match("docs/readme.md")

            assert result
            assert_equal "docs", result.name
            assert_equal({"model" => "gflash"}, result.config)
          end

          def test_matches_dot_paths_with_dotmatch
            matcher = PathRuleMatcher.new({
              "taskflow" => {"glob" => ".ace-task/**", "format" => "simple"}
            })

            result = matcher.match(".ace-task/v1/task.md")

            assert result
            assert_equal "taskflow", result.name
            assert_equal({"format" => "simple"}, result.config)
          end

          def test_supports_extglob_patterns
            matcher = PathRuleMatcher.new({
              "packages" => {"glob" => "ace-{docs,handbook}/**", "model" => "gflash"}
            })

            result = matcher.match("ace-docs/README.md")

            assert result
            assert_equal "packages", result.name
          end

          def test_matches_glob_array_with_single_entry
            matcher = PathRuleMatcher.new({
              "packages" => {"glob" => ["ace-*/**"], "type" => "chore"}
            })

            result = matcher.match("ace-bundle/README.md")

            assert result
            assert_equal "packages", result.name
            assert_equal({"type" => "chore"}, result.config)
          end

          def test_matches_glob_array_first_pattern
            matcher = PathRuleMatcher.new({
              "docs" => {"glob" => ["docs/**", "lib/**"], "model" => "gflash"}
            })

            result = matcher.match("docs/readme.md")

            assert result
            assert_equal "docs", result.name
          end

          def test_matches_glob_array_second_pattern
            matcher = PathRuleMatcher.new({
              "library" => {"glob" => ["docs/**", "lib/**"], "model" => "gflash"}
            })

            result = matcher.match("lib/file.rb")

            assert result
            assert_equal "library", result.name
          end

          def test_returns_nil_with_empty_glob_array
            matcher = PathRuleMatcher.new({
              "empty" => {"glob" => [], "model" => "gflash"}
            })

            result = matcher.match("docs/readme.md")

            assert_nil result
          end

          def test_matches_glob_array_with_mixed_values
            matcher = PathRuleMatcher.new({
              "docs" => {"glob" => ["docs/**", nil, 123, ""], "model" => "gflash"}
            })

            result = matcher.match("docs/readme.md")

            assert result
            assert_equal "docs", result.name
          end

          def test_returns_nil_when_no_match
            matcher = PathRuleMatcher.new({
              "docs" => {"glob" => "docs/**", "model" => "gflash"}
            })

            result = matcher.match("lib/file.rb")

            assert_nil result
          end

          # Edge case: overlapping patterns - first match wins
          def test_first_matching_rule_wins_with_overlapping_patterns
            matcher = PathRuleMatcher.new({
              "specific" => {"glob" => "docs/api/**", "model" => "gpro"},
              "general" => {"glob" => "docs/**", "model" => "gflash"}
            })

            result = matcher.match("docs/api/endpoints.md")

            assert_equal "specific", result.name
            assert_equal({"model" => "gpro"}, result.config)
          end

          # Edge case: bracket character class wildcard
          def test_matches_bracket_character_class
            matcher = PathRuleMatcher.new({
              "images" => {"glob" => "assets/*.[jp][pn]g", "type" => "media"}
            })

            result = matcher.match("assets/logo.png")

            assert result
            assert_equal "images", result.name
          end

          # Edge case: question mark single character wildcard
          def test_matches_question_mark_wildcard
            matcher = PathRuleMatcher.new({
              "logs" => {"glob" => "logs/app?.log", "type" => "log"}
            })

            result = matcher.match("logs/app1.log")

            assert result
            assert_equal "logs", result.name
          end

          # Edge case: empty path rules hash
          def test_returns_nil_with_empty_rules
            matcher = PathRuleMatcher.new({})

            result = matcher.match("any/path.rb")

            assert_nil result
          end

          # Edge case: deeply nested paths
          def test_matches_deeply_nested_paths
            matcher = PathRuleMatcher.new({
              "nested" => {"glob" => "a/b/c/d/**", "depth" => "deep"}
            })

            result = matcher.match("a/b/c/d/e/f/g/file.rb")

            assert result
            assert_equal "nested", result.name
            assert_equal({"depth" => "deep"}, result.config)
          end

          # Config root relative path matching tests

          def test_matches_with_config_root_relative_path
            Dir.mktmpdir do |project_root|
              config_root = File.join(project_root, "ace-bundle")
              FileUtils.mkdir_p(config_root)

              matcher = PathRuleMatcher.new(
                {"lib-scope" => {"glob" => "lib/**", "type" => "feat", "_config_root" => config_root}},
                project_root: project_root
              )

              # File path relative to project root: ace-bundle/lib/file.rb
              # Should be converted to lib/file.rb relative to config root
              result = matcher.match("ace-bundle/lib/file.rb")

              assert result
              assert_equal "lib-scope", result.name
              assert_equal({"type" => "feat"}, result.config)
            end
          end

          def test_config_root_excludes_internal_metadata
            Dir.mktmpdir do |project_root|
              matcher = PathRuleMatcher.new(
                {"lib-scope" => {"glob" => "lib/**", "type" => "feat", "_config_root" => project_root}},
                project_root: project_root
              )

              result = matcher.match("lib/file.rb")

              assert result
              # _config_root should not appear in extracted config
              refute result.config.key?("_config_root")
              assert_equal({"type" => "feat"}, result.config)
            end
          end

          def test_rule_without_config_root_uses_project_relative_path
            Dir.mktmpdir do |project_root|
              matcher = PathRuleMatcher.new(
                {"lib-scope" => {"glob" => "lib/**", "type" => "feat"}},
                project_root: project_root
              )

              # Without _config_root, path is matched as-is
              result = matcher.match("lib/file.rb")

              assert result
              assert_equal "lib-scope", result.name
            end
          end

          def test_config_root_same_as_project_root_matches_unchanged
            Dir.mktmpdir do |project_root|
              matcher = PathRuleMatcher.new(
                {"lib-scope" => {"glob" => "lib/**", "type" => "feat", "_config_root" => project_root}},
                project_root: project_root
              )

              result = matcher.match("lib/file.rb")

              assert result
              assert_equal "lib-scope", result.name
            end
          end

          def test_file_outside_config_root_not_adjusted
            Dir.mktmpdir do |project_root|
              config_root = File.join(project_root, "ace-bundle")
              FileUtils.mkdir_p(config_root)

              matcher = PathRuleMatcher.new(
                {"lib-scope" => {"glob" => "lib/**", "type" => "feat", "_config_root" => config_root}},
                project_root: project_root
              )

              # File path that doesn't start with ace-bundle/ prefix
              # Should not match because lib/file.rb != ace-bundle/lib/file.rb
              result = matcher.match("lib/file.rb")

              assert_nil result
            end
          end
        end
      end
    end
  end
end
