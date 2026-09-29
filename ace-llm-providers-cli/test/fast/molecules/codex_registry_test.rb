# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"
require "yaml"
require "date"

class CodexRegistryTest < Minitest::Test
  ROOT = File.expand_path("../../../..", __dir__)
  PATHS = ["ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml", ".ace/llm/providers/codex.yml"].freeze
  MODELS = %w[gpt-6-sol gpt-6-astra gpt-6-luna].freeze

  def test_catalog_parity_exact_entries_aliases_and_unverified_limit_omission
    copies = PATHS.map { |path| File.binread(File.join(ROOT, path)) }
    assert_equal Digest::SHA256.hexdigest(copies[0]), Digest::SHA256.hexdigest(copies[1])
    config = YAML.safe_load(copies[0], permitted_classes: [Date])
    assert_equal MODELS, config["models"]
    assert_equal({"sol" => "gpt-6-sol", "astra" => "gpt-6-astra", "luna" => "gpt-6-luna",
                  "gpt" => "gpt-6-sol", "codex" => "gpt-6-sol", "mini" => "gpt-6-sol"}, config.dig("aliases", "model"))
    refute config.key?("context_limit")
    refute config.key?("limits")
  end
end
