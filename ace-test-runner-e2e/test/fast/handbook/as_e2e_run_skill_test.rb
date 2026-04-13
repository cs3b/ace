# frozen_string_literal: true

require_relative "../../test_helper"

class AsE2ERunSkillTest < Minitest::Test
  def test_canonical_skill_routes_sandbox_runs_to_execute_workflow
    skill_path = File.expand_path("../../../handbook/skills/as-e2e-run/SKILL.md", __dir__)
    content = File.read(skill_path)

    assert_includes content, "If `$ARGUMENTS` contains `--sandbox`:"
    assert_includes content, "read and run `ace-bundle wfi://e2e/execute`"
  end
end
