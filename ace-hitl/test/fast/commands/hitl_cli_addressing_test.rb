# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module CLI
      module Commands
        class HitlCliAddressingTest < AceHitlTestCase
          ADDRESS_CONFIG = {
            "hitl" => {
              "root_dir" => ".ace-local/hitl",
              "machine" => "lab01",
              "recipients" => {
                "overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"},
                "captain" => {"machine" => "lab02", "panel" => "telegram"}
              }
            }
          }.freeze

          def with_address_root
            with_hitl_dir do |root|
              config = {
                "hitl" => ADDRESS_CONFIG["hitl"].merge("root_dir" => root)
              }
              with_cli_root(root, config: config) do
                yield root
              end
            end
          end

          def test_create_with_to_prints_recipient_and_reply_to
            with_address_root do |root|
              result = run_cli(["create", "Blocked on auth", "--kind", "decision",
                "--to", "overseer", "--task", "8xg.t.sbz.1.1"])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/HITL event created:/, result[:stdout])
              assert_match(/Recipient: lab01\/\.ace-local\/hitl\/[0-9a-z]{6}/, result[:stdout])
              assert_match(/Reply-To: lab01\/#{Regexp.escape(root)}\/[0-9a-z]{6}/, result[:stdout])
            end
          end

          def test_create_with_panel_recipient
            with_address_root do
              result = run_cli(["create", "For the captain", "--to", "captain", "--question", "Q?"])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/Recipient: lab02\/panel\/telegram/, result[:stdout])
            end
          end

          def test_unknown_to_exits_with_error_and_writes_nothing
            with_address_root do |root|
              result = run_cli(["create", "Q?", "--to", "ghost"])
              assert_equal 1, result[:exit_code]
              assert_match(/Unknown HITL recipient 'ghost'/, result[:stderr])
              assert_match(/Configured recipients: captain, overseer/, result[:stderr])
              assert Dir.children(root).empty?
            end
          end

          def test_show_prints_address_lines
            with_address_root do |root|
              created = run_cli(["create", "Blocked", "--to", "overseer", "--question", "Q?"])
              id = created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

              result = run_cli(["show", id])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/Recipient: lab01\/\.ace-local\/hitl\/#{id}/, result[:stdout])
              assert_match(/Reply-To: lab01\/#{Regexp.escape(root)}\/#{id}/, result[:stdout])
            end
          end

          def test_legacy_create_without_to_has_no_address_lines
            with_address_root do
              result = run_cli(["create", "Plain local question", "--question", "Q?"])
              assert_equal 0, result[:exit_code], result[:stderr]
              refute_match(/Recipient:/, result[:stdout])
              refute_match(/Reply-To:/, result[:stdout])
            end
          end

          def test_update_answer_on_foreign_id_writes_nothing
            with_address_root do |root|
              created = run_cli(["create", "Real", "--to", "overseer", "--question", "Q?"])
              id = created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

              result = run_cli(["update", "zzz999", "--answer", "stray"])
              assert_equal 1, result[:exit_code]
              assert_match(/not found/, result[:stderr])

              content = File.read(Dir.glob(File.join(root, "**", "#{id}-*.hitl.s.md")).first)
              refute_includes content, "stray"
            end
          end
        end
      end
    end
  end
end
