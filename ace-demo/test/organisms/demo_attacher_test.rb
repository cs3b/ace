# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class DemoAttacherTest < AceDemoTestCase
  class StubUploader
    attr_reader :args

    def upload(file_path:, dry_run:)
      @args = { file_path: file_path, dry_run: dry_run }
      {
        asset_name: "hello-1700.gif",
        asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-1700.gif"
      }
    end
  end

  class StubPoster
    attr_reader :args

    def post(pr:, comment_body:, dry_run:)
      @args = { pr: pr, comment_body: comment_body, dry_run: dry_run }
      { posted: !dry_run, dry_run: dry_run }
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_attacher")
    @gif_path = File.join(@tmp, "hello.gif")
    File.write(@gif_path, "gif")
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

  def test_attach_dry_run
    uploader = StubUploader.new
    poster = StubPoster.new

    attacher = Ace::Demo::Organisms::DemoAttacher.new(uploader: uploader, poster: poster)
    result = attacher.attach(file: @gif_path, pr: 123, dry_run: true)

    assert_equal true, result[:dry_run]
    assert_equal true, uploader.args[:dry_run]
    assert_equal true, poster.args[:dry_run]
  end

  def test_attach_requires_existing_file
    attacher = Ace::Demo::Organisms::DemoAttacher.new(
      uploader: StubUploader.new,
      poster: StubPoster.new
    )

    assert_raises(ArgumentError) { attacher.attach(file: File.join(@tmp, "missing.gif"), pr: 123) }
  end
end
