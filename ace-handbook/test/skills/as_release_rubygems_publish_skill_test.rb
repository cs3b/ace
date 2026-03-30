# frozen_string_literal: true

require_relative "../test_helper"
require "date"

module Ace
  module Handbook
    module Skills
      class AsReleaseRubygemsPublishSkillTest < TestCase
        def test_allows_gem_and_bundle_commands_required_by_publish_workflow
          skill_path = File.expand_path("../../handbook/skills/as-release-rubygems-publish/SKILL.md", __dir__)
          frontmatter = YAML.safe_load(
            File.read(skill_path).split(/^---\s*$/.freeze)[1],
            permitted_classes: [Date]
          )
          allowed_tools = Array(frontmatter["allowed-tools"])

          assert_includes allowed_tools, "Bash(bundle:*)"
          assert_includes allowed_tools, "Bash(gem:*)"
        end
      end
    end
  end
end
