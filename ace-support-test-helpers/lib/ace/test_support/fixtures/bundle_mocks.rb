# frozen_string_literal: true

require "ostruct"
require "yaml"

module Ace
  module TestSupport
    module Fixtures
      # Shared mock fixtures for Ace::Bundle testing
      # Extracted from ace-review/test/test_helper.rb to promote reusability
      module BundleMocks
        # Mock content for context files (>1000 chars for integration tests)
        MOCK_CONTEXT_CONTENT = <<~CONTENT
          # Mock Context for Testing

          Fast test context for code review that avoids expensive shell command execution.

          <format>
          ## Format Guidelines

          Output Formatting Rules:
          - Use clear, structured markdown
          - Include code examples where relevant
          - Maintain consistent formatting
          - Use proper section headers

          Additional formatting instructions that make this content
          substantial enough to pass integration tests that verify
          the context is properly embedded and processed.

          More content to ensure we exceed 1000 characters for
          integration tests that verify prompt generation includes
          all sections and produces substantial output.
          </format>

          <focus>
          ## Documentation Review Focus

          Focus areas for documentation review:
          - Clarity and completeness
          - Code examples accuracy
          - Proper formatting and structure
          - Consistency with style guide

          Additional focus areas and details to ensure comprehensive
          review coverage and sufficient content length.
          </focus>

          <communication>
          ## Communication Style

          Maintain professional, constructive tone in all feedback.
          Provide specific, actionable suggestions for improvement.
          Balance critique with recognition of good practices.

          Additional communication guidelines and best practices
          to ensure effective collaboration and helpful feedback.
          </communication>

          ## Additional Context

          This mock content provides enough substance to satisfy
          integration test requirements while avoiding the 30-second
          delay caused by executing expensive shell commands like
          ace-taskflow queries and recursive directory scans.

          By mocking ace-bundle, we achieve 10x faster test execution
          without sacrificing test coverage or reliability.
        CONTENT

        # Mock git diff content that looks realistic
        MOCK_GIT_DIFF = <<~DIFF
          diff --git a/lib/example.rb b/lib/example.rb
          index abc123..def456 100644
          --- a/lib/example.rb
          +++ b/lib/example.rb
          @@ -1,5 +1,8 @@
           class Example
          +  # Added new method
          +  def new_feature
          +    "implementation"
          +  end
           end
        DIFF

        # Mock staged diff for GitExtractor
        MOCK_STAGED_DIFF = <<~DIFF
          diff --git a/staged.txt b/staged.txt
          new file mode 100644
          index 0000000..abc1234
          --- /dev/null
          +++ b/staged.txt
          @@ -0,0 +1,3 @@
          +Staged change
          +This is a mock staged diff
          +for fast testing
        DIFF

        # Mock working diff for GitExtractor
        MOCK_WORKING_DIFF = <<~DIFF
          diff --git a/working.txt b/working.txt
          index abc1234..def5678 100644
          --- a/working.txt
          +++ b/working.txt
          @@ -1,2 +1,3 @@
           Existing line
          +New unstaged line
          +Another change
        DIFF

        # Creates a mock Ace::Bundle.load_file result
        # @param path [String] The file path (used in mock content)
        # @return [OpenStruct] Mock result with content, metadata, and success
        def self.mock_load_file_result(path)
          mock_content = MOCK_CONTEXT_CONTENT.sub("Testing", File.basename(path))

          OpenStruct.new(
            content: mock_content,
            metadata: {"format" => "markdown-xml"},
            success: true
          )
        end

        # Creates a mock Ace::Bundle.load_auto result
        # @param content [String] The content to process (for frontmatter parsing)
        # @param format [String] The format type (default: "markdown")
        # @return [OpenStruct] Mock result with diff content, metadata, and success
        def self.mock_load_auto_result(content, format: "markdown")
          # Parse YAML frontmatter if present
          config = {}
          if content.start_with?("---") || content.match?(/\A[a-z_]+:/)
            frontmatter = content.split("---").first.strip
            begin
              config = YAML.safe_load(frontmatter, permitted_classes: [Symbol]) || {}
            rescue Psych::SyntaxError
              # Continue with empty config
            end
          end

          OpenStruct.new(
            content: MOCK_GIT_DIFF,
            metadata: {"format" => format, "config" => config},
            success: true
          )
        end

        # Stub Ace::Bundle.load_file to return fast mock data
        # @param original_method_holder [Hash] Hash to store original method for restoration
        # @yield Block where the stub is active
        def self.stub_load_file(original_method_holder = {})
          return unless defined?(Ace::Bundle)

          original_method_holder[:load_file] = Ace::Bundle.method(:load_file) if Ace::Bundle.respond_to?(:load_file)

          Ace::Bundle.define_singleton_method(:load_file) do |path|
            BundleMocks.mock_load_file_result(path)
          end

          yield if block_given?
        ensure
          restore_load_file(original_method_holder) if block_given?
        end

        # Stub Ace::Bundle.load_auto to return fast mock data
        # @param original_method_holder [Hash] Hash to store original method for restoration
        # @yield Block where the stub is active
        def self.stub_load_auto(original_method_holder = {})
          return unless defined?(Ace::Bundle)

          original_method_holder[:load_auto] = Ace::Bundle.method(:load_auto) if Ace::Bundle.respond_to?(:load_auto)

          Ace::Bundle.define_singleton_method(:load_auto) do |content, format: "markdown"|
            BundleMocks.mock_load_auto_result(content, format: format)
          end

          yield if block_given?
        ensure
          restore_load_auto(original_method_holder) if block_given?
        end

        # Stub GitExtractor methods to return fast mock data
        # @param original_method_holder [Hash] Hash to store original methods for restoration
        # @yield Block where the stubs are active
        def self.stub_git_extractor(original_method_holder = {})
          return unless defined?(Ace::Bundle::Atoms::GitExtractor)

          extractor = Ace::Bundle::Atoms::GitExtractor

          original_method_holder[:staged_diff] = extractor.method(:staged_diff) if extractor.respond_to?(:staged_diff)
          original_method_holder[:working_diff] = extractor.method(:working_diff) if extractor.respond_to?(:working_diff)
          original_method_holder[:tracking_branch] = extractor.method(:tracking_branch) if extractor.respond_to?(:tracking_branch)

          # Mock staged_diff
          extractor.define_singleton_method(:staged_diff) do
            MOCK_STAGED_DIFF
          end

          # Mock working_diff
          extractor.define_singleton_method(:working_diff) do
            MOCK_WORKING_DIFF
          end

          # Mock tracking_branch
          extractor.define_singleton_method(:tracking_branch) do
            "origin/main"
          end

          yield if block_given?
        ensure
          restore_git_extractor(original_method_holder) if block_given?
        end

        # Restore original Ace::Bundle.load_file method
        # @param original_method_holder [Hash] Hash containing original method
        def self.restore_load_file(original_method_holder)
          return unless original_method_holder[:load_file]

          Ace::Bundle.define_singleton_method(:load_file, original_method_holder[:load_file])
        end

        # Restore original Ace::Bundle.load_auto method
        # @param original_method_holder [Hash] Hash containing original method
        def self.restore_load_auto(original_method_holder)
          return unless original_method_holder[:load_auto]

          Ace::Bundle.define_singleton_method(:load_auto, original_method_holder[:load_auto])
        end

        # Restore original GitExtractor methods
        # @param original_method_holder [Hash] Hash containing original methods
        def self.restore_git_extractor(original_method_holder)
          return unless defined?(Ace::Bundle::Atoms::GitExtractor)

          extractor = Ace::Bundle::Atoms::GitExtractor

          extractor.define_singleton_method(:staged_diff, original_method_holder[:staged_diff]) if original_method_holder[:staged_diff]
          extractor.define_singleton_method(:working_diff, original_method_holder[:working_diff]) if original_method_holder[:working_diff]
          extractor.define_singleton_method(:tracking_branch, original_method_holder[:tracking_branch]) if original_method_holder[:tracking_branch]
        end
      end
    end
  end
end
