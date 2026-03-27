# frozen_string_literal: true

require "open3"
require "tmpdir"
require "fileutils"

module Ace
  module Demo
    module Molecules
      class GhAssetUploader
        RELEASE_TAG = "demo-assets"
        RELEASE_TITLE = "Demo Assets"
        RELEASE_NOTES = "Auto-generated release for demo GIF hosting"

        def initialize(now: -> { Time.now.to_i }, gh_bin: "gh")
          @now = now
          @gh_bin = gh_bin
        end

        def upload(file_path:, dry_run: false)
          asset_name = stamped_asset_name(file_path)
          if dry_run
            repo = ENV.fetch("GITHUB_REPOSITORY", "OWNER/REPO")
            asset_url = "https://github.com/#{repo}/releases/download/#{RELEASE_TAG}/#{asset_name}"
            return {asset_name: asset_name, asset_url: asset_url, dry_run: true}
          end
          raise ArgumentError, "Recording file not found: #{file_path}" unless File.exist?(file_path)

          repo = repo_name_with_owner
          asset_url = "https://github.com/#{repo}/releases/download/#{RELEASE_TAG}/#{asset_name}"

          ensure_release_exists!

          Dir.mktmpdir("ace_demo_attach") do |tmpdir|
            upload_path = File.join(tmpdir, asset_name)
            FileUtils.cp(file_path, upload_path)
            run_gh!("release", "upload", RELEASE_TAG, upload_path, "--clobber")
          end

          {asset_name: asset_name, asset_url: asset_url, dry_run: false}
        end

        private

        def stamped_asset_name(file_path)
          ext = File.extname(file_path)
          base = File.basename(file_path, ext)
          "#{base}-#{@now.call}#{ext}"
        end

        def repo_name_with_owner
          stdout, stderr, status = Open3.capture3(@gh_bin, "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner")
          raise_auth_if_needed!(stderr)
          raise GhCommandError, "Failed to detect repository: #{stderr.strip}" unless status.success?

          repo = stdout.strip
          raise GhCommandError, "Failed to detect repository" if repo.empty?

          repo
        end

        def ensure_release_exists!
          _stdout, stderr, status = Open3.capture3(@gh_bin, "release", "view", RELEASE_TAG)
          raise_auth_if_needed!(stderr)
          return if status.success?

          return create_release! if stderr.downcase.include?("not found") || stderr.downcase.include?("could not find")

          raise GhUploadError, "Failed to check release '#{RELEASE_TAG}': #{stderr.strip}"
        end

        def create_release!
          run_gh!("release", "create", RELEASE_TAG, "--title", RELEASE_TITLE, "--notes", RELEASE_NOTES)
        end

        def run_gh!(*args)
          _stdout, stderr, status = Open3.capture3(@gh_bin, *args)
          raise_auth_if_needed!(stderr)
          return if status.success?

          raise GhUploadError, "gh #{args.join(" ")} failed: #{stderr.strip}"
        end

        def raise_auth_if_needed!(stderr)
          return unless auth_error?(stderr)

          raise GhAuthenticationError, "gh CLI not authenticated. Run: gh auth login"
        end

        def auth_error?(stderr)
          text = stderr.to_s.downcase
          text.include?("gh auth login") ||
            text.include?("not logged into any github hosts") ||
            text.include?("authentication required") ||
            text.include?("authentication token")
        end
      end
    end
  end
end
