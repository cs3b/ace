# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"

class GettingStartedTapesSmokeTest < AceDemoTestCase
  TAPE_FILES = [
    "ace-task/docs/demo/ace-task-getting-started.tape.yml",
    "ace-retro/docs/demo/ace-retro-getting-started.tape.yml",
    "ace-git-worktree/docs/demo/ace-git-worktree-getting-started.tape.yml",
    "ace-test-runner/docs/demo/ace-test-runner-getting-started.tape.yml"
  ].freeze

  def test_no_placeholder_demo_commands
    all_commands.each do |command|
      refute_includes command, "Demo placeholder"
    end
  end

  def test_no_hard_coded_numeric_demo_ids
    all_commands.each do |command|
      refute_match(/\b001\b/, command)
    end
  end

  def test_task_demo_uses_sandbox_with_git_init
    spec = load_tape("ace-task/docs/demo/ace-task-getting-started.tape.yml")
    setup = Array(spec["setup"]).map(&:to_s)
    assert_includes setup, "sandbox"
    assert_includes setup, "git-init"
  end

  private

  def all_commands
    TAPE_FILES.flat_map do |path|
      spec = load_tape(path)
      Array(spec["scenes"]).flat_map do |scene|
        Array(scene["commands"]).map { |entry| entry["type"].to_s }
      end
    end
  end

  def load_tape(path)
    YAML.safe_load_file(File.expand_path("../../../#{path}", __dir__))
  end
end
