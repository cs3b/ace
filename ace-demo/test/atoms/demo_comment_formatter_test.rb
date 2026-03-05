# frozen_string_literal: true

require_relative "../test_helper"
require "time"

class DemoCommentFormatterTest < AceDemoTestCase
  def test_format_generates_markdown_comment
    body = Ace::Demo::Atoms::DemoCommentFormatter.format(
      demo_name: "hello",
      asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-1.gif",
      recorded_at: Time.parse("2026-03-05 12:00:00")
    )

    assert_includes body, "## Demo: hello"
    assert_includes body, "![Demo](https://github.com/org/repo/releases/download/demo-assets/hello-1.gif)"
    assert_includes body, "_Recorded at 2026-03-05 12:00:00_"
  end

  def test_format_uses_link_for_non_gif
    body = Ace::Demo::Atoms::DemoCommentFormatter.format(
      demo_name: "hello",
      asset_url: "https://example.test/hello-1.mp4",
      recorded_at: Time.parse("2026-03-05 12:00:00"),
      format: "mp4"
    )

    assert_includes body, "## Demo: hello"
    assert_includes body, "[hello.mp4](https://example.test/hello-1.mp4)"
    refute_includes body, "![Demo]"
  end
end
