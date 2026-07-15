# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Molecules::SkillProjectionTest < Minitest::Test
  FakeRegistry = Struct.new(:providers) do
    def known?(provider)
      providers.include?(provider.to_s)
    end
  end

  def test_agents_only_registry_includes_legacy_full_provider_targets
    targets = %w[claude codex gemini opencode pi]

    assert_equal ["agents"], projection_targets(targets, providers: ["agents"])
  end

  def test_agents_only_registry_includes_skills_without_targets
    assert_equal ["agents"], projection_targets(nil, providers: ["agents"])
  end

  def test_agents_only_registry_includes_explicit_agents_target
    assert_equal ["agents"], projection_targets(["agents"], providers: ["agents"])
  end

  def test_agents_only_registry_excludes_narrow_provider_target
    assert_empty projection_targets(["codex"], providers: ["agents"])
  end

  private

  def projection_targets(targets, providers:)
    integration = {}
    integration["targets"] = targets unless targets.nil?

    described_class.projection_targets(
      {"integration" => integration},
      registry: FakeRegistry.new(providers)
    )
  end

  def described_class
    Ace::Handbook::Molecules::SkillProjection
  end
end
