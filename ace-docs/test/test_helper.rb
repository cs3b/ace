# frozen_string_literal: true

require "ace/docs"
require "ace/test_support"
require "open3"

# AceTestCase is now provided by ace-support-test-helpers
# It includes all the helper methods we need

# Test helper methods for fast, isolated tests
# See guide://testing for patterns used here

# Stub ace-nav subprocess calls for prompt loading
# Prevents 150-400ms delay per ace-nav call
def stub_ace_nav_prompts(user_content: "mock user prompt", system_content: "mock system prompt")
  mock_status = Object.new
  mock_status.define_singleton_method(:success?) { true }
  mock_status.define_singleton_method(:exitstatus) { 0 }

  Open3.stub :capture3, ->(cmd, *args) {
    if cmd == "ace-nav" && args[0] =~ /prompt:\/\//
      # Return appropriate mock content based on prompt type
      [args[0].end_with?(".system") ? system_content : user_content, "", mock_status]
    else
      # Fall through for non-ace-nav calls (shouldn't happen in tests)
      raise "Unexpected subprocess call in test: #{cmd} #{args.join(' ')}"
    end
  } do
    yield
  end
end

# Mock DocumentRegistry to prevent expensive file system scanning
# Prevents scanning thousands of markdown files (7134 in ace repo)
def with_mock_registry(documents: [])
  mock_registry = Object.new
  mock_registry.define_singleton_method(:all) { documents }
  mock_registry.define_singleton_method(:by_type) { |*_type| documents }
  mock_registry.define_singleton_method(:find) { |*_path| nil }
  mock_registry.define_singleton_method(:project_root) { Dir.pwd }

  Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
    yield
  end
end

# Stub git diff operations
# Prevents real git operations via DiffOrchestrator
# See guide://mocking-patterns for stubbing rationale
def with_empty_git_diff
  require "ace/git"
  empty_result = Ace::Git::Models::DiffResult.empty
  Ace::Git::Organisms::DiffOrchestrator.stub(:generate, empty_result) do
    yield
  end
end
