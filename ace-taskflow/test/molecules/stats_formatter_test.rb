# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/stats_formatter"

class StatsFormatterTest < AceTaskflowTestCase
  def test_task_status_icons_constant
    formatter = Ace::Taskflow::Molecules::StatsFormatter

    assert_equal "⚫", formatter::TASK_STATUS_ICONS["draft"]
    assert_equal "⚪", formatter::TASK_STATUS_ICONS["pending"]
    assert_equal "🟡", formatter::TASK_STATUS_ICONS["in-progress"]
    assert_equal "🟢", formatter::TASK_STATUS_ICONS["done"]
    assert_equal "🔴", formatter::TASK_STATUS_ICONS["blocked"]
  end

  def test_task_status_order_constant
    formatter = Ace::Taskflow::Molecules::StatsFormatter

    assert_includes formatter::TASK_STATUS_ORDER, "draft"
    assert_includes formatter::TASK_STATUS_ORDER, "pending"
    assert_includes formatter::TASK_STATUS_ORDER, "in-progress"
    assert_includes formatter::TASK_STATUS_ORDER, "done"
  end

  def test_idea_status_icons_constant
    formatter = Ace::Taskflow::Molecules::StatsFormatter

    assert_equal "💡", formatter::IDEA_STATUS_ICONS["new"]
    assert_equal "🔄", formatter::IDEA_STATUS_ICONS["refined"]
    assert_equal "✅", formatter::IDEA_STATUS_ICONS["converted"]
  end

  def test_idea_status_order_constant
    formatter = Ace::Taskflow::Molecules::StatsFormatter

    assert_includes formatter::IDEA_STATUS_ORDER, "new"
    assert_includes formatter::IDEA_STATUS_ORDER, "refined"
    assert_includes formatter::IDEA_STATUS_ORDER, "converted"
  end

  def test_formatter_initialization
    with_test_project do |dir|
      Dir.chdir(dir) do
        formatter = Ace::Taskflow::Molecules::StatsFormatter.new

        assert_instance_of Ace::Taskflow::Molecules::StatsFormatter, formatter
      end
    end
  end
end
