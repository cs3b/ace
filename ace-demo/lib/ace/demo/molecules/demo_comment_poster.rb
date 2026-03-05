# frozen_string_literal: true

require "open3"
require "tempfile"

module Ace
  module Demo
    module Molecules
      class DemoCommentPoster
        def initialize(gh_bin: "gh")
          @gh_bin = gh_bin
        end

        def post(pr:, comment_body:, dry_run: false)
          return { dry_run: true } if dry_run

          Tempfile.create(["ace-demo-pr-comment", ".md"]) do |file|
            file.write(comment_body)
            file.flush

            _stdout, stderr, status = Open3.capture3(@gh_bin, "pr", "comment", pr.to_s, "--body-file", file.path)
            raise_auth_if_needed!(stderr)

            unless status.success?
              raise PrNotFoundError, "PR ##{pr} not found" if pr_not_found?(stderr)

              raise GhCommentError, "Failed to post comment to PR ##{pr}: #{stderr.strip}"
            end
          end

          { dry_run: false, posted: true }
        end

        private

        def pr_not_found?(stderr)
          text = stderr.to_s.downcase
          text.include?("could not resolve to a pull request") ||
            text.match?(/pull request[^\n]*not found/)
        end

        def raise_auth_if_needed!(stderr)
          text = stderr.to_s.downcase
          return unless text.include?("gh auth login") ||
                        text.include?("not logged into any github hosts") ||
                        text.include?("authentication required") ||
                        text.include?("authentication token")

          raise GhAuthenticationError, "gh CLI not authenticated. Run: gh auth login"
        end
      end
    end
  end
end
