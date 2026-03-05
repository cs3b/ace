# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class AttachOutputPrinterTest < AceDemoTestCase
  def test_prints_live_output
    out = StringIO.new
    result = {
      dry_run: false,
      asset_name: "demo.gif",
      asset_url: "https://example.test/demo.gif",
      pr: "123",
      comment_body: "comment body"
    }

    Ace::Demo::Atoms::AttachOutputPrinter.print(result, out: out)
    output = out.string

    assert_includes output, "Uploaded: demo.gif -> https://example.test/demo.gif"
    assert_includes output, "Posted demo comment to PR #123"
    refute_includes output, "comment body"
  end

  def test_prints_dry_run_output
    out = StringIO.new
    result = {
      dry_run: true,
      asset_name: "demo.gif",
      asset_url: "https://example.test/demo.gif",
      pr: "123",
      comment_body: "comment body"
    }

    Ace::Demo::Atoms::AttachOutputPrinter.print(result, out: out)
    output = out.string

    assert_includes output, "[dry-run] Would upload: demo.gif"
    assert_includes output, "[dry-run] Would post comment to PR #123:"
    assert_includes output, "comment body"
  end
end
