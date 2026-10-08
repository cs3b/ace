# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/prepared_input"
require "ace/bundle"

module Ace
  module Assign
    class PreparedInputRenderTest < AceAssignTestCase
      def setup
        super
        # Parser unit only: no fetch, capability or authority admission claimed.
        @input = Authority::PreparedInput.allocate
        @selectors = {"mapping_id" => "mapping with space", "assignment_id" => "assignment;echo bad",
          "scope" => "010.020", "attempt_id" => "launch-'literal'"}.freeze
        @input.instance_variable_set(:@descriptor, @selectors)
      end

      def test_actual_shipped_delivery_workflow_keeps_literal_nested_json
        source = File.expand_path("../../../../ace-handbook/handbook/workflow-instructions/handbook/perform-delivery.wf.md", __dir__)
        content = Ace::Bundle::Organisms::BundleLoader.new(base_dir: File.dirname(source)).load_file(source).content
        assert_includes content, "}}"
        refute_includes content, "{{"
        rendered = @input.render(content)
        assert_equal content, rendered
        assert rendered.frozen?
      end

      def test_literal_closing_braces_and_json_are_not_template_openings
        ["}}", '{"target":{"resource":"https://forge.example/repo"}}', "nested }}} end", "{ordinary}"].each do |literal|
          assert_equal literal, @input.render(literal)
        end
      end

      def test_only_original_admitted_tokens_are_shell_quoted_once
        source = @selectors.keys.map { |field| "{{admitted.#{field}}}" }.join(" ")
        rendered = @input.render(source)
        assert_equal @selectors.values, Shellwords.split(rendered)
        assert rendered.frozen?
        @input.instance_variable_set(:@descriptor, @selectors.merge("mapping_id" => "{{unknown}}"))
        assert_equal ["{{unknown}}"], Shellwords.split(@input.render("{{admitted.mapping_id}}"))
      end

      def test_unknown_and_malformed_opened_tokens_refuse
        ["{{unknown}}", "{{scope}}", "{{admitted.project_id}}", "{{ admitted.scope }}", "{{}}",
          "{{admitted.scope", "{{admitted.scope}", "{{admitted.{scope}}", "{{{{admitted.scope}}}}"].each do |text|
          error = assert_raises(AttemptErrors::EvidenceUnavailable, text) { @input.render(text) }
          assert_match(/prepared_input_invalid:/, error.message)
        end
      end

      def test_campaign_child_prompt_uses_registered_phase_and_private_candidate
        execution = {"phase" => "check", "operation" => "lint", "check_name" => "lint",
          "head" => "a" * 40, "base" => "b" * 40}
        definition = Struct.new(:campaign_execution).new(execution)
        work = Struct.new(:definition, :manifest).new(definition, {"context" => [], "steps" => []})
        @input.instance_variable_set(:@work, work)
        @input.instance_variable_set(:@descriptor, @selectors.merge("project_id" => "project"))
        prompt = @input.drive_prompt
        assert_includes prompt, "registered campaign check child"
        assert_includes prompt, "private authenticated parent candidate repository at #{execution.fetch('head')}"
        assert_includes prompt, "actual lint check"
        assert_includes prompt, "campaign null"
        assert_includes prompt, "Do not edit or advance that candidate"
        assert_includes prompt, "CURRENT_CANDIDATE"
        assert_includes prompt, "REVIEWED_CANDIDATE"
        assert prompt.frozen?
      end
    end
  end
end
