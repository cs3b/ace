# frozen_string_literal: true

require "test_helper"
require "ace/hitl/cli"
require "stringio"

class HitlCliTest < AceHitlTestCase
  def test_library_contract
    assert_kind_of String, Ace::Hitl::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, Ace::Hitl::VERSION)
    assert_respond_to Ace::Hitl::HitlCLI, :start
  end

  def test_help_command
    result = run_cli(["help"])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(/ace-hitl/, result[:stdout])
    assert_match(/create/, result[:stdout])
    assert_match(/show/, result[:stdout])
    assert_match(/list/, result[:stdout])
    assert_match(/update/, result[:stdout])
    assert_match(/wait/, result[:stdout])
    assert_match(/\bask\b/, result[:stdout])
    refute_match(/proposal/, result[:stdout])
  end

  def test_operator_only_serve_uses_the_local_operator_binding
    policy = Object.new
    policy.define_singleton_method(:service_uid) { Process.uid }
    service = Object.new
    service.define_singleton_method(:run) { nil }
    selected = nil
    Ace::Hitl::Providers::Lab.stub(:grants_policy, policy) do
      Ace::Hitl::Lifecycle::Service.stub(:new, ->(**options) { selected = options; service }) do
        result = run_cli(["serve", "--operator-only", "--group", "ace-hitl-project"])
        assert_equal 0, result[:exit_code], result[:stderr]
      end
    end
    assert_equal "ace-hitl-project", selected[:group]
    assert_kind_of Ace::Hitl::Lifecycle::OperatorOnlyBinding, selected.fetch(:binding)
  end

  def test_serve_requires_operator_only
    result = run_cli(["serve", "--group", "ace-hitl-project"])

    assert_equal 1, result[:exit_code]
    assert_match(/requires --operator-only/, result[:stderr])
  end

  def test_removed_managed_and_tls_serve_modes_fail_clearly
    result = run_cli(["serve", "--operator-only", "--group", "ace-hitl-project", "--tls-authority", "/tmp/x.yml"])

    assert_equal 1, result[:exit_code]
    assert_match(/removed with the installed attempt authority/, result[:stderr])
  end

  def test_operator_question_and_read_commands_use_public_authenticated_client
    client = Object.new
    captured = nil
    client.define_singleton_method(:operator_question) do |**params|
      captured = params
      {"id" => params.fetch(:id), "requested" => true}
    end
    client.define_singleton_method(:read) { |id| {"id" => id, "state" => "created"} }
    Ace::Hitl::Providers::Lab.stub(:boundary_client, client) do
      result = run_cli(["operator-question", "operator001", "--project", "ace",
        "--plan", "Host question", "--question", "Which option?", "--options", "A,B"])
      assert_equal 0, result[:exit_code], result[:stderr]
      assert_equal({id: "operator001", project: "ace", plan: "Host question", question: "Which option?", options: ["A", "B"]}, captured)
      result = run_cli(["read", "operator001"])
      assert_equal 0, result[:exit_code], result[:stderr]
      assert_equal "created", JSON.parse(result[:stdout]).fetch("state")
    end
  end

  def test_serve_requires_explicit_dedicated_group
    policy = Object.new
    policy.define_singleton_method(:service_uid) { Process.uid }
    Ace::Hitl::Providers::Lab.stub(:grants_policy, policy) do
      result = run_cli(["serve", "--operator-only"])
      assert_equal 1, result[:exit_code]
      assert_match(/--group is required/, result[:stderr])
    end
  end

  def test_create_basic_hitl_event
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Which auth strategy?", "--kind", "decision", "--question", "JWT or sessions?"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/HITL event created:/, result[:stdout])

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        item = manager.list(in_folder: "all").first
        assert_equal "decision", item.kind
      end
    end
  end

  def test_create_requires_title
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create"])
        assert_equal 1, result[:exit_code]
        assert_match(/Title required/, result[:stderr])
      end
    end
  end

  def test_show_path_and_content
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "auth-decision")

      with_cli_root(root) do
        path_result = run_cli(["show", id, "--path"])
        assert_equal 0, path_result[:exit_code], path_result[:stderr]
        assert_match(/\.hitl\.s\.md/, path_result[:stdout])

        content_result = run_cli(["show", id, "--content"])
        assert_equal 0, content_result[:exit_code], content_result[:stderr]
        assert_match(/## Questions/, content_result[:stdout])
      end
    end
  end

  def test_list_defaults_to_all_statuses_when_status_omitted
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "aaa111", slug: "first", status: "pending")
      create_hitl_fixture(root, id: "bbb222", slug: "second", status: "answered")

      with_cli_root(root) do
        result = run_cli(["list", "--in", "all"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/^○\s+aaa111/m, result[:stdout])
        assert_match(/^✓\s+bbb222/m, result[:stdout])
        assert_match(/HITL Events:.*2 total/, result[:stdout])
      end
    end
  end

  def test_list_rejects_invalid_scope
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["list", "--scope", "global"])
        assert_equal 1, result[:exit_code]
        assert_match(/Invalid scope/, result[:stderr])
      end
    end
  end

  def test_show_rejects_invalid_scope
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["show", "aaa111", "--scope", "global"])
        assert_equal 1, result[:exit_code]
        assert_match(/Invalid scope/, result[:stderr])
      end
    end
  end

  def test_update_rejects_invalid_scope
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "aaa111", slug: "item")
      with_cli_root(root) do
        result = run_cli(["update", "aaa111", "--scope", "global", "--answer", "ok"])
        assert_equal 1, result[:exit_code]
        assert_match(/Invalid scope/, result[:stderr])
      end
    end
  end

  def test_show_scope_current_does_not_fallback_to_all
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "8ppq7w", slug: "main-only")

      resolver = StaticScopeResolver.new(
        default_scope: "current",
        current_worktree_root: task_worktree,
        roots_by_scope: {
          "current" => [task_worktree],
          "all" => [task_worktree, main_worktree]
        }
      )

      with_cli_root(task_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: resolver) do
        result = run_cli(["show", "8ppq7w", "--scope", "current"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
    end
  end

  def test_show_implicit_scope_falls_back_to_all_and_prints_location
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "8ppq7w", slug: "main-only")

      resolver = StaticScopeResolver.new(
        default_scope: "current",
        current_worktree_root: task_worktree,
        roots_by_scope: {
          "current" => [task_worktree],
          "all" => [task_worktree, main_worktree]
        }
      )

      with_cli_root(task_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: resolver) do
        normal = run_cli(["show", "8ppq7w"])
        assert_equal 0, normal[:exit_code], normal[:stderr]
        assert_match(/Resolved Location:/, normal[:stdout])
        assert_match(/worktree=#{Regexp.escape(main_worktree)}/, normal[:stdout])

        content = run_cli(["show", "8ppq7w", "--content"])
        assert_equal 0, content[:exit_code], content[:stderr]
        assert_match(/Resolved Location:/, content[:stdout])
        assert_match(/## Questions/, content[:stdout])
      end
    end
  end

  def test_update_scope_current_does_not_fallback_to_all
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "8ppq7w", slug: "main-only")

      resolver = StaticScopeResolver.new(
        default_scope: "current",
        current_worktree_root: task_worktree,
        roots_by_scope: {
          "current" => [task_worktree],
          "all" => [task_worktree, main_worktree]
        }
      )

      with_cli_root(task_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: resolver) do
        result = run_cli(["update", "8ppq7w", "--scope", "current", "--answer", "Nope"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
    end
  end

  def test_update_implicit_scope_falls_back_to_all
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "8ppq7w", slug: "main-only")

      resolver = StaticScopeResolver.new(
        default_scope: "current",
        current_worktree_root: task_worktree,
        roots_by_scope: {
          "current" => [task_worktree],
          "all" => [task_worktree, main_worktree]
        }
      )

      with_cli_root(task_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: resolver) do
        result = run_cli(["update", "8ppq7w", "--answer", "Confirmed fallback mutation"])
        assert_equal 0, result[:exit_code], result[:stderr]

        content_result = run_cli(["show", "8ppq7w", "--scope", "all", "--content"])
        assert_equal 0, content_result[:exit_code], content_result[:stderr]
        assert_match(/Confirmed fallback mutation/, content_result[:stdout])
      end
    end
  end

  def test_show_scope_all_errors_on_ambiguous_ref_with_candidates
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "aaa111", slug: "main-item")
      create_hitl_fixture(task_root, id: "bbb111", slug: "task-item")

      resolver = StaticScopeResolver.new(
        default_scope: "all",
        current_worktree_root: main_worktree,
        roots_by_scope: {
          "current" => [main_worktree],
          "all" => [main_worktree, task_worktree]
        }
      )

      with_cli_root(main_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: resolver) do
        result = run_cli(["show", "111", "--scope", "all"])
        assert_equal 1, result[:exit_code]
        assert_match(/ambiguous/i, result[:stderr])
        assert_match(/main-item/, result[:stderr])
        assert_match(/task-item/, result[:stderr])
      end
    end
  end

  def test_list_smart_defaults_scope_based_on_context
    with_multi_worktree_roots do |main_worktree, task_worktree|
      main_root = File.join(main_worktree, ".ace-local/hitl")
      task_root = File.join(task_worktree, ".ace-local/hitl")
      create_hitl_fixture(main_root, id: "aaa111", slug: "main-item", status: "pending")
      create_hitl_fixture(task_root, id: "bbb222", slug: "task-item", status: "pending")

      main_resolver = StaticScopeResolver.new(
        default_scope: "all",
        current_worktree_root: main_worktree,
        roots_by_scope: {
          "current" => [main_worktree],
          "all" => [main_worktree, task_worktree]
        }
      )
      with_cli_root(main_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: main_resolver) do
        main_result = run_cli(["list", "--in", "all"])
        assert_equal 0, main_result[:exit_code], main_result[:stderr]
        assert_match(/aaa111/, main_result[:stdout])
        assert_match(/bbb222/, main_result[:stdout])
      end

      task_resolver = StaticScopeResolver.new(
        default_scope: "current",
        current_worktree_root: task_worktree,
        roots_by_scope: {
          "current" => [task_worktree],
          "all" => [task_worktree, main_worktree]
        }
      )
      with_cli_root(task_root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}}, scope_resolver: task_resolver) do
        task_result = run_cli(["list", "--in", "all"])
        assert_equal 0, task_result[:exit_code], task_result[:stderr]
        assert_match(/bbb222/, task_result[:stdout])
        refute_match(/aaa111/, task_result[:stdout])
      end
    end
  end

  def test_show_not_found
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["show", "zzz"])
        assert_equal 1, result[:exit_code]
        assert_match(/not found/, result[:stderr])
      end
    end
  end

  def test_list_filters
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "aaa111", slug: "first", kind: "clarification", status: "pending", tags: ["auth"])
      create_hitl_fixture(root, id: "bbb222", slug: "second", kind: "decision", status: "answered", tags: ["release"])

      with_cli_root(root) do
        pending = run_cli(["list", "--status", "pending"])
        assert_equal 0, pending[:exit_code], pending[:stderr]
        assert_match(/^○\s+aaa111/m, pending[:stdout])
        refute_match(/bbb222/, pending[:stdout])
        assert_match(/HITL Events:.*1 of 2/, pending[:stdout])

        decisions = run_cli(["list", "--kind", "decision", "--status", "answered", "--in", "all"])
        assert_equal 0, decisions[:exit_code], decisions[:stderr]
        assert_match(/^✓\s+bbb222/m, decisions[:stdout])
        assert_match(/HITL Events:/, decisions[:stdout])
      end
    end
  end

  def test_update_answer_marks_answered
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "auth-decision", status: "pending")

      with_cli_root(root) do
        result = run_cli(["update", id, "--answer", "Use JWT with refresh tokens."])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/HITL event updated:/, result[:stdout])

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        updated = manager.show(id)[:event]
        assert_equal "answered", updated.status
        assert_match(/Use JWT with refresh tokens\./, File.read(updated.file_path))
      end
    end
  end

  def test_update_move_to_archive
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "move-me")

      with_cli_root(root) do
        result = run_cli(["update", id, "--move-to", "archive"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/_archive/, result[:stdout])
      end
    end
  end

  def test_wait_returns_answer_for_specific_hitl_event
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "answer-ready", status: "answered", answer: "Close assignment")

      with_cli_root(root) do
        result = run_cli(["wait", id, "--poll-every", "1", "--timeout", "5"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/HITL event answered: 8ppq7w/, result[:stdout])
        assert_match(/Close assignment/, result[:stdout])
      end
    end
  end

  def test_wait_times_out_when_no_answer
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "still-pending", status: "pending")

      with_cli_root(root) do
        result = run_cli(["wait", id, "--poll-every", "1", "--timeout", "1"])
        assert_equal 1, result[:exit_code]
        assert_match(/Timed out waiting/, result[:stderr])
      end
    end
  end

  def test_update_resume_skips_when_waiter_active
    with_hitl_dir do |root|
      id = "8ppq7w"
      now = Time.now.utc.iso8601
      create_hitl_fixture(
        root,
        id: id,
        slug: "waiter-active",
        status: "pending",
        extra_frontmatter: {
          "waiter_state" => "waiting",
          "waiter_last_seen_at" => now,
          "waiter_poll_every_sec" => 600,
          "resume_instructions" => "false"
        }
      )

      with_cli_root(root) do
        result = run_cli(["update", id, "--answer", "Proceed", "--resume"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Resume dispatch skipped/, result[:stdout])

        archived = run_cli(["list", "--in", "archive", "--status", "answered"])
        assert_equal 0, archived[:exit_code], archived[:stderr]
        refute_match(/8ppq7w/, archived[:stdout])
      end
    end
  end

  def test_update_resume_dispatches_and_archives_when_waiter_inactive
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(
        root,
        id: id,
        slug: "waiter-gone",
        status: "pending",
        extra_frontmatter: {
          "resume_instructions" => "true"
        }
      )

      with_cli_root(root) do
        result = run_cli(["update", id, "--answer", "Proceed", "--resume"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Resume dispatched/, result[:stdout])
        assert_match(/archived/, result[:stdout])

        archived = run_cli(["list", "--in", "archive", "--status", "answered"])
        assert_equal 0, archived[:exit_code], archived[:stderr]
        assert_match(/8ppq7w/, archived[:stdout])
      end
    end
  end

  def test_update_answer_preserves_markdown_headings_in_answer_body
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "heading-answer", status: "pending")
      answer_text = "Primary decision\n\n## Addendum\n\nKeep this section."

      with_cli_root(root) do
        result = run_cli(["update", id, "--answer", answer_text])
        assert_equal 0, result[:exit_code], result[:stderr]

        shown = run_cli(["show", id, "--content"])
        assert_equal 0, shown[:exit_code], shown[:stderr]
        assert_match(/Primary decision/, shown[:stdout])
        assert_match(/## Addendum/, shown[:stdout])
        assert_match(/Keep this section\./, shown[:stdout])
      end
    end
  end

  def test_update_requires_operation
    with_hitl_dir do |root|
      id = "8ppq7w"
      create_hitl_fixture(root, id: id, slug: "noop")

      with_cli_root(root) do
        result = run_cli(["update", id])
        assert_equal 1, result[:exit_code]
        assert_match(/No update operations specified/, result[:stderr])
      end
    end
  end

  def test_create_avoids_duplicate_ids_when_time_collides
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
      fixed_time = Time.utc(2026, 4, 1, 12, 0, 0)

      first = manager.create("First collision test", time: fixed_time)
      second = manager.create("Second collision test", time: fixed_time)

      refute_equal first.id, second.id
    end
  end

  def test_list_empty
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["list", "--in", "all"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/No HITL events found/, result[:stdout])
        assert_match(/HITL Events:.*0 total/, result[:stdout])
      end
    end
  end

  def test_create_report_event
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli([
          "create", "Work done on auth",
          "--type", "report", "--result", "success",
          "--body", "Implemented JWT login",
          "--body", "Tests green",
          "--task", "8xg.t.sbz.1.0", "--assignment", "abc123", "--step", "010"
        ])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/HITL event created:/, result[:stdout])

        id = result[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]
        content = File.read(Dir.glob(File.join(root, "**", "#{id}-*.hitl.s.md")).first)
        assert_match(/^type: report/, content)
        assert_match(/^result: success/, content)
        assert_match(/^status: recorded/, content)
        assert_match(/^task: 8xg\.t\.sbz\.1\.0/, content)
        assert_match(/## Report/, content)
        refute_match(/## Questions/, content)
        refute_match(/## Answer/, content)

        show = run_cli(["show", id])
        assert_equal 0, show[:exit_code], show[:stderr]
        assert_match(/Type: report/, show[:stdout])
        assert_match(/Result: success/, show[:stdout])
        refute_match(/Questions:/, show[:stdout])
        refute_match(/Answer:/, show[:stdout])

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        event = manager.list(in_folder: "all", type: "report").first
        assert_equal "report", event.type
        assert_equal "success", event.result
        assert_equal "recorded", event.status
        assert_equal "8xg.t.sbz.1.0", event.metadata["task"]
        assert_equal "abc123", event.metadata["assignment"]
        assert event.report?
        assert event.question? == false
        refute event.answered?
      end
    end
  end

  def test_create_question_writes_explicit_type
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Which auth strategy?", "--kind", "decision", "--question", "JWT?"])
        assert_equal 0, result[:exit_code], result[:stderr]

        id = result[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]
        content = File.read(Dir.glob(File.join(root, "**", "#{id}-*.hitl.s.md")).first)
        assert_match(/^type: question/, content)
      end
    end
  end

  def test_report_is_never_a_blocked_question
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Work done", "--type", "report", "--result", "success"])
        assert_equal 0, result[:exit_code], result[:stderr]
        id = result[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

        pending = run_cli(["list", "--status", "pending", "--in", "all"])
        assert_equal 0, pending[:exit_code], pending[:stderr]
        refute_match(/#{id}/, pending[:stdout])

        wait = run_cli(["wait", id, "--timeout", "1"])
        assert_equal 1, wait[:exit_code]
        assert_match(/report; reports do not await an answer/, wait[:stderr])

        answer = run_cli(["update", id, "--answer", "x"])
        assert_equal 1, answer[:exit_code]
        assert_match(/report; reports do not await an answer/, answer[:stderr])

        resume = run_cli(["update", id, "--resume"])
        assert_equal 1, resume[:exit_code]
        assert_match(/report; reports do not await an answer or resume/, resume[:stderr])

        show = run_cli(["show", id])
        assert_equal 0, show[:exit_code], show[:stderr]
        assert_match(/Status: recorded/, show[:stdout])

        generic = run_cli(["update", id, "--add", "tags=processed"])
        assert_equal 0, generic[:exit_code], generic[:stderr]

        archived = run_cli(["update", id, "--move-to", "archive"])
        assert_equal 0, archived[:exit_code], archived[:stderr]
      end
    end
  end

  def test_question_cycle_unchanged_and_silence_is_not_consent
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "Which DB?", "--question", "Postgres or SQLite?"])
        assert_equal 0, result[:exit_code], result[:stderr]
        id = result[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

        show = run_cli(["show", id])
        assert_equal 0, show[:exit_code], show[:stderr]
        assert_match(/Status: pending/, show[:stdout])
        assert_match(/Answer: \(none\)/, show[:stdout])

        wait = run_cli(["wait", id, "--timeout", "1"])
        assert_equal 1, wait[:exit_code]
        assert_match(/Timed out/, wait[:stderr])
      end
    end
  end

  def test_create_rejects_kind_on_report
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["create", "T", "--type", "report", "--result", "success", "--kind", "decision"])
        assert_equal 1, result[:exit_code]
        assert_match(/--kind cannot be combined with --type report/, result[:stderr])
      end
    end
  end

  def test_create_rejects_invalid_report_and_question_combinations
    with_hitl_dir do |root|
      with_cli_root(root) do
        invalid_type = run_cli(["create", "T", "--type", "bogus"])
        assert_equal 1, invalid_type[:exit_code]
        assert_match(/Invalid type 'bogus'/, invalid_type[:stderr])

        missing_result = run_cli(["create", "T", "--type", "report"])
        assert_equal 1, missing_result[:exit_code]
        assert_match(/requires --result/, missing_result[:stderr])

        invalid_result = run_cli(["create", "T", "--type", "report", "--result", "bogus"])
        assert_equal 1, invalid_result[:exit_code]
        assert_match(/Invalid result 'bogus'/, invalid_result[:stderr])

        question_on_report = run_cli(["create", "T", "--type", "report", "--result", "success", "--question", "Q?"])
        assert_equal 1, question_on_report[:exit_code]
        assert_match(/--question cannot be combined with --type report/, question_on_report[:stderr])

        resume_on_report = run_cli(["create", "T", "--type", "report", "--result", "success", "--resume", "/x"])
        assert_equal 1, resume_on_report[:exit_code]
        assert_match(/--resume cannot be combined with --type report/, resume_on_report[:stderr])

        result_on_question = run_cli(["create", "T", "--result", "success"])
        assert_equal 1, result_on_question[:exit_code]
        assert_match(/--result is only valid with --type report/, result_on_question[:stderr])

        body_on_question = run_cli(["create", "T", "--body", "line"])
        assert_equal 1, body_on_question[:exit_code]
        assert_match(/--body is only valid with --type report/, body_on_question[:stderr])
      end
    end
  end

  def test_list_filters_by_type
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "qqq111", slug: "question-one", type: "question", status: "pending")
      create_hitl_fixture(root, id: "rrr222", slug: "report-one", type: "report",
        result: "error", task: "8xg.t.sbz.1.0", status: "recorded", body: ["step failed"])

      with_cli_root(root) do
        reports = run_cli(["list", "--type", "report", "--in", "all"])
        assert_equal 0, reports[:exit_code], reports[:stderr]
        assert_match(/rrr222/, reports[:stdout])
        refute_match(/qqq111/, reports[:stdout])
        assert_match(/▪\s+rrr222/, reports[:stdout])

        questions = run_cli(["list", "--type", "question", "--in", "all"])
        assert_equal 0, questions[:exit_code], questions[:stderr]
        assert_match(/qqq111/, questions[:stdout])
        refute_match(/rrr222/, questions[:stdout])

        invalid = run_cli(["list", "--type", "bogus"])
        assert_equal 1, invalid[:exit_code]
        assert_match(/Invalid type 'bogus'/, invalid[:stderr])
      end
    end
  end

  def test_help_includes_report_example
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["--help"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/--type report --result success --task/, result[:stdout])
        assert_match(/Create HITL event \(question or report\)/, result[:stdout])
      end
    end
  end
end
