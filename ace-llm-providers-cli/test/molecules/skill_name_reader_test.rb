# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

describe Ace::LLM::Providers::CLI::Molecules::SkillNameReader do
  it "extracts names from canonical skill frontmatter with nested metadata" do
    Dir.mktmpdir do |dir|
      skill_dir = File.join(dir, "as-task-plan")
      Dir.mkdir(skill_dir)
      File.write(
        File.join(skill_dir, "SKILL.md"),
        <<~MARKDOWN
          ---
          name: as-task-plan
          description: plan
          user-invocable: true
          allowed-tools:
            - Read
          source: ace-task
          skill:
            kind: workflow
            execution:
              workflow: wfi://task/plan
          assign:
            source: wfi://task/work
          ---
        MARKDOWN
      )

      names = Ace::LLM::Providers::CLI::Molecules::SkillNameReader.new.call(dir)
      assert_equal ["as-task-plan"], names
    end
  end

  it "ignores malformed frontmatter files" do
    Dir.mktmpdir do |dir|
      skill_dir = File.join(dir, "broken-skill")
      Dir.mkdir(skill_dir)
      File.write(File.join(skill_dir, "SKILL.md"), "---\nname: [broken\n---\n")

      names = Ace::LLM::Providers::CLI::Molecules::SkillNameReader.new.call(dir)
      assert_equal [], names
    end
  end
end
