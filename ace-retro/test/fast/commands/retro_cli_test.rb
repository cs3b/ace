# frozen_string_literal: true

require "test_helper"
require "ace/retro/cli"
require "stringio"

# CLI integration tests for ace-retro commands.
# Tests each command by invoking RetroCLI.start(args) against a temp retros directory.
class RetroCliTest < AceRetroTestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Capture stdout/stderr during a CLI invocation.
  # @return [Hash] { stdout:, stderr:, exit_code: }
  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Retro::RetroCLI.start(args)
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

  # Run CLI with a real RetroManager scoped to a tmp directory.
  # Monkey-patches RetroManager.new to use the given root.
  def with_cli_root(root_dir)
    original_new = Ace::Retro::Organisms::RetroManager.method(:new)
    Ace::Retro::Organisms::RetroManager.define_singleton_method(:new) do |**_opts|
      original_new.call(root_dir: root_dir)
    end
    yield
  ensure
    Ace::Retro::Organisms::RetroManager.singleton_class.remove_method(:new)
  end

  def with_project_root_workspace
    Dir.mktmpdir("ace-retro-project-root") do |tmp_repo_root|
      repo_root = File.realpath(tmp_repo_root)
      old_pwd = Dir.pwd
      old_project_root = ENV["PROJECT_ROOT_PATH"]

      FileUtils.touch(File.join(repo_root, "Gemfile"))
      nested_dir = File.join(repo_root, "app", "subdir")
      FileUtils.mkdir_p(nested_dir)
      ENV.delete("PROJECT_ROOT_PATH")
      clear_project_root_cache

      yield repo_root, nested_dir
    ensure
      Dir.chdir(old_pwd) if old_pwd
      if old_project_root.nil?
        ENV.delete("PROJECT_ROOT_PATH")
      else
        ENV["PROJECT_ROOT_PATH"] = old_project_root
      end
      clear_project_root_cache
    end
  end

  def chdir_for_root_resolution(path)
    Dir.chdir(path)
    clear_project_root_cache
  end

  # ---------------------------------------------------------------------------
  # create command
  # ---------------------------------------------------------------------------

  def test_create_basic_retro
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Sprint Review"])
        assert_equal 0, result[:exit_code], "Expected exit 0, got: #{result[:stderr]}"
        assert_match(/Retro created:/, result[:stdout])
        assert_match(/Path:/, result[:stdout])
      end
    end
  end

  def test_create_with_type_and_tags
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Self check", "--type", "self-review", "--tags", "sprint,personal"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro created:/, result[:stdout])
      end
    end
  end

  def test_create_with_move_to
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Archived retro", "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro created:/, result[:stdout])
        assert_match(/_archive/, result[:stdout])
      end
    end
  end

  def test_create_dry_run
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Dry run retro", "--dry-run"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Would create retro:/, result[:stdout])
        # No files written
        entries = Dir.entries(root) - [".", ".."]
        assert_empty entries, "dry-run should not create any files"
      end
    end
  end

  def test_create_requires_title
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create"])
        assert_equal 1, result[:exit_code]
        assert_match(/Title required/, result[:stderr])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # show command
  # ---------------------------------------------------------------------------

  def test_show_formatted
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "test-retro", status: "active", tags: ["sprint"])
      with_cli_root(root) do
        result = run_cli(["show", id])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/#{id}/, result[:stdout])
        assert_match(/Test retro/, result[:stdout])
      end
    end
  end

  def test_show_path_flag
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "test-retro")
      with_cli_root(root) do
        result = run_cli(["show", id, "--path"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/\.retro\.md/, result[:stdout])
        refute_match(/🟡|🟢/, result[:stdout])
      end
    end
  end

  def test_show_content_flag
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "test-retro")
      with_cli_root(root) do
        result = run_cli(["show", id, "--content"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/---/, result[:stdout])
      end
    end
  end

  def test_show_not_found
    with_retros_dir do |root|
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
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "first-retro")
      create_retro_fixture(root, id: "bbb222", slug: "second-retro")
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/First retro/, result[:stdout])
        assert_match(/Second retro/, result[:stdout])
      end
    end
  end

  def test_list_empty
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/No retros found/, result[:stdout])
      end
    end
  end

  def test_list_in_folder
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "root-retro")
      create_retro_fixture(root, id: "bbb222", slug: "archived-retro", special_folder: "_archive")
      with_cli_root(root) do
        result = run_cli(["list", "--in", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Archived retro/, result[:stdout])
        refute_match(/Root retro/, result[:stdout])
      end
    end
  end

  def test_list_filter_by_status
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "active-retro", status: "active")
      create_retro_fixture(root, id: "bbb222", slug: "done-retro", status: "done")
      with_cli_root(root) do
        result = run_cli(["list", "--status", "active"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Active retro/, result[:stdout])
        refute_match(/Done retro/, result[:stdout])
      end
    end
  end

  def test_list_filter_by_type
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "standard-retro", type: "standard")
      create_retro_fixture(root, id: "bbb222", slug: "self-retro", type: "self-review")
      with_cli_root(root) do
        result = run_cli(["list", "--type", "self-review"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Self retro/, result[:stdout])
        refute_match(/Standard retro/, result[:stdout])
      end
    end
  end

  def test_list_filter_by_tags
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "sprint-retro", tags: ["sprint"])
      create_retro_fixture(root, id: "bbb222", slug: "personal-retro", tags: ["personal"])
      with_cli_root(root) do
        result = run_cli(["list", "--tags", "sprint"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Sprint retro/, result[:stdout])
        refute_match(/Personal retro/, result[:stdout])
      end
    end
  end

  def test_list_shows_stats_line
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "active-retro", status: "active")
      create_retro_fixture(root, id: "bbb222", slug: "done-retro", status: "done")
      with_cli_root(root) do
        result = run_cli(["list"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retros:.*total/, result[:stdout])
      end
    end
  end

  def test_commands_default_to_project_root_retros_from_nested_cwd
    with_project_root_workspace do |repo_root, nested_dir|
      root_retros = File.join(repo_root, ".ace-retros")
      nested_retros = File.join(nested_dir, ".ace-retros")
      package_retros = File.join(repo_root, "app", ".ace-retros")

      chdir_for_root_resolution(nested_dir)
      create_result = run_cli(["create", "Nested cwd retro", "--type", "standard"])
      assert_equal 0, create_result[:exit_code], create_result[:stderr]
      assert_match(/Path: #{Regexp.escape(root_retros)}\//, create_result[:stdout])
      refute Dir.exist?(nested_retros), "nested cwd should not receive the default retros workspace"

      retro_id = create_result[:stdout].match(/Retro created: ([0-9a-z]+)/)[1]

      chdir_for_root_resolution(repo_root)
      list_result = run_cli(["list"])
      assert_equal 0, list_result[:exit_code], list_result[:stderr]
      assert_match(/Nested cwd retro/, list_result[:stdout])

      show_result = run_cli(["show", retro_id, "--path"])
      assert_equal 0, show_result[:exit_code], show_result[:stderr]
      assert_match(/\A#{Regexp.escape(root_retros)}\//, show_result[:stdout])

      update_result = run_cli(["update", retro_id, "--set", "status=done"])
      assert_equal 0, update_result[:exit_code], update_result[:stderr]
      assert_match(/Retro updated: #{retro_id}/, update_result[:stdout])

      chdir_for_root_resolution(nested_dir)
      doctor_result = run_cli(["doctor", "--quiet"])
      assert_equal 0, doctor_result[:exit_code], doctor_result[:stderr]

      create_retro_fixture(package_retros, id: "bbb222", slug: "package-local")

      chdir_for_root_resolution(repo_root)
      root_list_result = run_cli(["list", "--in", "all"])
      assert_equal 0, root_list_result[:exit_code], root_list_result[:stderr]
      refute_match(/Package local/, root_list_result[:stdout])

      custom_list_result = run_cli(["list", "--root", package_retros])
      assert_equal 0, custom_list_result[:exit_code], custom_list_result[:stderr]
      assert_match(/Package local/, custom_list_result[:stdout])
      refute_match(/Nested cwd retro/, custom_list_result[:stdout])
    end
  end

  # ---------------------------------------------------------------------------
  # update command
  # ---------------------------------------------------------------------------

  def test_update_set_status
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "updatable-retro", status: "active")
      with_cli_root(root) do
        result = run_cli(["update", id, "--set", "status=done"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro updated:/, result[:stdout])

        manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
        updated = manager.show(id)
        assert_equal "done", updated.status
      end
    end
  end

  def test_update_add_tags
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "tag-retro", tags: ["existing"])
      with_cli_root(root) do
        result = run_cli(["update", id, "--add", "tags=new-tag"])
        assert_equal 0, result[:exit_code], result[:stderr]

        manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
        updated = manager.show(id)
        assert_includes updated.tags, "existing"
        assert_includes updated.tags, "new-tag"
      end
    end
  end

  def test_update_remove_tags
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "tag-retro", tags: ["keep", "remove-me"])
      with_cli_root(root) do
        result = run_cli(["update", id, "--remove", "tags=remove-me"])
        assert_equal 0, result[:exit_code], result[:stderr]

        manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
        updated = manager.show(id)
        assert_includes updated.tags, "keep"
        refute_includes updated.tags, "remove-me"
      end
    end
  end

  def test_update_move_to_archive
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "moveable-retro")
      with_cli_root(root) do
        result = run_cli(["update", id, "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro updated:/, result[:stdout])
        assert_match(/_archive/, result[:stdout])
      end
    end
  end

  def test_update_set_and_move_to
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "combo-retro", status: "active")
      with_cli_root(root) do
        result = run_cli(["update", id, "--set", "status=done", "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/_archive/, result[:stdout])

        manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
        updated = manager.show(id)
        assert_equal "done", updated.status
      end
    end
  end

  def test_update_move_to_next
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "moveable-retro", special_folder: "_archive")
      with_cli_root(root) do
        result = run_cli(["update", id, "--move-to", "next"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/root/, result[:stdout])
      end
    end
  end

  def test_update_requires_at_least_one_operation
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "test-retro")
      with_cli_root(root) do
        result = run_cli(["update", id])
        assert_equal 1, result[:exit_code]
        assert_match(/No update operations specified/, result[:stderr])
      end
    end
  end

  def test_update_not_found
    with_retros_dir do |root|
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
    with_retros_dir do |root|
      with_cli_root(root) do
        commit_args = nil
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) {
          commit_args = kwargs
          true
        }) do
          result = run_cli(["create", "Retro with gc", "--git-commit"])
          assert_equal 0, result[:exit_code], result[:stderr]
        end

        refute_nil commit_args, "Expected GitCommitter.commit to be called"
        assert_match(/create retro/, commit_args[:intention])
      end
    end
  end

  def test_create_without_git_commit_does_not_call_committer
    with_retros_dir do |root|
      with_cli_root(root) do
        commit_called = false
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
          run_cli(["create", "Retro without gc"])
        end

        refute commit_called, "Expected GitCommitter.commit NOT to be called"
      end
    end
  end

  def test_create_dry_run_with_git_commit_does_not_call_committer
    with_retros_dir do |root|
      with_cli_root(root) do
        commit_called = false
        Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
          run_cli(["create", "Dry run gc retro", "--dry-run", "--git-commit"])
        end

        refute commit_called, "Expected GitCommitter.commit NOT to be called during dry-run"
      end
    end
  end

  def test_update_with_git_commit_calls_committer
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "gc-retro", status: "active")
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
        assert_match(/update retro/, commit_args[:intention])
      end
    end
  end

  def test_update_move_to_with_git_commit_calls_committer
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "gc-retro")
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
        assert_match(/update retro.*move/, commit_args[:intention])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # version and help
  # ---------------------------------------------------------------------------

  def test_version_command
    result = run_cli(["version"])
    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(/ace-retro/, result[:stdout])
    assert_match(/\d+\.\d+\.\d+/, result[:stdout])
  end

  def test_help_command
    result = run_cli(["help"])
    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(/ace-retro/, result[:stdout])
    assert_match(/create/, result[:stdout])
    assert_match(/show/, result[:stdout])
    assert_match(/list/, result[:stdout])
    assert_match(/update/, result[:stdout])
  end

  def test_list_with_root_option
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "root-test")
      # Use --root to point at the tmp directory without monkey-patching
      result = run_cli(["list", "--root", root])
      assert_equal 0, result[:exit_code], result[:stderr]
      assert_match(/Root test/, result[:stdout])
    end
  end
end
