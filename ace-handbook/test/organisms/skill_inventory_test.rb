# frozen_string_literal: true

require "test_helper"

module Ace
  module Handbook
    module Organisms
      class SkillInventoryTest < Ace::Handbook::TestCase
        def setup
          @project_root = Dir.mktmpdir("ace_handbook_skill_inventory")
        end

        def teardown
          FileUtils.rm_rf(@project_root)
        end

        def test_loads_only_registered_skill_sources
          create_skill_source_registration("registered", "registered-skills")
          registered_path = create_skill("registered-skills", "as-registered", "registered-source")
          create_skill("unregistered-skills", "as-unregistered", "unregistered-source")

          inventory = SkillInventory.new(project_root: @project_root)

          skills = inventory.all

          assert_equal ["as-registered"], skills.map(&:name)
          assert_equal [registered_path], skills.map(&:source_path)
        end

        private

        def create_skill_source_registration(name, relative_path)
          sources_dir = File.join(@project_root, ".ace", "nav", "protocols", "skill-sources")
          FileUtils.mkdir_p(sources_dir)

          File.write(File.join(sources_dir, "#{name}.yml"), {
            "name" => name,
            "type" => "directory",
            "path" => relative_path,
            "priority" => 10
          }.to_yaml)
        end

        def create_skill(root, skill_name, source_name)
          skill_dir = File.join(@project_root, root, skill_name)
          FileUtils.mkdir_p(skill_dir)

          skill_path = File.join(skill_dir, "SKILL.md")
          File.write(skill_path, <<~SKILL)
            ---
            name: #{skill_name}
            source: #{source_name}
            ---

            test body
          SKILL
          skill_path
        end
      end
    end
  end
end
