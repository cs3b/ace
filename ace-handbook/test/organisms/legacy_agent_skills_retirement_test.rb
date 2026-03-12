# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Organisms::LegacyAgentSkillsRetirementTest < Minitest::Test
  def test_canonical_inventory_includes_as_e2e_run
    skills = inventory.all.map(&:name)

    assert_includes skills, "as-e2e-run"
  end

  def test_legacy_agent_skills_directory_is_not_present
    refute Dir.exist?(File.join(repo_root, ".agent", "skills"))
  end

  private

  def inventory
    @inventory ||= Ace::Handbook::Organisms::SkillInventory.new(project_root: repo_root)
  end

  def repo_root
    File.expand_path("../../..", __dir__)
  end
end
