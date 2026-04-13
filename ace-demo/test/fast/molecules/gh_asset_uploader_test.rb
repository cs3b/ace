# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class GhAssetUploaderTest < AceDemoTestCase
  class FakeStatus
    def initialize(success, code)
      @success = success
      @code = code
    end

    def success?
      @success
    end

    def exitstatus
      @code
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_uploader")
    @gif_path = File.join(@tmp, "hello.gif")
    File.write(@gif_path, "gif")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_upload_creates_release_when_missing
    call_index = 0
    Open3.stub(:capture3, proc { |_cmd, *args|
      call_index += 1

      case call_index
      when 1
        ["org/repo\n", "", FakeStatus.new(true, 0)]
      when 2
        ["", "release not found", FakeStatus.new(false, 1)]
      when 3
        ["", "", FakeStatus.new(true, 0)]
      when 4
        ["", "", FakeStatus.new(true, 0)]
      else
        raise "unexpected capture3 call: #{args.inspect}"
      end
    }) do
      uploader = Ace::Demo::Molecules::GhAssetUploader.new(now: -> { 1700 })
      result = uploader.upload(file_path: @gif_path)

      assert_equal "hello-1700.gif", result[:asset_name]
      assert_equal "https://github.com/org/repo/releases/download/demo-assets/hello-1700.gif", result[:asset_url]
      assert_equal false, result[:dry_run]
    end
  end

  def test_upload_dry_run_skips_release_upload
    call_index = 0
    Open3.stub(:capture3, proc { |_cmd, *_args|
      call_index += 1
      ["org/repo\n", "", FakeStatus.new(true, 0)]
    }) do
      uploader = Ace::Demo::Molecules::GhAssetUploader.new(now: -> { 1700 })
      result = uploader.upload(file_path: @gif_path, dry_run: true)

      assert_equal true, result[:dry_run]
      assert_equal "hello-1700.gif", result[:asset_name]
      assert_equal 0, call_index
      assert_includes result[:asset_url], "/releases/download/demo-assets/hello-1700.gif"
    end
  end

  def test_upload_raises_auth_error
    Open3.stub(:capture3, proc { |_cmd, *_args|
      ["", "run: gh auth login", FakeStatus.new(false, 1)]
    }) do
      uploader = Ace::Demo::Molecules::GhAssetUploader.new
      error = assert_raises(Ace::Demo::GhAuthenticationError) { uploader.upload(file_path: @gif_path) }
      assert_includes error.message, "gh auth login"
    end
  end

  def test_upload_dry_run_allows_planned_nonexistent_path
    uploader = Ace::Demo::Molecules::GhAssetUploader.new(now: -> { 1700 })
    missing_planned_path = File.join(@tmp, "planned.gif")

    result = uploader.upload(file_path: missing_planned_path, dry_run: true)

    assert_equal true, result[:dry_run]
    assert_equal "planned-1700.gif", result[:asset_name]
  end
end
