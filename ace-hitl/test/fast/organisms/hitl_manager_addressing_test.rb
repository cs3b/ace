# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Organisms
      class HitlManagerAddressingTest < AceHitlTestCase
        def address_config(machine: "lab01", default: nil)
          {"hitl" => {
            "root_dir" => ".ace-local/hitl",
            "machine" => machine,
            "default_recipient" => default,
            "recipients" => {
              "overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"},
              "captain" => {"machine" => "lab02", "panel" => "telegram"}
            }
          }}
        end

        def manager(root, config: address_config)
          HitlManager.new(root_dir: root, config: config)
        end

        def test_create_with_folder_recipient_stamps_address_and_reply
          with_hitl_dir do |root|
            event = manager(root).create("Which DB?", to: "overseer", questions: ["Postgres?"])

            assert_equal "lab01", event.recipient["machine"]
            assert_equal ".ace-local/hitl", event.recipient["folder"]
            assert_equal event.id, event.recipient["id"]
            assert_equal "lab01", event.reply_to["machine"]
            assert_equal ".ace-local/hitl", event.reply_to["folder"]
            assert_equal event.id, event.reply_to["id"]

            content = File.read(event.file_path)
            assert_match(/^recipient_machine: lab01/, content)
            assert_match(/^recipient_id: #{event.id}/, content)
            assert_match(/^reply_to_machine: lab01/, content)
            assert_match(/^reply_to_id: #{event.id}/, content)
          end
        end

        def test_create_with_panel_recipient_has_no_recipient_id
          with_hitl_dir do |root|
            event = manager(root).create("Which DB?", to: "captain", questions: ["Q?"])

            assert_equal({"machine" => "lab02", "panel" => "telegram"}, event.recipient)
            assert_nil event.recipient["id"]
            assert event.reply_to["id"] == event.id
          end
        end

        def test_report_carries_recipient_but_no_reply
          with_hitl_dir do |root|
            event = manager(root).create("Work done",
              to: "overseer", type: "report", result: "success",
              task: "8xg.t.sbz.1.1", assignment: "abc123", body: ["done"])

            assert_equal event.id, event.recipient["id"]
            assert_nil event.reply_to
            assert_equal "8xg.t.sbz.1.1", event.metadata["task"]
            assert_equal "abc123", event.metadata["assignment"]
          end
        end

        def test_unknown_recipient_writes_nothing
          with_hitl_dir do |root|
            error = assert_raises(Molecules::HitlAddressResolver::UnknownRecipientError) do
              manager(root).create("Q?", to: "ghost")
            end
            assert_includes error.message, "Configured recipients"

            assert Dir.children(root).empty?, "no event may be written for an unknown recipient"
          end
        end

        def test_default_recipient_applied_when_to_absent
          with_hitl_dir do |root|
            event = manager(root, config: address_config(default: "overseer"))
              .create("Q?", questions: ["Q?"])
            assert_equal "lab01", event.recipient["machine"]
          end
        end

        def test_no_recipient_and_no_default_keeps_legacy_event
          with_hitl_dir do |root|
            event = manager(root, config: {"hitl" => {"root_dir" => ".ace-local/hitl"}})
              .create("Q?", questions: ["Q?"])
            assert_nil event.recipient
            assert_nil event.reply_to
          end
        end

        def test_missing_machine_config_fails_before_write_when_recipient_requested
          with_hitl_dir do |root|
            config = {"hitl" => {
              "root_dir" => ".ace-local/hitl",
              "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
            }}
            error = assert_raises(Molecules::HitlAddressResolver::InvalidAddressError) do
              manager(root, config: config).create("Q?", to: "overseer")
            end
            assert_includes error.message, "hitl.machine"
            assert Dir.children(root).empty?
          end
        end

        def test_report_with_to_does_not_require_machine
          with_hitl_dir do |root|
            config = {"hitl" => {
              "root_dir" => ".ace-local/hitl",
              "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
            }}
            event = manager(root, config: config).create("Work done",
              to: "overseer", type: "report", result: "success", body: ["done"])

            assert_equal "lab01", event.recipient["machine"]
            assert_nil event.reply_to
            assert_equal "recorded", event.status
          end
        end

        def test_two_worktrees_each_answer_their_own_event
          with_multi_worktree_roots do |main_root, task_root|
            main_hitl = File.join(main_root, ".ace-local", "hitl")
            task_hitl = File.join(task_root, ".ace-local", "hitl")
            FileUtils.mkdir_p([main_hitl, task_hitl])

            resolver = StaticScopeResolver.new(default_scope: "current",
              current_worktree_root: task_root,
              roots_by_scope: {"current" => [task_root], "all" => [main_root, task_root]})
            main_resolver = StaticScopeResolver.new(default_scope: "current",
              current_worktree_root: main_root,
              roots_by_scope: {"current" => [main_root], "all" => [main_root, task_root]})

            config = address_config
            main_manager = HitlManager.new(root_dir: main_hitl, config: config, scope_resolver: main_resolver)
            task_manager = HitlManager.new(root_dir: task_hitl, config: config, scope_resolver: resolver)

            first = main_manager.create("Main question", questions: ["A?"])
            second = task_manager.create("Task question", questions: ["B?"])

            task_manager.update(second.id, answer: "answer for task")
            main_manager.update(first.id, answer: "answer for main")

            reloaded_first = main_manager.show(first.id)[:event]
            reloaded_second = task_manager.show(second.id, scope: "current")[:event]
            assert_equal "answer for main", reloaded_first.answer
            assert_equal "answer for task", reloaded_second.answer
          end
        end

        def test_repeated_shortcut_is_ambiguous_and_writes_no_answer
          with_hitl_dir do |root|
            create_hitl_fixture(root, id: "aaa123", slug: "first-question")
            create_hitl_fixture(root, id: "bbb123", slug: "second-question")

            config = {"hitl" => {"root_dir" => root}}
            mgr = HitlManager.new(root_dir: root, config: config)

            error = assert_raises(HitlManager::AmbiguousReferenceError) do
              mgr.update("123", answer: "stray answer")
            end
            assert_includes error.message, "123"

            mgr.list(in_folder: "all").each do |event|
              refute_includes File.read(event.file_path), "stray answer"
            end
          end
        end

        def test_missing_id_is_not_found_and_writes_nothing
          with_hitl_dir do |root|
            manager(root).create("Real question", questions: ["A?"])

            result = manager(root).update("zzz999", answer: "stray answer")
            assert_nil result

            manager(root).list(in_folder: "all").each do |event|
              content = File.read(event.file_path)
              refute_includes content, "stray answer"
            end
          end
        end
      end
    end
  end
end
