# frozen_string_literal: true

require "test_helper"
require "ace/idea/cli"
require "stringio"

# CLI integration tests for ace-idea commands.
# Tests each command by invoking IdeaCLI.start(args) against a temp ideas directory.
class IdeaCliTest < AceIdeaTestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Capture stdout/stderr during a CLI invocation.
  # @return [Hash] { stdout:, stderr:, exit_code: }
  def run_cli(args, env_root: nil)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Idea::IdeaCLI.start(args)
    rescue Ace::Support::Cli::Error => e
      warn e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    {stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code}
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  # Run CLI with a real IdeaManager scoped to a tmp directory.
  # Monkey-patches IdeaManager.new to use the given root.
  def with_cli_root(root_dir)
    original_new = Ace::Idea::Organisms::IdeaManager.method(:new)
    Ace::Idea::Organisms::IdeaManager.define_singleton_method(:new) do |**_opts|
      original_new.call(root_dir: root_dir)
    end
    yield
  ensure
    Ace::Idea::Organisms::IdeaManager.singleton_class.remove_method(:new)
  end

  # ---------------------------------------------------------------------------
  # create command
  # ---------------------------------------------------------------------------

  def test_create_basic_idea
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "My new idea"])
        assert_equal 0, result[:exit_code], "Expected exit 0, got: #{result[:stderr]}"
        assert_match(/Idea created:/, result[:stdout])
        assert_match(/Path:/, result[:stdout])
      end
    end
  end

  def test_create_with_title_and_tags
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Great idea", "--title", "My Great Idea", "--tags", "ux,design"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Idea created:/, result[:stdout])
        assert_match(/My Great Idea/, result[:stdout])
      end
    end
  end

  def test_create_with_move_to
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Maybe item idea", "--move-to", "maybe"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Idea created:/, result[:stdout])
        assert_match(/_maybe/, result[:stdout])
      end
    end
  end

  def test_create_dry_run
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Dry run idea", "--dry-run"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Would create idea:/, result[:stdout])
        # No files written
        entries = Dir.entries(root) - [".", ".."]
        assert_empty entries, "dry-run should not create any files"
      end
    end
  end

  def test_create_requires_content_or_clipboard
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create"])
        assert_equal 1, result[:exit_code]
        assert_match(/Content or --clipboard required/, result[:stderr])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # show command
  # ---------------------------------------------------------------------------

  def test_show_formatted
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "test-idea", status: "pending", tags: ["ux"])
      with_cli_root(root) do
        result = run_cli(["show", id])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/#{id}/, result[:stdout])
        assert_match(/Test idea/, result[:stdout])
      end
    end
  end

  def test_show_path_flag
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "test-idea")
      with_cli_root(root) do
        result = run_cli(["show", id, "--path"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/\.idea\.s\.md/, result[:stdout])
        refute_match(/⚪|🟡|🟢/, result[:stdout])
      end
    end
  end

  def test_show_content_flag
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "test-idea")
      with_cli_root(root) do
        result = run_cli(["show", id, "--content"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/---/, result[:stdout])  # frontmatter present
      end
    end
  end

  def test_show_not_found
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["show", "zzz"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # list command
  # ---------------------------------------------------------------------------

  def test_list_all
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "first-idea")
      create_idea_fixture(root, id: "bbb222", slug: "second-idea")
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/First idea/, result[:stdout])
        assert_match(/Second idea/, result[:stdout])
      end
    end
  end

  def test_list_empty
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/No ideas found/, result[:stdout])
        assert_match(/Ideas:/, result[:stdout])
        assert_match(/• 0 total/, result[:stdout])
      end
    end
  end

  def test_list_empty_shows_summary_for_scoped_filter
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "root-idea")
      create_idea_fixture(root, id: "bbb222", slug: "maybe-idea", special_folder: "_maybe")

      with_cli_root(root) do
        result = run_cli(["list", "--in", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/No ideas found/, result[:stdout])
        assert_match(/Ideas:/, result[:stdout])
        assert_match(/• 0 of 2/, result[:stdout])
        refute_match(/Root idea/, result[:stdout])
      end
    end
  end

  def test_list_in_folder
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "root-idea")
      create_idea_fixture(root, id: "bbb222", slug: "maybe-idea", special_folder: "_maybe")
      with_cli_root(root) do
        result = run_cli(["list", "--in", "maybe"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Maybe idea/, result[:stdout])
        refute_match(/Root idea/, result[:stdout])
      end
    end
  end

  def test_list_filter_by_status
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "pending-idea", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "done-idea", status: "done")
      with_cli_root(root) do
        result = run_cli(["list", "--status", "pending"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Pending idea/, result[:stdout])
        refute_match(/Done idea/, result[:stdout])
      end
    end
  end

  def test_list_filter_by_tags
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "ux-idea", tags: ["ux"])
      create_idea_fixture(root, id: "bbb222", slug: "backend-idea", tags: ["backend"])
      with_cli_root(root) do
        result = run_cli(["list", "--tags", "ux"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Ux idea/, result[:stdout])
        refute_match(/Backend idea/, result[:stdout])
      end
    end
  end

  def test_list_shows_stats_line
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "first-idea", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "second-idea", status: "done")
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Ideas:.*total/, result[:stdout])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # update command
  # ---------------------------------------------------------------------------

  def test_update_set_status
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "updatable-idea", status: "pending")
      with_cli_root(root) do
        result = run_cli(["update", id, "--set", "status=done"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Idea updated:/, result[:stdout])

        # Verify by loading again
        manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
        updated = manager.show(id)
        assert_equal "done", updated.status
      end
    end
  end

  def test_update_add_tags
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "tag-idea", tags: ["existing"])
      with_cli_root(root) do
        result = run_cli(["update", id, "--add", "tags=new-tag"])
        assert_equal 0, result[:exit_code], result[:stderr]

        manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
        updated = manager.show(id)
        assert_includes updated.tags, "existing"
        assert_includes updated.tags, "new-tag"
      end
    end
  end

  def test_update_remove_tags
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "tag-idea", tags: ["keep", "remove-me"])
      with_cli_root(root) do
        result = run_cli(["update", id, "--remove", "tags=remove-me"])
        assert_equal 0, result[:exit_code], result[:stderr]

        manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
        updated = manager.show(id)
        assert_includes updated.tags, "keep"
        refute_includes updated.tags, "remove-me"
      end
    end
  end

  def test_update_move_to_archive
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "moveable-idea")
      with_cli_root(root) do
        result = run_cli(["update", id, "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Idea updated:/, result[:stdout])
        assert_match(/_archive/, result[:stdout])
      end
    end
  end

  def test_update_set_and_move_to
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "combo-idea", status: "pending")
      with_cli_root(root) do
        result = run_cli(["update", id, "--set", "status=done", "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/_archive/, result[:stdout])

        # Verify status was updated
        manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
        updated = manager.show(id)
        assert_equal "done", updated.status
      end
    end
  end

  def test_update_move_to_next
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "moveable-idea", special_folder: "_maybe")
      with_cli_root(root) do
        result = run_cli(["update", id, "--move-to", "next"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/root/, result[:stdout])
      end
    end
  end

  def test_update_requires_at_least_one_operation
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "test-idea")
      with_cli_root(root) do
        result = run_cli(["update", id])
        assert_equal 1, result[:exit_code]
        assert_match(/No update operations specified/, result[:stderr])
      end
    end
  end

  def test_update_not_found
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["update", "zzz", "--set", "status=done"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --git-commit / --gc flag
  # ---------------------------------------------------------------------------

  def test_create_with_git_commit_calls_committer
    with_ideas_dir do |root|
      with_cli_root(root) do
        commit_args = nil
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) {
          commit_args = kwargs
          true
        }) do
          result = run_cli(["create", "Idea with gc", "--git-commit"])
          assert_equal 0, result[:exit_code], result[:stderr]
        end

        refute_nil commit_args, "Expected GitCommitter.commit to be called"
        assert_match(/create idea/, commit_args[:intention])
      end
    end
  end

  def test_create_without_git_commit_does_not_call_committer
    with_ideas_dir do |root|
      with_cli_root(root) do
        commit_called = false
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
          run_cli(["create", "Idea without gc"])
        end

        refute commit_called, "Expected GitCommitter.commit NOT to be called"
      end
    end
  end

  def test_create_dry_run_with_git_commit_does_not_call_committer
    with_ideas_dir do |root|
      with_cli_root(root) do
        commit_called = false
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
          run_cli(["create", "Dry run gc idea", "--dry-run", "--git-commit"])
        end

        refute commit_called, "Expected GitCommitter.commit NOT to be called during dry-run"
      end
    end
  end

  def test_update_with_git_commit_calls_committer
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "gc-idea", status: "pending")
      with_cli_root(root) do
        commit_args = nil
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) {
          commit_args = kwargs
          true
        }) do
          result = run_cli(["update", id, "--set", "status=done", "--git-commit"])
          assert_equal 0, result[:exit_code], result[:stderr]
        end

        refute_nil commit_args, "Expected GitCommitter.commit to be called"
        assert_match(/update idea/, commit_args[:intention])
      end
    end
  end

  def test_update_move_to_with_git_commit_calls_committer
    with_ideas_dir do |root|
      id = "8ppq7w"
      create_idea_fixture(root, id: id, slug: "gc-idea")
      with_cli_root(root) do
        commit_args = nil
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) {
          commit_args = kwargs
          true
        }) do
          result = run_cli(["update", id, "--move-to", "archive", "--git-commit"])
          assert_equal 0, result[:exit_code], result[:stderr]
        end

        refute_nil commit_args, "Expected GitCommitter.commit to be called"
        assert_match(/update idea.*move/, commit_args[:intention])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # version and help
  # ---------------------------------------------------------------------------

  def test_version_command
    result = run_cli(["version"])
    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(/ace-idea/, result[:stdout])
    assert_match(/\d+\.\d+\.\d+/, result[:stdout])
  end

  def test_help_command
    result = run_cli(["help"])
    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(/ace-idea/, result[:stdout])
    assert_match(/create/, result[:stdout])
    assert_match(/show/, result[:stdout])
    assert_match(/list/, result[:stdout])
    assert_match(/update/, result[:stdout])
  end
end
