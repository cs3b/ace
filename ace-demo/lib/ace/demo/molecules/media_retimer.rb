# frozen_string_literal: true

require "open3"
require "pathname"
require "fileutils"

module Ace
  module Demo
    module Molecules
      class MediaRetimer
        def initialize(ffmpeg_bin: "ffmpeg")
          @ffmpeg_bin = ffmpeg_bin
        end

        def retime(input_path:, speed:, output_path: nil, dry_run: false)
          raise ArgumentError, "Input file not found: #{input_path}" unless File.exist?(input_path)

          parsed = Atoms::PlaybackSpeedParser.parse(speed)
          raise ArgumentError, "Playback speed is required." unless parsed

          target_path = output_path || default_output_path(input_path, parsed[:label])
          return {input_path: input_path, output_path: target_path, speed: parsed[:label], dry_run: true} if dry_run

          ensure_ffmpeg_available!
          FileUtils.mkdir_p(File.dirname(target_path))

          cmd = build_ffmpeg_command(
            input_path: input_path,
            output_path: target_path,
            factor: parsed[:factor]
          )
          _stdout, stderr, status = Open3.capture3(*cmd)
          raise MediaRetimeError, "FFmpeg retime failed: #{stderr.strip}" unless status.success?

          {input_path: input_path, output_path: target_path, speed: parsed[:label], dry_run: false}
        rescue Errno::ENOENT
          raise FfmpegNotFoundError, "FFmpeg not found. Install ffmpeg to use retime."
        end

        private

        def ensure_ffmpeg_available!
          _stdout, _stderr, status = Open3.capture3(@ffmpeg_bin, "-version")
          return if status.success?

          raise FfmpegNotFoundError, "FFmpeg not found. Install ffmpeg to use retime."
        rescue Errno::ENOENT
          raise FfmpegNotFoundError, "FFmpeg not found. Install ffmpeg to use retime."
        end

        def default_output_path(input_path, speed_label)
          path = Pathname.new(input_path)
          ext = path.extname.downcase
          basename = path.basename(ext).to_s
          File.join(path.dirname.to_s, "#{basename}-#{speed_label}#{ext}")
        end

        def build_ffmpeg_command(input_path:, output_path:, factor:)
          case File.extname(input_path).downcase
          when ".gif"
            [
              @ffmpeg_bin, "-y", "-i", input_path,
              "-filter_complex",
              "[0:v]setpts=PTS/#{factor},split[v][p];[p]palettegen=stats_mode=full[pal];[v][pal]paletteuse=dither=bayer",
              output_path
            ]
          when ".mp4", ".webm"
            [
              @ffmpeg_bin, "-y", "-i", input_path,
              "-filter:v", "setpts=PTS/#{factor}",
              "-an",
              output_path
            ]
          else
            raise ArgumentError, "Unsupported media format: #{File.extname(input_path)}. Use gif, mp4, or webm."
          end
        end
      end
    end
  end
end
