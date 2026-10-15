# frozen_string_literal: true

require_relative "../../test_helper"
require "yaml"

class DeliverySupervisionPresetsTest < AceAssignTestCase
  PRESET_ROOT = File.expand_path("../../../.ace-defaults/assign/presets", __dir__)
  PRESET_NAMES = %w[supervise-delivery integrate-batch deliver-release close-delivery].freeze

  def test_delivery_presets_load_and_expand_for_multiple_producer_references
    PRESET_NAMES.each do |name|
      preset = Ace::Assign::Atoms::PresetLoader.load(name)

      assert_equal name, preset.fetch("name")
      assert_equal "array", preset.dig("parameters", "taskrefs", "type")
      assert preset.dig("parameters", "taskrefs", "required")

      steps = Ace::Assign::Atoms::PresetExpander.expand(preset, "taskrefs" => %w[t.alpha t.beta])
      refute_empty steps, name
      assert steps.all? { |step| step["parent"].nil? }, "#{name} must reference producers, never reparent them"
      assert_includes steps.join(" "), "t.alpha, t.beta", name
    end
  end

  def test_supervise_delivery_encodes_complete_integration_decision_record
    content = normalized_preset_content("supervise-delivery")

    [
      "ordered eligible set",
      "selected next entry",
      "deferred entries",
      "reason",
      "decision actor",
      "timestamp",
      "policy/plan revision",
      "evidence references"
    ].each { |field| assert_includes content, field }

    assert_includes content, "wait(reference, next-check)"
    assert_includes content, "blocked(provision, owner)"
    assert_includes content, "never completion order"
    assert_includes content, "transiently empty"
    assert_includes content, "never reparent"
    assert_includes content, "no second queue"
  end

  def test_integrate_batch_requires_fresh_exact_head_evidence_after_movement
    content = preset_content("integrate-batch")

    assert_includes content, "exact candidate head SHA"
    assert_includes content, "target branch"
    assert_includes content, "range-diff"
    assert_includes content, "fresh relevant tests"
    assert_includes content, "independent reviewer"
    assert_includes content, "voids prior eligibility"
    assert_includes content, "durable operation reference"
    assert_includes content, "never repeat"
  end

  def test_deliver_release_binds_cut_and_keeps_publication_separate
    content = normalized_preset_content("deliver-release")
    preset = YAML.safe_load_file(File.join(PRESET_ROOT, "deliver-release.yml"))
    placeholder = preset.fetch("steps").find { |step| step.fetch("name") == "publication-authority-placeholder" }

    assert_includes content, "exact accepted source set"
    assert_includes content, "package name and version"
    assert_includes content, "artifact digest"
    assert_includes content, "do not add later merges"
    assert_includes content, "placeholder only"
    assert_includes content, "separate publication authority"
    refute placeholder.key?("workflow")
    refute placeholder.key?("skill")
  end

  def test_close_delivery_preserves_work_and_closes_only_accepted_scope
    content = normalized_preset_content("close-delivery")

    assert_includes content, "preserve accepted evidence"
    assert_includes content, "no surviving writers"
    assert_includes content, "close only the accepted delivery scope"
    assert_includes content, "host-owned root"
    assert_includes content, "producer task status"
    assert_includes content, "delivery tag"
  end

  private

  def preset_content(name)
    File.read(File.join(PRESET_ROOT, "#{name}.yml"))
  end

  def normalized_preset_content(name)
    preset_content(name).downcase.gsub(/\s+/, " ")
  end
end
