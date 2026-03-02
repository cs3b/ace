# frozen_string_literal: true

require "test_helper"

class RetroDisplayFormatterTest < AceRetroTestCase
  def make_retro(overrides = {})
    Ace::Retro::Models::Retro.new(
      {
        id: "8ppq7w",
        status: "active",
        title: "Sprint Review",
        type: "standard",
        tags: ["sprint"],
        content: "Content here.",
        path: "/tmp/test",
        file_path: "/tmp/test/file.retro.md",
        special_folder: nil,
        created_at: Time.now,
        task_ref: nil,
        folder_contents: [],
        metadata: {}
      }.merge(overrides)
    )
  end

  def test_format_basic
    retro = make_retro
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro)
    assert_includes output, "8ppq7w"
    assert_includes output, "Sprint Review"
    assert_includes output, "<standard>"
  end

  def test_format_with_tags
    retro = make_retro(tags: ["sprint", "team"])
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro)
    assert_includes output, "[sprint, team]"
  end

  def test_format_with_task_ref
    retro = make_retro(task_ref: "292.01")
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro)
    assert_includes output, "292.01"
  end

  def test_format_with_special_folder
    retro = make_retro(special_folder: "_archive")
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro)
    assert_includes output, "(_archive)"
  end

  def test_format_with_content
    retro = make_retro
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro, show_content: true)
    assert_includes output, "Content here."
  end

  def test_format_with_folder_contents
    retro = make_retro(folder_contents: ["report.md", "notes.txt"])
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format(retro)
    assert_includes output, "Files: report.md, notes.txt"
  end

  def test_format_list
    retros = [make_retro, make_retro(id: "9xzr1k", title: "Another")]
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format_list(retros)
    assert_includes output, "8ppq7w"
    assert_includes output, "9xzr1k"
  end

  def test_format_list_empty
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format_list([])
    assert_equal "No retros found.", output
  end

  def test_status_symbols
    active = make_retro(status: "active")
    done = make_retro(status: "done")
    assert_includes Ace::Retro::Molecules::RetroDisplayFormatter.format(active), "🟡"
    assert_includes Ace::Retro::Molecules::RetroDisplayFormatter.format(done), "🟢"
  end

  # --- format_list stats line ---

  def test_format_list_includes_stats_line
    retros = [
      make_retro(id: "aaa111", status: "active"),
      make_retro(id: "bbb222", status: "done"),
      make_retro(id: "ccc333", status: "done")
    ]
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format_list(retros)

    assert_includes output, "Retros: 🟡 1 | 🟢 2 • 3 total • 67% complete"
  end

  def test_format_list_stats_line_omits_zero_counts
    retros = [make_retro(status: "active"), make_retro(status: "active")]
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format_list(retros)

    assert_includes output, "Retros: 🟡 2 • 2 total"
    refute_includes output, "🟢 0"
  end

  def test_format_list_stats_separated_by_blank_line
    retros = [make_retro]
    output = Ace::Retro::Molecules::RetroDisplayFormatter.format_list(retros)

    assert_match(/\n\nRetros:/, output)
  end

  # --- format_stats_line ---

  def test_format_stats_line
    retros = [
      make_retro(status: "active"),
      make_retro(status: "done"),
      make_retro(status: "done")
    ]
    line = Ace::Retro::Molecules::RetroDisplayFormatter.format_stats_line(retros)

    assert_equal "Retros: 🟡 1 | 🟢 2 • 3 total • 67% complete", line
  end
end
