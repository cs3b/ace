# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"
require "yaml"
require "date"

class CodexRegistryTest < Minitest::Test
  ROOT = File.expand_path("../../../..", __dir__)
  PATHS = ["ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml", ".ace/llm/providers/codex.yml"].freeze
  NEW = %w[gpt-5.6-terra gpt-6-astra gpt-5.6-sol gpt-5.6-luna].freeze
  OLD = %w[gpt-5.3-chat-latest gpt-5.3-codex gpt-5.3-codex-spark gpt-5.4 gpt-5.4-mini gpt-5.4-nano gpt-5.4-pro].freeze

  def test_catalog_parity_exact_entries_aliases_and_unverified_limit_omission
    copies = PATHS.map { |path| File.binread(File.join(ROOT, path)) }
    assert_equal Digest::SHA256.hexdigest(copies[0]), Digest::SHA256.hexdigest(copies[1])
    config = YAML.safe_load(copies[0], permitted_classes: [Date])
    assert_equal NEW + OLD, config["models"]
    assert_equal({"astra" => "gpt-6-astra", "sol" => "gpt-5.6-sol", "terra" => "gpt-5.6-terra",
                  "luna" => "gpt-5.6-luna", "codex" => "gpt-5.6-terra", "gpt" => "gpt-5.6-terra",
                  "mini" => "gpt-5.6-luna", "spark" => "gpt-5.3-codex-spark"}, config.dig("aliases", "model"))
    refute config.key?("context_limit")
    refute config.fetch("limits").key?("default")
    NEW.each { |id| refute config.dig("limits", "models").key?(id) }
    assert_equal OLD.sort, config.dig("limits", "models").keys.sort
  end
end
