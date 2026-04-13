# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class MediaRetimerTest < AceDemoTestCase
  class FakeStatus
    def initialize(success)
      @success = success
    end

    def success?
      @success
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_media_retimer")
    @input = File.join(@tmp, "demo.gif")
    File.write(@input, "GIF89a")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_dry_run_builds_default_output_path
    retimer = Ace::Demo::Molecules::MediaRetimer.new(ffmpeg_bin: "ffmpeg")
    result = retimer.retime(input_path: @input, speed: "4x", dry_run: true)

    assert_equal @input, result[:input_path]
    assert_equal File.join(@tmp, "demo-4x.gif"), result[:output_path]
    assert_equal "4x", result[:speed]
    assert result[:dry_run]
  end

  def test_retimes_with_ffmpeg
    calls = []
    retimer = Ace::Demo::Molecules::MediaRetimer.new(ffmpeg_bin: "ffmpeg")
    Open3.stub(:capture3, proc { |*args|
      calls << args
      ["", "", FakeStatus.new(true)]
    }) do
      result = retimer.retime(input_path: @input, speed: "2x")
      assert_equal File.join(@tmp, "demo-2x.gif"), result[:output_path]
      refute result[:dry_run]
    end

    assert_equal "ffmpeg", calls[0][0]
    assert_equal "-version", calls[0][1]
    assert_equal "ffmpeg", calls[1][0]
    assert_includes calls[1], "-filter_complex"
  end

  def test_raises_when_ffmpeg_missing
    retimer = Ace::Demo::Molecules::MediaRetimer.new(ffmpeg_bin: "ffmpeg")
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::FfmpegNotFoundError) do
        retimer.retime(input_path: @input, speed: "4x")
      end
      assert_includes error.message, "FFmpeg not found"
    end
  end

  def test_raises_for_unsupported_extension
    bad = File.join(@tmp, "demo.txt")
    File.write(bad, "x")
    retimer = Ace::Demo::Molecules::MediaRetimer.new(ffmpeg_bin: "ffmpeg")
    Open3.stub(:capture3, proc { |_a, *_rest| ["", "", FakeStatus.new(true)] }) do
      error = assert_raises(ArgumentError) do
        retimer.retime(input_path: bad, speed: "4x")
      end
      assert_includes error.message, "Unsupported media format"
    end
  end
end
