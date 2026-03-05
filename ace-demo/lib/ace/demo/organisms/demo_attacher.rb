# frozen_string_literal: true

module Ace
  module Demo
    module Organisms
      class DemoAttacher
        def initialize(uploader: Molecules::GhAssetUploader.new,
                       formatter: Atoms::DemoCommentFormatter,
                       poster: Molecules::DemoCommentPoster.new,
                       clock: -> { Time.now })
          @uploader = uploader
          @formatter = formatter
          @poster = poster
          @clock = clock
        end

        def attach(file:, pr:, dry_run: false)
          raise ArgumentError, "Recording file not found: #{file}" unless File.exist?(file)

          demo_name = File.basename(file, File.extname(file))
          ext = File.extname(file).delete_prefix(".").downcase
          upload = @uploader.upload(file_path: file, dry_run: dry_run)
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
        end
      end
    end
  end
end
