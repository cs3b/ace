# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::TypeDetectorTest < Minitest::Test
  def test_detects_skill_md
    assert_equal :skill, detect("path/to/SKILL.md")
    assert_equal :skill, detect("path/to/skill.md")
    assert_equal :skill, detect("path/to/Skill.md")
    assert_equal :skill, detect("path/to/SKILLS.md")
    assert_equal :skill, detect("path/to/Skills.md")
  end

  def test_detects_workflow_wf_md
    assert_equal :workflow, detect("path/to/commit.wf.md")
    assert_equal :workflow, detect("path/to/COMMIT.WF.MD")
    assert_equal :workflow, detect("path/to/my-workflow.wf.md")
  end

  def test_detects_agent_ag_md
    assert_equal :agent, detect("path/to/search.ag.md")
    assert_equal :agent, detect("path/to/SEARCH.AG.MD")
    assert_equal :agent, detect("path/to/my-agent.ag.md")
  end

  def test_regular_markdown_not_affected
    assert_equal :markdown, detect("path/to/README.md")
    assert_equal :markdown, detect("path/to/docs/guide.md")
    assert_equal :markdown, detect("path/to/CHANGELOG.md")
  end

  def test_ruby_files
    assert_equal :ruby, detect("path/to/file.rb")
    assert_equal :ruby, detect("Gemfile")
    assert_equal :ruby, detect("Rakefile")
  end

  def test_yaml_files
    assert_equal :yaml, detect("path/to/config.yml")
    assert_equal :yaml, detect("path/to/config.yaml")
  end

  def test_unknown_extension
    assert_equal :unknown, detect("path/to/file.txt")
  end

  def test_has_frontmatter
    content_with_fm = "---\ntitle: Test\n---\n\nBody"
    content_without_fm = "# Just markdown"

    assert Ace::Lint::Atoms::TypeDetector.has_frontmatter?(content_with_fm)
    refute Ace::Lint::Atoms::TypeDetector.has_frontmatter?(content_without_fm)
  end

  private

  def detect(path)
    Ace::Lint::Atoms::TypeDetector.detect(path)
  end
end
