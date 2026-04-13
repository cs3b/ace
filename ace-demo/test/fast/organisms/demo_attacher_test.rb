# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class DemoAttacherTest < AceDemoTestCase
  class StubUploader
    attr_reader :args

    def upload(file_path:, dry_run:)
      @args = {file_path: file_path, dry_run: dry_run}
      {
        asset_name: "hello-1700.gif",
        asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-1700.gif"
      }
    end
  end

  class StubPoster
    attr_reader :args

    def post(pr:, comment_body:, dry_run:)
      @args = {pr: pr, comment_body: comment_body, dry_run: dry_run}
      {posted: !dry_run, dry_run: dry_run}
    end
  end

  class StubAggExecutor
    attr_reader :cmd

    def run(cmd, chdir: nil)
      @cmd = cmd
      output_path = cmd.last
      File.write(output_path, "gif")
      Ace::Demo::Models::ExecutionResult.new(stdout: "ok", stderr: "", success: true, exit_code: 0)
    end
  end

  class FailingAggExecutor
    def run(_cmd, chdir: nil)
      raise Ace::Demo::AggExecutionError, "Agg execution failed: boom"
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_attacher")
    @gif_path = File.join(@tmp, "hello.gif")
    File.write(@gif_path, "gif")
    @cast_path = File.join(@tmp, "hello.cast")
    File.write(@cast_path, "{\"version\":2}\n")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_attach_orchestrates_upload_and_post
    uploader = StubUploader.new
    poster = StubPoster.new

    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: uploader,
      formatter: Ace::Demo::Atoms::DemoCommentFormatter,
      poster: poster,
      clock: -> { Time.new(2026, 3, 5, 12, 0, 0) }
    )

    result = attacher.attach(file: @gif_path, pr: 123)

    assert_equal @gif_path, uploader.args[:file_path]
    assert_equal 123, poster.args[:pr]
    assert_equal false, poster.args[:dry_run]
    assert_includes result[:comment_body], "## Demo: hello"
    assert_equal "hello-1700.gif", result[:asset_name]
  end

  def test_attach_cast_converts_to_gif_before_upload
    uploader = StubUploader.new
    poster = StubPoster.new
    agg_executor = StubAggExecutor.new

    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: uploader,
      formatter: Ace::Demo::Atoms::DemoCommentFormatter,
      poster: poster,
      agg_executor: agg_executor,
      agg_bin: "agg-custom",
      agg_font_family: "Hack Nerd Font Mono",
      clock: -> { Time.new(2026, 3, 5, 12, 0, 0) }
    )

    result = attacher.attach(file: @cast_path, pr: 123)

    assert_match(%r{\A#{Regexp.escape(Dir.tmpdir)}/ace-demo-hello-\d+-[0-9a-f]{6}\.gif\z}, uploader.args[:file_path])
    refute File.exist?(uploader.args[:file_path])
    assert_equal "agg-custom", agg_executor.cmd.first
    assert_includes agg_executor.cmd, "--font-family"
    assert_includes agg_executor.cmd, "Hack Nerd Font Mono"
    assert_equal @cast_path, agg_executor.cmd[-2]
    assert_equal "hello", result[:demo_name]
    assert_includes result[:comment_body], ".gif"
  end

  def test_attach_dry_run
    uploader = StubUploader.new
    poster = StubPoster.new

    attacher = Ace::Demo::Organisms::DemoAttacher.new(uploader: uploader, poster: poster)
    result = attacher.attach(file: @gif_path, pr: 123, dry_run: true)

    assert_equal true, result[:dry_run]
    assert_equal true, uploader.args[:dry_run]
    assert_equal true, poster.args[:dry_run]
  end

  def test_attach_cast_dry_run_skips_conversion_and_uses_planned_gif_name
    uploader = StubUploader.new
    poster = StubPoster.new
    agg_executor = StubAggExecutor.new

    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: uploader,
      formatter: Ace::Demo::Atoms::DemoCommentFormatter,
      poster: poster,
      agg_executor: agg_executor
    )

    result = attacher.attach(file: @cast_path, pr: 123, dry_run: true)

    assert_nil agg_executor.cmd
    assert_equal File.join(@tmp, "hello.gif"), uploader.args[:file_path]
    assert_equal "hello", result[:demo_name]
    assert_equal true, result[:dry_run]
  end

  def test_attach_requires_existing_file
    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: StubUploader.new,
      poster: StubPoster.new
    )

    assert_raises(ArgumentError) { attacher.attach(file: File.join(@tmp, "missing.gif"), pr: 123) }
  end

  def test_attach_cast_raises_when_agg_fails
    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: StubUploader.new,
      poster: StubPoster.new,
      agg_executor: FailingAggExecutor.new
    )

    error = assert_raises(Ace::Demo::AggExecutionError) do
      attacher.attach(file: @cast_path, pr: 123)
    end

    assert_includes error.message, "Agg execution failed"
  end
end
