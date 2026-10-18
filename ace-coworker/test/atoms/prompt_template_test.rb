# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class PromptTemplateTest < AceCoworkerTestCase
        def test_renders_all_known_placeholders_from_context
          template = "{{role}} on {{task}} drives {{assignment}}, overseen by {{overseer}}."
          context = {"task" => "8xg.t.sbz.4.0", "assignment" => "abc123", "role" => "worker",
            "overseer" => "overseer@lab"}
          assert_equal "worker on 8xg.t.sbz.4.0 drives abc123, overseen by overseer@lab.",
            PromptTemplate.render(template, context)
        end

        def test_unknown_placeholders_stay_literal
          context = {"task" => "t1", "assignment" => "a1", "role" => "spec", "overseer" => "o1"}
          rendered = PromptTemplate.render("Refine {{spec}} for {{task}} ({{unknown}}).", context)
          assert_equal "Refine {{spec}} for t1 ({{unknown}}).", rendered
        end

        def test_known_placeholder_missing_from_context_renders_empty
          rendered = PromptTemplate.render("Drive {{assignment}} for {{task}}.", {})
          assert_equal "Drive  for .", rendered
        end

        def test_provided_but_empty_values_render_empty
          rendered = PromptTemplate.render("[{{role}}]", {"role" => ""})
          assert_equal "[]", rendered
        end

        def test_render_is_pure_and_strips_surrounding_whitespace
          original = "  Drive {{task}}.  "
          PromptTemplate.render(original, {"task" => "t1"})
          assert_equal "  Drive {{task}}.  ", original
          assert_equal "Drive t1.", PromptTemplate.render(original, {"task" => "t1"})
        end

        def test_values_with_gsub_escape_sequences_render_literally
          sneaky = "back\\slash \\1 \\0 \\& done"
          rendered = PromptTemplate.render("Drive {{task}} as {{role}}.",
            {"task" => sneaky, "assignment" => "a1", "role" => "spec", "overseer" => "o1"})
          assert_equal "Drive back\\slash \\1 \\0 \\& done as spec.", rendered
        end
      end
    end
  end
end
