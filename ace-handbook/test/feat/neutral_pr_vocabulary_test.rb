# frozen_string_literal: true

require_relative "../test_helper"
require "ace/support/nav/molecules/protocol_scanner"

class NeutralPrVocabularyTest < Ace::Handbook::TestCase
  ROOT = File.expand_path("../../..", __dir__)
  GIT = File.join(ROOT, "ace-git")
  NEW_SKILLS = %w[as-git-pr-create as-git-pr-update].freeze
  OLD_SKILLS = %w[as-github-pr-create as-github-pr-update].freeze

  def test_gem_payload_sources_resolve_only_neutral_pr_names
    # Read the real gem file manifest without building or installing a package.
    spec = Dir.chdir(GIT) { Gem::Specification.load("ace-git.gemspec") }
    refute_nil spec
    scanner = Ace::Support::Nav::Molecules::ProtocolScanner.new
    {"wfi" => ["handbook/workflow-instructions", [".wf.md"], %w[git/pr/create git/pr/update], %w[github/pr/create github/pr/update]],
     "skill" => ["handbook/skills", ["/SKILL.md"], NEW_SKILLS, OLD_SKILLS]}.each do |protocol, (directory, extensions, current, obsolete)|
      source = Ace::Support::Nav::Models::ProtocolSource.new(
        name: "ace-git", type: "directory", path: File.join(GIT, directory), priority: 10)
      config = {"protocol" => protocol, "extensions" => extensions}
      current.each do |name|
        found = scanner.find_resources_in_source_internal(source, config, name)
        assert_equal 1, found.length, name
        relative = found.first.fetch(:path).delete_prefix("#{GIT}/")
        assert_includes spec.files, relative
      end
      obsolete.each do |name|
        assert_empty scanner.find_resources_in_source_internal(source, config, name), name
        refute spec.files.any? { |file| file == "#{directory}/#{name}#{extensions.first}" }
      end
    end
  end

  def test_real_neutral_skills_project_to_agents_and_prune_old_names
    inventory = Ace::Handbook::Organisms::SkillInventory.new(project_root: ROOT).all
    selected = inventory.select { |skill| NEW_SKILLS.include?(skill.name) }
    assert_equal NEW_SKILLS.sort, selected.map(&:name).sort
    assert_empty inventory.select { |skill| OLD_SKILLS.include?(skill.name) }

    Dir.mktmpdir("neutral-pr-projection") do |project|
      OLD_SKILLS.each do |name|
        path = File.join(project, ".agents", "skills", name)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "SKILL.md"), "old generated projection")
      end
      # The actual projection engine receives real canonical documents. The
      # bounded inventory keeps unrelated skills outside this fixture.
      only_selected = Struct.new(:all).new(selected)
      result = Ace::Handbook::Organisms::ProviderSyncer.new(
        project_root: project, inventory: only_selected,
        config: {"sync" => {"providers" => {"enabled" => ["agents"]}}}).sync
      assert_equal ["agents"], result.map { |entry| entry.fetch(:provider) }
      assert_equal 2, result.first.fetch(:removed_entries)
      selected.each do |skill|
        path = File.join(project, ".agents", "skills", skill.name, "SKILL.md")
        document = File.read(path)
        assert_includes document, skill.body.strip
        assert_includes document, "wfi://git/pr/"
      end
      OLD_SKILLS.each { |name| refute File.exist?(File.join(project, ".agents", "skills", name)) }
      refute File.exist?(File.join(project, ".codex"))
      refute File.exist?(File.join(project, ".claude"))
    end
  end
end
