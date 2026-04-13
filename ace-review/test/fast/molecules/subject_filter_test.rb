# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Molecules
      class SubjectFilterTest < AceReviewTest
        def setup
          super
          @patterns_with_include_and_exclude = {
            "include" => ["lib/**/*.rb", "src/**/*.ts"],
            "exclude" => ["**/*_test.rb", "**/*.spec.ts"]
          }
          @patterns_with_only_include = {
            "include" => ["lib/**/*.rb"],
            "exclude" => []
          }
          @patterns_with_only_exclude = {
            "include" => [],
            "exclude" => ["**/*_test.rb"]
          }
        end

        # has_patterns? tests

        def test_has_patterns_with_include
          assert SubjectFilter.has_patterns?(@patterns_with_only_include)
        end

        def test_has_patterns_with_exclude
          assert SubjectFilter.has_patterns?(@patterns_with_only_exclude)
        end

        def test_has_patterns_with_both
          assert SubjectFilter.has_patterns?(@patterns_with_include_and_exclude)
        end

        def test_has_patterns_without_patterns
          refute SubjectFilter.has_patterns?(nil)
        end

        def test_has_patterns_with_empty_hash
          refute SubjectFilter.has_patterns?({})
        end

        def test_has_patterns_with_empty_arrays
          refute SubjectFilter.has_patterns?({"include" => [], "exclude" => []})
        end

        def test_has_patterns_with_non_hash
          refute SubjectFilter.has_patterns?("not a hash")
          refute SubjectFilter.has_patterns?([])
        end

        # matches_file? tests

        def test_matches_file_with_include_pattern
          assert SubjectFilter.matches_file?("lib/models/user.rb", @patterns_with_include_and_exclude)
          assert SubjectFilter.matches_file?("src/components/Button.ts", @patterns_with_include_and_exclude)
        end

        def test_matches_file_not_matching_include
          refute SubjectFilter.matches_file?("app/models/user.rb", @patterns_with_include_and_exclude)
        end

        def test_matches_file_with_exclude_pattern
          refute SubjectFilter.matches_file?("lib/models/user_test.rb", @patterns_with_include_and_exclude)
          refute SubjectFilter.matches_file?("src/components/Button.spec.ts", @patterns_with_include_and_exclude)
        end

        def test_matches_file_without_patterns
          assert SubjectFilter.matches_file?("any/path/file.rb", nil)
        end

        def test_matches_file_with_only_exclude
          assert SubjectFilter.matches_file?("lib/models/user.rb", @patterns_with_only_exclude)
          refute SubjectFilter.matches_file?("lib/models/user_test.rb", @patterns_with_only_exclude)
        end

        def test_matches_file_with_only_include
          assert SubjectFilter.matches_file?("lib/models/user.rb", @patterns_with_only_include)
          refute SubjectFilter.matches_file?("app/models/user.rb", @patterns_with_only_include)
        end

        def test_matches_file_with_nested_paths
          assert SubjectFilter.matches_file?("lib/ace/review/models/reviewer.rb", @patterns_with_only_include)
        end

        # filter tests (dispatch)

        def test_filter_dispatches_string_to_filter_diff
          diff_content = <<~DIFF
            diff --git a/lib/models/user.rb b/lib/models/user.rb
            +# some change
          DIFF

          result = SubjectFilter.filter(diff_content, @patterns_with_only_include)

          assert_includes result, "lib/models/user.rb"
        end

        def test_filter_dispatches_hash_to_filter_hash
          subject = {"files" => ["lib/models/user.rb", "app/models/post.rb"]}

          result = SubjectFilter.filter(subject, @patterns_with_only_include)

          assert_equal ["lib/models/user.rb"], result["files"]
        end

        def test_filter_returns_unchanged_when_no_patterns
          subject = "unchanged content"

          result = SubjectFilter.filter(subject, nil)

          assert_equal subject, result
        end

        def test_filter_returns_unchanged_for_unknown_types
          subject = 123

          result = SubjectFilter.filter(subject, @patterns_with_only_include)

          assert_equal subject, result
        end

        # filter_diff tests

        def test_filter_diff_with_matching_files
          diff_content = <<~DIFF
            diff --git a/lib/models/user.rb b/lib/models/user.rb
            index abc123..def456 100644
            --- a/lib/models/user.rb
            +++ b/lib/models/user.rb
            @@ -1,3 +1,4 @@
            +# New line
             class User
             end
          DIFF

          result = SubjectFilter.filter_diff(diff_content, @patterns_with_only_include)

          assert_includes result, "lib/models/user.rb"
        end

        def test_filter_diff_excludes_non_matching_files
          diff_content = <<~DIFF
            diff --git a/lib/models/user.rb b/lib/models/user.rb
            index abc123..def456 100644
            --- a/lib/models/user.rb
            +++ b/lib/models/user.rb
            @@ -1,3 +1,4 @@
            +# New line
             class User
             end
            diff --git a/app/models/post.rb b/app/models/post.rb
            index 111111..222222 100644
            --- a/app/models/post.rb
            +++ b/app/models/post.rb
            @@ -1,2 +1,3 @@
            +# Another line
             class Post
             end
          DIFF

          result = SubjectFilter.filter_diff(diff_content, @patterns_with_only_include)

          assert_includes result, "lib/models/user.rb"
          refute_includes result, "app/models/post.rb"
        end

        def test_filter_diff_with_exclude_patterns
          diff_content = <<~DIFF
            diff --git a/lib/models/user.rb b/lib/models/user.rb
            +# implementation
            diff --git a/lib/models/user_test.rb b/lib/models/user_test.rb
            +# test file
          DIFF

          result = SubjectFilter.filter_diff(diff_content, @patterns_with_include_and_exclude)

          assert_includes result, "lib/models/user.rb"
          refute_includes result, "lib/models/user_test.rb"
        end

        def test_filter_diff_returns_unchanged_without_patterns
          diff_content = "unchanged diff"

          result = SubjectFilter.filter_diff(diff_content, nil)

          assert_equal diff_content, result
        end

        # filter_hash tests

        def test_filter_hash_filters_files_array
          subject = {
            "files" => [
              "lib/models/user.rb",
              "lib/models/user_test.rb",
              "src/Button.ts"
            ]
          }

          result = SubjectFilter.filter_hash(subject, @patterns_with_include_and_exclude)

          assert_equal 2, result["files"].length
          assert_includes result["files"], "lib/models/user.rb"
          assert_includes result["files"], "src/Button.ts"
          refute_includes result["files"], "lib/models/user_test.rb"
        end

        def test_filter_hash_handles_bundle_sections
          subject = {
            "bundle" => {
              "sections" => {
                "source_files" => {
                  "files" => ["lib/models/user.rb", "lib/models/user_test.rb"]
                },
                "docs" => {
                  "content" => "documentation"
                }
              }
            }
          }

          result = SubjectFilter.filter_hash(subject, @patterns_with_include_and_exclude)

          assert_equal ["lib/models/user.rb"], result["bundle"]["sections"]["source_files"]["files"]
          assert_equal "documentation", result["bundle"]["sections"]["docs"]["content"]
        end

        def test_filter_hash_removes_empty_sections
          subject = {
            "bundle" => {
              "sections" => {
                "tests_only" => {
                  "files" => ["lib/models/user_test.rb", "test/other_test.rb"]
                }
              }
            }
          }

          result = SubjectFilter.filter_hash(subject, @patterns_with_include_and_exclude)

          refute result["bundle"]["sections"].key?("tests_only")
        end

        def test_filter_hash_normalizes_symbol_keys
          subject = {
            files: ["lib/models/user.rb", "app/other.rb"]
          }

          result = SubjectFilter.filter_hash(subject, @patterns_with_only_include)

          assert_equal ["lib/models/user.rb"], result["files"]
        end

        def test_filter_hash_returns_unchanged_without_patterns
          subject = {"files" => ["any.rb"]}

          result = SubjectFilter.filter_hash(subject, nil)

          assert_equal subject, result
        end

        # filter_bundle_sections tests

        def test_filter_bundle_sections_filters_files
          sections = {
            "code" => {"files" => ["lib/user.rb", "lib/user_test.rb"]},
            "config" => {"files" => ["config.yml"]}
          }

          result = SubjectFilter.filter_bundle_sections(sections, @patterns_with_include_and_exclude)

          assert_equal ["lib/user.rb"], result["code"]["files"]
          refute result.key?("config")  # config.yml doesn't match include patterns
        end

        def test_filter_bundle_sections_keeps_non_file_sections
          sections = {
            "metadata" => {"title" => "Review"}
          }

          result = SubjectFilter.filter_bundle_sections(sections, @patterns_with_only_include)

          assert_equal({"title" => "Review"}, result["metadata"])
        end

        def test_filter_bundle_sections_normalizes_section_keys
          sections = {
            "code" => {files: ["lib/user.rb"]}
          }

          result = SubjectFilter.filter_bundle_sections(sections, @patterns_with_only_include)

          assert_equal ["lib/user.rb"], result["code"]["files"]
        end
      end
    end
  end
end
