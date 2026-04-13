# frozen_string_literal: true

require "test_helper"
require "ace/docs/cli/commands/status"
require "ace/docs/models/document"

module Ace
  module Docs
    module CLI
      module Commands
        class StatusTest < Minitest::Test
          def setup
            @command = Status.new
          end

          def test_format_date_with_date_object
            date = Date.new(2025, 11, 10)
            result = @command.send(:format_date, date)

            # Should display date-only format
            assert_match(/2025-11-10/, result)
            # Should calculate days ago
            assert_match(/\d+d ago/, result)
          end

          def test_format_date_with_time_object_iso8601
            time = Time.utc(2025, 11, 10, 14, 30, 45)
            result = @command.send(:format_date, time)

            # Should display ISO 8601 UTC format
            assert_match(/2025-11-10T14:30:45Z/, result)
            # Should calculate days ago
            assert_match(/\d+d ago/, result)
          end

          def test_format_date_no_crash_with_time
            # This test ensures we don't crash with TypeError when doing date math
            time = Time.now.utc

            # Should not raise any errors - just call it and verify result
            result = @command.send(:format_date, time)
            assert_kind_of String, result
            assert_match(/T\d{2}:\d{2}:\d{2}Z/, result) # Should have ISO 8601 time component
          end

          def test_format_date_with_nil
            result = @command.send(:format_date, nil)
            assert_equal "-", result
          end

          def test_format_date_preserves_time_precision
            # When given a Time object, should show full timestamp
            time = Time.utc(2025, 11, 15, 8, 30, 0)
            result = @command.send(:format_date, time)

            # Should include the time component
            assert_match(/T08:30:00Z/, result)

            # When given a Date object, should show date only
            date = Date.new(2025, 11, 15)
            result = @command.send(:format_date, date)

            # Should NOT include time component
            refute_match(/T\d{2}:\d{2}:\d{2}Z/, result)
            # Strip ANSI color codes before matching
            plain_result = result.gsub(/\e\[\d+(;\d+)*m/, "")
            assert_match(/^2025-11-15/, plain_result)
          end

          def test_format_date_color_coding_today
            # Should show green for today
            date = Date.today
            result = @command.send(:format_date, date)

            # Should contain "today"
            assert_match(/today/, result)
            # Should be colorized green (colorize gem uses \e[0;32;49m format)
            assert_includes result, "\e[0;32;49m", "Should have green color for today"
          end

          def test_format_date_color_coding_recent
            # 1 day ago should be green
            date = Date.today - 1
            result = @command.send(:format_date, date)

            assert_match(/1d ago/, result)
            assert_includes result, "\e[0;32;49m", "Should have green color for 1 day ago"
          end

          def test_format_date_color_coding_week_old
            # 5 days ago should be yellow
            date = Date.today - 5
            result = @command.send(:format_date, date)

            assert_match(/5d ago/, result)
            assert_includes result, "\e[0;33;49m", "Should have yellow color for 5 days ago"
          end

          def test_format_date_color_coding_old
            # 30 days ago should be red
            date = Date.today - 30
            result = @command.send(:format_date, date)

            assert_match(/30d ago/, result)
            assert_includes result, "\e[0;31;49m", "Should have red color for 30 days ago"
          end
        end
      end
    end
  end
end
