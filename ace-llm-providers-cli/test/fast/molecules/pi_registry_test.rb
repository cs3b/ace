# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"
require "yaml"

describe "Pi provider registry" do
  REPO_ROOT = File.expand_path("../../../../", __dir__)
  REGISTRY_PATHS = [
    File.expand_path("../../../.ace-defaults/llm/providers/pi.yml", __dir__),
    File.join(REPO_ROOT, ".ace/llm/providers/pi.yml")
  ].freeze

  LIVE_GLM_TARGETS = [
    "zai/glm-5.3",
    "zai/glm-5.3-flash",
    "zai/glm-5.3-highspeed"
  ].freeze

  it "keeps project and shipped defaults byte-identical" do
    REGISTRY_PATHS.each do |path|
      assert File.exist?(path), "missing registry file: #{path}"
    end

    left = File.binread(REGISTRY_PATHS[0])
    right = File.binread(REGISTRY_PATHS[1])
    assert_equal Digest::SHA256.hexdigest(left), Digest::SHA256.hexdigest(right),
                 "registries diverge"
  end

  it "registers exactly the live GLM 5.3 targets and no obsolete GLM models" do
    config = YAML.safe_load(File.read(REGISTRY_PATHS[0]))
    models = config.fetch("models")

    LIVE_GLM_TARGETS.each do |target|
      assert_includes models, target
    end

    assert models.grep(/glm-(4\.|5\.1|5-turbo)/).empty?, "obsolete GLM models still registered"
  end

  it "configures the flash default and the glm model aliases" do
    config = YAML.safe_load(File.read(REGISTRY_PATHS[0]))
    aliases = config.fetch("aliases")

    assert_equal "pi:zai/glm-5.3-flash", aliases.dig("global", "pi")
    assert_equal "zai/glm-5.3", aliases.dig("model", "glm")
    assert_equal "zai/glm-5.3-flash", aliases.dig("model", "glmflash")
    assert_equal "zai/glm-5.3-highspeed", aliases.dig("model", "glmhighspeed")
    refute aliases.dig("model").key?("glmturbo"), "obsolete GLM alias still active"
  end

  it "resolves aliases and full slash selectors without truncation" do
    require "ace/llm/molecules/client_registry"
    registry = Ace::LLM::Molecules::ClientRegistry.new

    assert_equal "pi:zai/glm-5.3-flash", registry.resolve_alias("pi")
    assert_equal "pi:zai/glm-5.3", registry.resolve_alias("pi:glm")
    assert_equal "pi:zai/glm-5.3-flash", registry.resolve_alias("pi:glmflash")
    assert_equal "pi:zai/glm-5.3-highspeed", registry.resolve_alias("pi:glmhighspeed")

    # Full provider:model selectors must pass through untouched (no truncation)
    LIVE_GLM_TARGETS.each do |target|
      assert_equal "pi:#{target}", registry.resolve_alias("pi:#{target}")
    end
  end
end
