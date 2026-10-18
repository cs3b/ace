# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class RolePresetLoaderTest < AceCoworkerTestCase
        GEM_ROOT = File.expand_path("../..", __dir__)

        def setup
          super
          @dir = Dir.mktmpdir("coworker-roles")
          @gem_roles = File.join(@dir, "gem-roles")
          FileUtils.mkdir_p(@gem_roles)
          write_preset(@gem_roles, "worker", <<~YAML)
            ---
            name: worker
            description: Gem worker
            instructions: wfi://coworker/worker
            start_prompt: "Drive {{assignment}} as {{role}}."
          YAML
          write_preset(@gem_roles, "spec", <<~YAML)
            ---
            name: spec
            description: Gem spec
            instructions: wfi://coworker/spec
            start_prompt: "Specify {{task}}."
          YAML
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def loader
          RolePresetLoader.new(project_root: @dir, gem_roles_dir: @gem_roles)
        end

        def write_preset(dir, name, content)
          File.write(File.join(dir, "#{name}.yml"), content)
        end

        def test_lists_shipped_presets_sorted_with_sources
          presets = loader.list
          assert_equal %w[spec worker], presets.map { |p| p["name"] }
          assert presets.all? { |p| p["source"] == "gem" }
          worker = presets.last
          assert_equal "wfi://coworker/worker", worker["instructions"]
          assert_equal "Drive {{assignment}} as {{role}}.", worker["start_prompt"]
        end

        def test_project_override_wins_and_adds_roles
          project_roles = File.join(@dir, ".ace", "coworker", "roles")
          FileUtils.mkdir_p(project_roles)
          write_preset(project_roles, "worker", <<~YAML)
            ---
            name: worker
            description: Project worker
            instructions: roles/project-worker.md
            start_prompt: "Project prompt."
          YAML
          write_preset(project_roles, "reviewer", <<~YAML)
            ---
            name: reviewer
            description: Project reviewer
            instructions: wfi://coworker/reviewer
            start_prompt: "Review."
          YAML

          presets = loader.list
          assert_equal %w[reviewer spec worker], presets.map { |p| p["name"] }
          assert_equal "project", presets.last["source"]
          assert_equal "Project worker", presets.last["description"]
          assert_equal "project", presets.first["source"]
          assert_equal "gem", presets[1]["source"]
        end

        def test_fetch_returns_preset_and_unknown_name_lists_available
          assert_equal "gem", loader.fetch("worker")["source"]
          error = assert_raises(Error) { loader.fetch("architect") }
          assert_equal "unknown role 'architect' (available: spec, worker)", error.message
        end

        def test_invalid_preset_file_raises_with_filename
          write_preset(@gem_roles, "broken", <<~YAML)
            ---
            description: no identity
          YAML
          error = assert_raises(Error) { loader.list }
          assert_includes error.message, "invalid role preset"
          assert_includes error.message, "broken.yml"
          assert_includes error.message, "missing required field 'name'"
        end

        def test_name_field_mismatching_filename_raises_naming_both
          write_preset(@gem_roles, "builder", <<~YAML)
            ---
            name: worker
            description: Mislabeled preset
            instructions: wfi://coworker/worker
            start_prompt: "Build."
          YAML
          error = assert_raises(Error) { loader.list }
          assert_includes error.message, "invalid role preset"
          assert_includes error.message, "builder.yml"
          assert_includes error.message, "name field 'worker' must match the filename 'builder.yml'"
        end

        def test_project_override_is_keyed_by_filename_not_name_field
          project_roles = File.join(@dir, ".ace", "coworker", "roles")
          FileUtils.mkdir_p(project_roles)
          # Same filename as the gem preset, different name field: this is an
          # authoring error (caught above), never a silent override bypass.
          write_preset(project_roles, "worker", <<~YAML)
            ---
            name: worker
            description: Project worker
            instructions: roles/project-worker.md
            start_prompt: "Project prompt."
          YAML
          presets = loader.list
          assert_equal "project", presets.find { |p| p["name"] == "worker" }["source"]
        end

        def test_empty_catalog_lists_nothing
          empty_dir = File.join(@dir, "empty")
          FileUtils.mkdir_p(empty_dir)
          assert_empty RolePresetLoader.new(project_root: @dir, gem_roles_dir: empty_dir).list
        end

        def test_shipped_presets_are_valid_and_backed_by_handbook_workflows
          loader = RolePresetLoader.new(project_root: @dir)
          presets = loader.list.map { |p| p["name"] }
          assert_includes presets, "worker"
          assert_includes presets, "spec"

          loader.list.each do |preset|
            instructions = preset["instructions"]
            next unless instructions.start_with?("wfi://coworker/")

            role = instructions.delete_prefix("wfi://coworker/")
            workflow = File.join(GEM_ROOT, "handbook", "workflow-instructions", "coworker", "#{role}.wf.md")
            assert File.file?(workflow), "shipped preset '#{preset['name']}' references missing workflow #{workflow}"
          end
        end
      end
    end
  end
end
