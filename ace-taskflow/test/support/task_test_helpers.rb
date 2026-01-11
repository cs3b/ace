# frozen_string_literal: true

# Domain-specific test helpers for task-related tests
# Extracted from test_helper.rb to keep global namespace clean
module TaskTestHelpers
  # Default release version for test fixtures
  # Can be overridden via TEST_RELEASE environment variable
  TEST_RELEASE = ENV.fetch("ACE_TEST_RELEASE", "v.0.9.0")

  # Test helper for building parent task data fixtures
  # Used across multiple test files for creating mock task objects
  #
  # @param id [Integer, String] Task ID number
  # @param title [String] Task title
  # @param status [String] Task status (default: "pending")
  # @param is_orchestrator [Boolean] Whether task is an orchestrator (default: true)
  # @param release [String] Release version (default: TEST_RELEASE)
  # @param path [String, nil] Optional task path
  # @return [Hash] Task data hash suitable for use with display methods
  #
  # @example Basic usage
  #   parent = build_parent_task(id: 202, title: "Parent Task")
  #   # => { id: "v.0.9.0+task.202", task_number: "202", ... }
  #
  # @example Non-orchestrator parent
  #   parent = build_parent_task(id: 202, title: "Regular Task", is_orchestrator: false)
  def build_parent_task(id:, title:, status: "pending", is_orchestrator: true, release: TEST_RELEASE, path: nil)
    {
      id: "#{release}+task.#{id}",
      task_number: id.to_s,
      release: release,
      title: title,
      status: status,
      is_orchestrator: is_orchestrator,
      path: path || ".ace-taskflow/#{release}/tasks/#{id}-task-placeholder/task.#{id}.md"
    }
  end
end
