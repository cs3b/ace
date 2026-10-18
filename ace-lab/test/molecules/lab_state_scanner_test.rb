# frozen_string_literal: true

require "test_helper"


module Ace
  module Lab
    module Molecules
      class LabStateScannerTest < Minitest::Test
        def scan(root)
          LabStateScanner.scan(root: root)
        end

        def test_full_layout_counts_entries
          Dir.mktmpdir do |tmp|
            %w[.ace-tasks/a .ace-tasks/b .ace-tasks/c].each { |dir| FileUtils.mkdir_p(File.join(tmp, dir)) }
            %w[.ace-local/assign/x .ace-local/assign/y].each { |dir| FileUtils.mkdir_p(File.join(tmp, dir)) }
            FileUtils.mkdir_p(File.join(tmp, ".ace-local/hitl/e1"))
            FileUtils.mkdir_p(File.join(tmp, ".ace-wt/wt1"))

            entries = scan(tmp)

            by_key = entries.to_h { |entry| [entry[:key], entry] }
            assert_equal :present, by_key["tasks"][:state]
            assert_equal 3, by_key["tasks"][:entries]
            assert_equal 2, by_key["assignments"][:entries]
            assert_equal 1, by_key["hitl"][:entries]
            assert_equal 1, by_key["worktrees"][:entries]
          end
        end

        def test_absent_directories_are_absent_with_path
          Dir.mktmpdir do |tmp|
            entries = scan(tmp)

            by_key = entries.to_h { |entry| [entry[:key], entry] }
            assert_equal :absent, by_key["tasks"][:state]
            assert_equal ".ace-tasks", by_key["tasks"][:path]
            assert_nil by_key["tasks"][:entries]
          end
        end

        def test_private_locations_report_presence_only
          Dir.mktmpdir do |tmp|
            %w[.ace-tasks/_overseer/s1 .ace-tasks/_overseer/s2].each { |dir| FileUtils.mkdir_p(File.join(tmp, dir)) }
            FileUtils.mkdir_p(File.join(tmp, ".ace-local/coworker"))

            by_key = scan(tmp).to_h { |entry| [entry[:key], entry] }

            assert_equal :prepared, by_key["overseer"][:state]
            assert_nil by_key["overseer"][:entries]
            assert_equal "private; not listed", by_key["overseer"][:note]
            assert_equal :prepared, by_key["coworker"][:state]
            assert_nil by_key["coworker"][:entries]
          end
        end

        def test_unreadable_location_is_error_without_masking_siblings
          Dir.mktmpdir do |tmp|
            FileUtils.mkdir_p(File.join(tmp, ".ace-tasks/ok"))
            blocked = File.join(tmp, ".ace-local/hitl")
            FileUtils.mkdir_p(blocked)
            File.chmod(0o000, blocked)
            begin
              entries = scan(tmp)
            ensure
              File.chmod(0o755, blocked)
            end

            by_key = entries.to_h { |entry| [entry[:key], entry] }
            if by_key["hitl"][:state] == :present
              skip "platform ignores directory read permission"
            end
            assert_equal :error, by_key["hitl"][:state]
            assert_equal :present, by_key["tasks"][:state]
          end
        end

        def test_covers_all_state_owner_locations
          keys = LabStateScanner::LOCATIONS.map { |location| location[:key] }

          assert_equal %w[tasks overseer assignments hitl worktrees coworker], keys
        end
      end
    end
  end
end
