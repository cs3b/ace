# frozen_string_literal: true
require_relative "../../test_helper"
class PresetTest < DesignTest
  def with_preset(data)
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, ".ace/design/presets"))
      File.write(File.join(root, ".ace/design/presets/custom.yml"), YAML.dump(data))
      Dir.chdir(root) { yield }
    end
  end
  def load_custom(**options)
    Ace::Design::Molecules::Preset.load(name: "custom", surface: "app", **options)
  end
  def test_preset_list_replaces_defaults_and_cli_model_overrides_slots
    with_preset({"concurrency" => 8, "model" => "preset-model", "variants" => [{"id" => "solo", "model" => "slot-model"}]}) do
      resolved = load_custom(model: "caller-model")
      assert_equal 1, resolved["concurrency"]
      assert_equal "caller-model", resolved["preparation_model"]
      assert_equal ["caller-model"], resolved["variants"].map { |s| s["model"] }
    end
  end
  def test_invalid_declarations_are_actionable
    [1, [nil], [], [{"id" => "../outside"}], [{"id" => "a"}, {"id" => "a"}]].each do |slots|
      with_preset({"variants" => slots}) { assert_raises(Ace::Design::Error) { load_custom } }
    end
    with_preset({"intents" => 1, "variants" => [{"id" => "a"}]}) do
      assert_raises(Ace::Design::Error) { load_custom }
    end
    with_preset({"concurrency" => 0, "variants" => [{"id" => "a"}]}) do
      assert_raises(Ace::Design::Error) { load_custom }
    end
    with_preset({"timeout" => -1, "variants" => [{"id" => "a"}]}) do
      assert_raises(Ace::Design::Error) { load_custom }
    end
    with_preset({"variants" => [{"id" => "a", "model" => "codex@good", "execution_preset" => "rw"}]}) do
      assert_raises(Ace::Design::Error) { load_custom }
    end
  end
  def test_fractional_execution_limits_are_rejected_instead_of_truncated
    %w[concurrency timeout].each do |key|
      [1.5, 3.0, "1.5"].each do |value|
        with_preset({key => value, "variants" => [{"id" => "a"}]}) do
          assert_match(/must be an integer/, assert_raises(Ace::Design::Error) { load_custom }.message)
        end
      end
    end
    with_preset({"concurrency" => "2", "timeout" => "30", "variants" => [{"id" => "a"}]}) do
      assert_equal 30, load_custom["timeout"]
    end
  end
  def test_artifact_validation_rejects_missing_shared_reference_and_symlinks
    Dir.mktmpdir do |root|
      File.write(File.join(root, "index.html"), "<h1>Not shared</h1>")
      File.write(File.join(root, "direction.md"), "Direction")
      assert_match(/fixtures/, assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Artifacts.validate_variant(root) }.message)
      File.write(File.join(root, "index.html"), "<script>fetch('../../fixtures.json')</script>")
      File.symlink("index.html", File.join(root, "another.html"))
      assert_match(/Symlinks/, assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Artifacts.validate_variant(root) }.message)
    end
  end
end
