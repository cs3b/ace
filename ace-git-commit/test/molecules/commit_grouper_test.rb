# frozen_string_literal: true

require_relative "../test_helper"

class CommitGrouperTest < TestCase
  class FakeResolver
    def initialize(mapping)
      @mapping = mapping
    end

    def resolve(file, namespace:, filename:, project_root: nil)
      @mapping.fetch(file)
    end
  end

  def setup
    @project_root = "/Users/mc/Ps/ace-task.228"
  end

  def test_groups_files_by_config_signature
    config_a = {"model" => "glite"}
    config_b = {"model" => "gflash"}

    group_a = Ace::Support::Config::Models::ConfigGroup.new(
      name: "docs",  # path rule name from root config
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config_a,
      files: []
    )
    group_b = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",  # no path rule match, from distributed config
      source: "#{@project_root}/ace-taskflow/.ace/git/commit.yml",
      config: config_b,
      files: []
    )

    resolver = FakeResolver.new(
      "a.md" => group_a,
      "b.md" => group_a,
      "c.md" => group_b
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["a.md", "b.md", "c.md"], project_root: @project_root)

    assert_equal 2, groups.length
    # Root config with path rule → keeps path rule name "docs"
    assert_equal ["a.md", "b.md"], groups.find { |g| g.scope_name == "docs" }.files
    # Distributed config → derives package name from path
    assert_equal ["c.md"], groups.find { |g| g.scope_name == "ace-taskflow" }.files
  end

  # ===== derive_scope_name tests =====

  def test_derive_scope_name_from_package_config
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/ace-bundle/.ace/git/commit.yml"

    # Distributed config overrides resolved name
    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "ace-bundle", scope
  end

  def test_derive_scope_name_from_git_commit_package
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/ace-git-commit/.ace/git/commit.yml"

    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "ace-git-commit", scope
  end

  def test_derive_scope_name_from_root_config_keeps_resolved_name
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/.ace/git/commit.yml"

    # Root config keeps the resolved name (could be path rule name)
    scope = grouper.derive_scope_name(source, "docs", @project_root)

    assert_equal "docs", scope
  end

  def test_derive_scope_name_from_root_config_project_default
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/.ace/git/commit.yml"

    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "project default", scope
  end

  def test_derive_scope_name_nil_source
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new

    scope = grouper.derive_scope_name(nil, "project default", @project_root)

    assert_equal "project default", scope
  end

  def test_derive_scope_name_nil_project_root
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/ace-bundle/.ace/git/commit.yml"

    # Without project_root, keep resolved name
    scope = grouper.derive_scope_name(source, "project default", nil)

    assert_equal "project default", scope
  end

  def test_derive_scope_name_handles_deeply_nested_package
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/some-package/.ace/git/commit.yml"

    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "some-package", scope
  end

  def test_derive_scope_name_handles_ace_defaults_at_root
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/.ace-defaults/git/commit.yml"

    # .ace-defaults keeps resolved name
    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "project default", scope
  end

  def test_derive_scope_name_handles_ace_defaults_in_package
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    source = "#{@project_root}/ace-git-commit/.ace-defaults/git/commit.yml"

    # .ace-defaults keeps resolved name
    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "project default", scope
  end

  def test_derive_scope_name_handles_compound_source_path
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    # Compound source from FileConfigResolver cascade
    source = "#{@project_root}/ace-git-commit/.ace/git/commit.yml -> #{@project_root}/ace-git-commit/.ace-defaults/git/commit.yml"

    # Should use primary source (before " -> ") to derive package name
    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "ace-git-commit", scope
  end

  def test_derive_scope_name_compound_path_root_config
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    # Root config with cascade
    source = "#{@project_root}/.ace/git/commit.yml -> #{@project_root}/ace-git-commit/.ace-defaults/git/commit.yml"

    # Root config keeps resolved name
    scope = grouper.derive_scope_name(source, "docs", @project_root)

    assert_equal "docs", scope
  end

  def test_derive_scope_name_ace_defaults_only_compound
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    # Only .ace-defaults in compound path (no .ace/)
    source = "#{@project_root}/.ace-defaults/git/commit.yml -> /gem/path/.ace-defaults/git/commit.yml"

    # No .ace/ source, keep resolved name
    scope = grouper.derive_scope_name(source, "project default", @project_root)

    assert_equal "project default", scope
  end

  # ===== ace_config_file? tests =====

  def test_ace_config_file_detects_package_ace_path
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    assert grouper.ace_config_file?("ace-bundle/.ace/git/commit.yml")
  end

  def test_ace_config_file_detects_root_ace_path
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    assert grouper.ace_config_file?(".ace/git/commit.yml")
  end

  def test_ace_config_file_detects_deeply_nested_ace_path
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    assert grouper.ace_config_file?("pkg/sub/.ace/config.yml")
  end

  def test_ace_config_file_rejects_regular_file
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    refute grouper.ace_config_file?("ace-bundle/lib/foo.rb")
  end

  def test_ace_config_file_rejects_ace_defaults
    grouper = Ace::GitCommit::Molecules::CommitGrouper.new
    refute grouper.ace_config_file?(".ace-defaults/git/commit.yml")
    refute grouper.ace_config_file?("ace-bundle/.ace-defaults/git/commit.yml")
  end

  # ===== ace-config grouping integration tests =====

  def test_groups_all_ace_files_into_single_ace_config_scope
    config = {"model" => "glite"}

    group_bundle = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-bundle/.ace/git/commit.yml",
      config: config,
      files: []
    )
    group_docs = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-docs/.ace/git/commit.yml",
      config: config,
      files: []
    )
    group_lint = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-lint/.ace/git/commit.yml",
      config: config,
      files: []
    )

    resolver = FakeResolver.new(
      "ace-bundle/.ace/git/commit.yml" => group_bundle,
      "ace-docs/.ace/git/commit.yml" => group_docs,
      "ace-lint/.ace/git/commit.yml" => group_lint
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(
      ["ace-bundle/.ace/git/commit.yml", "ace-docs/.ace/git/commit.yml", "ace-lint/.ace/git/commit.yml"],
      project_root: @project_root
    )

    assert_equal 1, groups.length
    assert_equal "ace-config", groups.first.scope_name
    assert_equal 3, groups.first.files.length
  end

  def test_groups_root_ace_files_into_ace_config_scope
    config = {"model" => "glite"}

    group = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config,
      files: []
    )

    resolver = FakeResolver.new(".ace/git/commit.yml" => group)

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group([".ace/git/commit.yml"], project_root: @project_root)

    assert_equal 1, groups.length
    assert_equal "ace-config", groups.first.scope_name
  end

  def test_groups_mixed_ace_and_regular_files_separately
    config = {"model" => "glite"}

    ace_group = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-bundle/.ace/git/commit.yml",
      config: config,
      files: []
    )
    regular_group = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-bundle/.ace/git/commit.yml",
      config: config,
      files: []
    )

    resolver = FakeResolver.new(
      "ace-bundle/.ace/git/commit.yml" => ace_group,
      "ace-bundle/lib/foo.rb" => regular_group
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(
      ["ace-bundle/.ace/git/commit.yml", "ace-bundle/lib/foo.rb"],
      project_root: @project_root
    )

    assert_equal 2, groups.length
    ace_config_group = groups.find { |g| g.scope_name == "ace-config" }
    regular_file_group = groups.find { |g| g.scope_name == "ace-bundle" }
    assert_equal ["ace-bundle/.ace/git/commit.yml"], ace_config_group.files
    assert_equal ["ace-bundle/lib/foo.rb"], regular_file_group.files
  end

  def test_no_ace_files_produces_no_ace_config_group
    config = {"model" => "glite"}

    group = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/ace-bundle/.ace/git/commit.yml",
      config: config,
      files: []
    )

    resolver = FakeResolver.new(
      "ace-bundle/lib/foo.rb" => group,
      "docs/README.md" => group
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["ace-bundle/lib/foo.rb", "docs/README.md"], project_root: @project_root)

    refute groups.any? { |g| g.scope_name == "ace-config" }
  end

  # ===== Grouping behavior tests =====

  def test_groups_project_default_files_with_different_configs_into_one_group
    config_a = {"model" => "glite", "extra" => "setting"}
    config_b = {"model" => "glite"}

    # Both resolve to "project default" but with different configs
    group_a = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config_a,
      files: []
    )
    group_b = Ace::Support::Config::Models::ConfigGroup.new(
      name: "project default",
      source: "#{@project_root}/.ace-defaults/git/commit.yml",
      config: config_b,
      files: []
    )

    resolver = FakeResolver.new(
      "a.md" => group_a,
      "b.md" => group_a,
      "c.md" => group_b,
      "d.md" => group_b
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["a.md", "b.md", "c.md", "d.md"], project_root: @project_root)

    # Should be ONE group for "project default", not two
    assert_equal 1, groups.length
    assert_equal "project default", groups.first.scope_name
    assert_equal ["a.md", "b.md", "c.md", "d.md"], groups.first.files
  end

  def test_groups_named_scopes_with_different_configs_separately
    config_a = {"model" => "glite"}
    config_b = {"model" => "gflash"}

    # Both have "docs" scope but different configs
    group_a = Ace::Support::Config::Models::ConfigGroup.new(
      name: "docs",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config_a,
      files: []
    )
    group_b = Ace::Support::Config::Models::ConfigGroup.new(
      name: "docs",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config_b,
      files: []
    )

    resolver = FakeResolver.new(
      "a.md" => group_a,
      "b.md" => group_b
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["a.md", "b.md"], project_root: @project_root)

    # Named scopes with different configs remain separate
    assert_equal 2, groups.length
    assert groups.all? { |g| g.scope_name == "docs" }
  end

  # ===== rule_config grouping tests (TC-004-008 fix) =====

  def test_groups_path_rule_matches_with_same_rule_config_but_different_cascade_configs
    # This is the TC-004-008 scenario: files matching the same path rule
    # should group together even when cascade config differs
    # Note: PathRuleMatcher strips 'glob' from rule_config - it only contains overrides
    rule_config = {"type_hint" => "chore"}
    config_a = {"model" => "glite", "type_hint" => "chore"}  # root cascade
    config_b = {"model" => "gflash", "type_hint" => "chore"} # pkg-a cascade overrides model

    # Same path rule name, same rule_config, but different merged configs
    group_a = Ace::Support::Config::Models::ConfigGroup.new(
      name: "ace-config",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: config_a,
      rule_config: rule_config,
      files: []
    )
    group_b = Ace::Support::Config::Models::ConfigGroup.new(
      name: "ace-config",
      source: "#{@project_root}/pkg-a/.ace/git/commit.yml -> #{@project_root}/.ace/git/commit.yml",
      config: config_b,
      rule_config: rule_config,
      files: []
    )

    resolver = FakeResolver.new(
      ".ace/git/commit.yml" => group_a,
      "pkg-a/.ace/git/commit.yml" => group_b,
      "pkg-b/.ace/git/commit.yml" => group_b
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(
      [".ace/git/commit.yml", "pkg-a/.ace/git/commit.yml", "pkg-b/.ace/git/commit.yml"],
      project_root: @project_root
    )

    # Should be ONE group with all files (same rule_config)
    assert_equal 1, groups.length
    assert_equal "ace-config", groups.first.scope_name
    assert_equal 3, groups.first.files.length
  end

  def test_groups_path_rule_matches_with_different_rule_configs_separately
    # Different path rules should still be grouped separately
    # Note: PathRuleMatcher strips 'glob' from rule_config - it only contains overrides
    rule_config_docs = {"type_hint" => "docs"}
    rule_config_test = {"type_hint" => "test"}

    group_docs = Ace::Support::Config::Models::ConfigGroup.new(
      name: "docs-scope",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: {"model" => "glite", "type_hint" => "docs"},
      rule_config: rule_config_docs,
      files: []
    )
    group_test = Ace::Support::Config::Models::ConfigGroup.new(
      name: "test-scope",
      source: "#{@project_root}/.ace/git/commit.yml",
      config: {"model" => "glite", "type_hint" => "test"},
      rule_config: rule_config_test,
      files: []
    )

    resolver = FakeResolver.new(
      "docs/readme.md" => group_docs,
      "test/file_test.rb" => group_test
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["docs/readme.md", "test/file_test.rb"], project_root: @project_root)

    # Different rule_configs → different groups
    assert_equal 2, groups.length
    assert_includes groups.map(&:scope_name), "docs-scope"
    assert_includes groups.map(&:scope_name), "test-scope"
  end

  def test_groups_distributed_configs_without_rule_config_by_full_config
    # When rule_config is nil (distributed config), grouping uses full config
    config_a = {"model" => "glite"}
    config_b = {"model" => "gflash"}

    # Distributed configs have nil rule_config
    group_a = Ace::Support::Config::Models::ConfigGroup.new(
      name: "pkg-a",
      source: "#{@project_root}/pkg-a/.ace/git/commit.yml",
      config: config_a,
      rule_config: nil,
      files: []
    )
    group_b = Ace::Support::Config::Models::ConfigGroup.new(
      name: "pkg-b",
      source: "#{@project_root}/pkg-b/.ace/git/commit.yml",
      config: config_b,
      rule_config: nil,
      files: []
    )

    resolver = FakeResolver.new(
      "pkg-a/lib/file.rb" => group_a,
      "pkg-b/lib/file.rb" => group_b
    )

    grouper = Ace::GitCommit::Molecules::CommitGrouper.new(file_config_resolver: resolver)
    groups = grouper.group(["pkg-a/lib/file.rb", "pkg-b/lib/file.rb"], project_root: @project_root)

    # Different packages with different configs → different groups
    assert_equal 2, groups.length
  end
end
