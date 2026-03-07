# frozen_string_literal: true

require_relative "../test_helper"

class CanonicalBlockTransformerTest < AceCompressorTestCase
  def setup
    super
    @transformer = Ace::Compressor::Atoms::CanonicalBlockTransformer.new("docs/vision.md")
  end

  def test_headings_normalize_and_strip_markdown
    blocks = [
      { type: :heading, level: 2, text: "### 1. CLI-First, Agent-Agnostic" },
      { type: :text, text: "**Agents** can run `cli` commands and read [docs](docs.md)." },
      { type: :text, text: "Only keep safe defaults." }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "SEC|cli_first_agent_agnostic"
    assert_includes lines, "FACT|Agents can run cli commands and read docs."
    assert_includes lines, "FACT|Only keep safe defaults."
  end

  def test_lists_become_typed_array_records
    blocks = [
      { type: :heading, level: 1, text: "Why Problems" },
      { type: :list, ordered: false, items: ["Context bloat", "No isolation boundary"] }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "PROBLEMS|[context_bloat,no_isolation_boundary]"
  end

  def test_generic_lists_use_stable_list_record
    blocks = [
      { type: :heading, level: 2, text: "Core Principles" },
      { type: :list, ordered: false, items: ["CLI First", "Transparent & Inspectable"] }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "LIST|core_principles|[cli_first,transparent_inspectable]"
  end

  def test_problem_context_text_can_drive_problems_record
    blocks = [
      { type: :heading, level: 2, text: "Why ACE Exists" },
      { type: :text, text: "Agents can run CLI commands and read files, but they struggle with:" },
      { type: :list, ordered: false, items: ["Context bloat", "No isolation boundary"] }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "PROBLEMS|[context_bloat,no_isolation_boundary]"
  end

  def test_fenced_code_is_typed
    blocks = [
      { type: :heading, level: 2, text: "Example: ace-git-commit" },
      { type: :fenced_code, language: "bash", content: "ace-git-commit -i \"fix auth bug\"\n" },
      { type: :fenced_code, language: "", content: ".ace-defaults/git/commit.yml\nhandbook/prompts/git-commit.system.md\nexe/ace-git-commit\n" },
      { type: :fenced_code, language: "ruby", content: "puts 1\nputs 2\n" }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "EXAMPLE|tool=ace-git-commit"
    assert_includes lines, "CMD|ace-git-commit -i \"fix auth bug\""
    assert_includes lines, "FILES|ace-git-commit|[.ace-defaults/git/commit.yml,handbook/prompts/git-commit.system.md,exe/ace-git-commit]"
    assert_includes lines, "CODE|ruby|puts 1 puts 2"
  end

  def test_prose_example_line_emits_example_record
    blocks = [
      { type: :heading, level: 2, text: "How It Works" },
      { type: :text, text: "**Example: `ace-git-commit`**" }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "EXAMPLE|tool=ace-git-commit"
    refute_includes lines, "FACT|Example: ace-git-commit"
  end

  def test_blockquote_markers_are_removed
    blocks = [
      { type: :heading, level: 1, text: "Vision" },
      { type: :text, text: ">> Agents can read files and run commands." }
    ]

    lines = @transformer.call(blocks)

    assert_includes lines, "SUMMARY|Agents can read files and run commands."
    refute_includes lines, ">"
  end
end
