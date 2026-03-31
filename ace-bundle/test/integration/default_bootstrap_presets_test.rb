# frozen_string_literal: true

require_relative "../test_helper"

class DefaultBootstrapPresetsTest < AceTestCase
  def test_default_project_preset_is_section_based_and_generic
    content = File.read(default_preset_path("project"))

    assert_includes content, "sections:"
    refute_includes content, "ace-taskflow"
    refute_includes content, "Coding Agent Workflow Toolkit (Meta)"
  end

  def test_default_bootstrap_presets_load_in_empty_project
    with_temp_dir do
      install_default_bootstrap_presets

      loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: Dir.pwd)
      project_bundle = loader.load_preset("project")
      project_base_bundle = loader.load_preset("project-base")

      assert_nil project_bundle.metadata[:error], "project preset failed: #{project_bundle.metadata[:error]}"
      assert_nil project_base_bundle.metadata[:error], "project-base preset failed: #{project_base_bundle.metadata[:error]}"
      assert (project_bundle.metadata[:errors] || []).empty?, "project preset warnings: #{project_bundle.metadata[:errors]}"
      assert (project_base_bundle.metadata[:errors] || []).empty?, "project-base preset warnings: #{project_base_bundle.metadata[:errors]}"
      assert project_bundle.content.is_a?(String)
      assert project_base_bundle.content.is_a?(String)
    end
  end

  private

  def install_default_bootstrap_presets
    target_dir = File.join(Dir.pwd, ".ace", "bundle", "presets")
    FileUtils.mkdir_p(target_dir)

    %w[project project-base].each do |name|
      FileUtils.cp(default_preset_path(name), File.join(target_dir, "#{name}.md"))
    end
  end

  def default_preset_path(name)
    File.expand_path("../../.ace-defaults/bundle/presets/#{name}.md", __dir__)
  end
end
