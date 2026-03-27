# frozen_string_literal: true

require "tmpdir"

module Ace
  module Demo
    module Organisms
      class DemoAttacher
        def initialize(uploader: Molecules::GhAssetUploader.new,
          formatter: Atoms::DemoCommentFormatter,
          poster: Molecules::DemoCommentPoster.new,
          agg_executor: Molecules::AggExecutor.new,
          agg_bin: Demo.config["agg_bin"],
          agg_font_family: Demo.config["agg_font_family"],
          clock: -> { Time.now })
          @uploader = uploader
          @formatter = formatter
          @poster = poster
          @agg_executor = agg_executor
          @agg_bin = agg_bin || "agg"
          @agg_font_family = agg_font_family
          @clock = clock
        end

        def attach(file:, pr:, dry_run: false)
          raise ArgumentError, "Recording file not found: #{file}" unless File.exist?(file)

          prepared = prepare_upload(file: file, dry_run: dry_run)
          begin
            demo_name = prepared.fetch(:demo_name)
            ext = prepared.fetch(:format)
            upload = @uploader.upload(file_path: prepared.fetch(:file_path), dry_run: dry_run)
            comment_body = @formatter.format(
              demo_name: demo_name,
              asset_url: upload.fetch(:asset_url),
              recorded_at: @clock.call,
              format: ext
            )

            @poster.post(pr: pr, comment_body: comment_body, dry_run: dry_run)

            {
              dry_run: dry_run,
              pr: pr,
              demo_name: demo_name,
              asset_name: upload.fetch(:asset_name),
              asset_url: upload.fetch(:asset_url),
              comment_body: comment_body
            }
          ensure
            cleanup_temporary_file(prepared)
          end
        end

        private

        def prepare_upload(file:, dry_run:)
          return direct_upload(file) unless File.extname(file).downcase == ".cast"
          return cast_upload_plan(cast_path: file) if dry_run

          cast_to_gif(file)
        end

        def direct_upload(file)
          {
            file_path: file,
            demo_name: File.basename(file, File.extname(file)),
            format: File.extname(file).delete_prefix(".").downcase,
            temporary_file: false
          }
        end

        def cast_to_gif(cast_path)
          gif_path = temporary_gif_path(cast_path)
          cmd = Atoms::AggCommandBuilder.build(
            input_path: cast_path,
            output_path: gif_path,
            font_family: @agg_font_family,
            agg_bin: @agg_bin
          )
          @agg_executor.run(cmd)
          {
            file_path: gif_path,
            demo_name: File.basename(cast_path, ".cast"),
            format: "gif",
            temporary_file: true
          }
        end

        def cast_upload_plan(cast_path:)
          {
            file_path: File.join(File.dirname(cast_path), "#{File.basename(cast_path, ".cast")}.gif"),
            demo_name: File.basename(cast_path, ".cast"),
            format: "gif",
            temporary_file: false
          }
        end

        def temporary_gif_path(cast_path)
          basename = File.basename(cast_path, ".cast")
          token = format("%06x", rand(0x1000000))
          File.join(Dir.tmpdir, "ace-demo-#{basename}-#{Process.pid}-#{token}.gif")
        end

        def cleanup_temporary_file(prepared)
          return unless prepared.fetch(:temporary_file, false)

          path = prepared.fetch(:file_path)
          File.delete(path) if File.file?(path)
        end
      end
    end
  end
end
