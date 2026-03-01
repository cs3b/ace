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
    rescue Ace::Core::CLI::Error => e
      $stderr.puts e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    { stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code }
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

  def test_create_with_task_ref
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Task retro", "--task-ref", "q7w"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro created:/, result[:stdout])

        # Verify task_ref was stored
        manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
        retros = manager.list
        assert_equal 1, retros.size
        assert_equal "q7w", retros.first.task_ref
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

  # ---------------------------------------------------------------------------
  # move command
  # ---------------------------------------------------------------------------

  def test_move_to_archive
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "moveable-retro")
      with_cli_root(root) do
        result = run_cli(["move", id, "--to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro moved:/, result[:stdout])
        assert_match(/_archive/, result[:stdout])
      end
    end
  end

  def test_move_to_root
    with_retros_dir do |root|
      id = "8ppq7w"
      create_retro_fixture(root, id: id, slug: "moveable-retro", special_folder: "_archive")
      with_cli_root(root) do
        result = run_cli(["move", id, "--to", "root"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Retro moved:/, result[:stdout])
        assert_match(/root/, result[:stdout])
      end
    end
  end

  def test_move_not_found
    with_retros_dir do |root|
      with_cli_root(root) do
        result = run_cli(["move", "zzz", "--to", "archive"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
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
    assert_match(/move/, result[:stdout])
    assert_match(/update/, result[:stdout])
  end
end
