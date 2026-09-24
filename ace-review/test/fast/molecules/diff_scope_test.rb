# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/diff_scope"

class DiffScopeTest < AceReviewTest
  DIFF = <<~DIFF
    diff --git a/apps/web/view.ts b/apps/web/view.ts
    --- a/apps/web/view.ts
    +++ b/apps/web/view.ts
    @@ -1 +1 @@
    -old
    +new
    diff --git a/.ace-tasks/task.md b/.ace-tasks/task.md
    --- a/.ace-tasks/task.md
    +++ b/.ace-tasks/task.md
    @@ -1 +1 @@
    -old
    +new
  DIFF

  def test_filters_raw_diff_and_accounts_for_excluded_files
    result = Ace::Review::Molecules::DiffScope.select(DIFF,
      {"include" => ["apps/web/**"], "exclude" => []})

    assert result[:success]
    assert_equal ["apps/web/view.ts"], result[:manifest][:selected_files]
    assert_equal [".ace-tasks/task.md"], result[:manifest][:excluded_files]
    assert result[:manifest][:received_diff_accounted_for]
    refute result[:manifest].key?(:complete)
    assert_includes result[:diff], "apps/web/view.ts"
    refute_includes result[:diff], ".ace-tasks/task.md"
  end

  def test_trailing_recursive_glob_selects_deep_files
    diff = "diff --git a/apps/admin/ui/deep/view.tsx b/apps/admin/ui/deep/view.tsx\n" \
      "--- a/apps/admin/ui/deep/view.tsx\n+++ b/apps/admin/ui/deep/view.tsx\n"
    selected = Ace::Review::Molecules::DiffScope.select(diff,
      {"include" => ["apps/admin/**"]})
    assert selected[:success], selected[:error]
    assert_equal ["apps/admin/ui/deep/view.tsx"], selected[:manifest][:selected_files]
    excluded = Ace::Review::Molecules::DiffScope.select(diff,
      {"include" => ["**/*.tsx"], "exclude" => ["apps/admin/**"]})
    refute excluded[:success]
  end

  def test_module_and_functional_groups_intersect_on_the_same_path
    diff = <<~DIFF
      diff --git a/apps/admin/view.tsx b/apps/admin/view.tsx
      --- a/apps/admin/view.tsx
      +++ b/apps/admin/view.tsx
      @@ -1 +1 @@
      -old
      +new
      diff --git a/apps/admin/view.test.tsx b/apps/admin/view.test.tsx
      --- a/apps/admin/view.test.tsx
      +++ b/apps/admin/view.test.tsx
      @@ -1 +1 @@
      -old
      +new
      diff --git a/apps/web/view.tsx b/apps/web/view.tsx
      --- a/apps/web/view.tsx
      +++ b/apps/web/view.tsx
      @@ -1 +1 @@
      -old
      +new
    DIFF

    result = Ace::Review::Molecules::DiffScope.select(diff, nil,
      groups: [{"include" => ["apps/admin/**"]},
        {"include" => ["**/*.tsx"], "exclude" => ["**/*.test.tsx"]}])

    assert result[:success]
    assert_equal ["apps/admin/view.tsx"], result[:manifest][:selected_files]
    assert_equal ["apps/admin/view.test.tsx", "apps/web/view.tsx"], result[:manifest][:excluded_files]
    assert_equal 2, result[:manifest][:file_pattern_groups].size
  end

  def test_rejects_malformed_pattern_groups
    refute Ace::Review::Molecules::DiffScope.select(DIFF, nil, groups: "apps/admin/**")[:success]
    refute Ace::Review::Molecules::DiffScope.select(DIFF, nil, groups: [{"include" => "apps/admin/**"}])[:success]
  end

  def test_records_binary_only_blocks_in_full_manifest
    diff = DIFF + "diff --git a/assets/photo.png b/assets/photo.png\n" \
      "index 1111111..2222222 100644\nBinary files a/assets/photo.png and b/assets/photo.png differ\n"
    result = Ace::Review::Molecules::DiffScope.select(diff, {"include" => ["apps/web/**"]})
    assert result[:success]
    assert_equal ["assets/photo.png"], result[:manifest][:binary_files]
    assert_equal ["assets/photo.png", ".ace-tasks/task.md"].sort, result[:manifest][:excluded_files].sort
  end

  def test_rename_exclusion_takes_precedence_over_old_path_inclusion
    diff = "diff --git a/apps/admin/old.rb b/.ace-local/new.rb\n" \
      "similarity index 99%\nrename from apps/admin/old.rb\nrename to .ace-local/new.rb\n" \
      "diff --git a/apps/admin/keep.rb b/apps/admin/keep.rb\n--- a/apps/admin/keep.rb\n+++ b/apps/admin/keep.rb\n"
    result = Ace::Review::Molecules::DiffScope.select(diff,
      {"include" => ["apps/admin/**"], "exclude" => [".ace-local/**"]})

    assert result[:success]
    assert_equal ["apps/admin/keep.rb"], result[:manifest][:selected_files]
    assert_equal [".ace-local/new.rb"], result[:manifest][:excluded_files]
  end

  def test_rejects_unparsed_or_empty_scope
    refute Ace::Review::Molecules::DiffScope.select("preface\n#{DIFF}")[:success]
    refute Ace::Review::Molecules::DiffScope.select(DIFF,
      {"include" => ["apps/admin/**"]})[:success]
    refute Ace::Review::Molecules::DiffScope.select(DIFF,
      {"exclude" => "**/*.md"})[:success]
  end

  def test_rename_is_selected_when_either_side_belongs_to_scope
    diff = "diff --git a/apps/admin/old.rb b/apps/web/new.rb\n" \
      "similarity index 99%\nrename from apps/admin/old.rb\nrename to apps/web/new.rb\n"
    result = Ace::Review::Molecules::DiffScope.select(diff,
      {"include" => ["apps/admin/**"]})

    assert result[:success]
    assert_equal [{from: "apps/admin/old.rb", to: "apps/web/new.rb"}], result[:manifest][:renames]
  end
end
