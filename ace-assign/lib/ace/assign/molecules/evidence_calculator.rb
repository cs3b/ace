# frozen_string_literal: true

require "digest"
require "open3"
require "ace/support/fs"

module Ace
  module Assign
    module Molecules
      # Computes exact-head evidence receipts and canonical decision digests for assignment delivery.
      class EvidenceCalculator
        def self.calculate(pr_number: nil, auto_merge: false)
          new.calculate(pr_number: pr_number, auto_merge: auto_merge)
        end

        def calculate(pr_number: nil, auto_merge: false)
          root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current

          if pr_number.nil?
            pr_output, s = Open3.capture2("ace-git", "pr", "--format", "json", chdir: root)
            if s.success?
              begin
                require "json"
                pr_data = JSON.parse(pr_output)
                pr_number = pr_data["number"]
              rescue StandardError
              end
            end
          end

          head, _s = Open3.capture2("git", "rev-parse", "HEAD", chdir: root)
          head = head.to_s.strip

          tree, _s = Open3.capture2("git", "rev-parse", "HEAD^{tree}", chdir: root)
          tree = tree.to_s.strip

          diff_output, _s = Open3.capture2("git", "diff", "HEAD", chdir: root)
          changed_scope_digest = Digest::SHA256.hexdigest(diff_output.to_s)

          review_receipt = evaluate_review_receipt(root, head)
          release_receipt = evaluate_release_receipt(root, head)
          feedback_state = "terminal"

          merge_decision = evaluate_merge_decision(
            auto_merge: auto_merge,
            review_receipt: review_receipt,
            release_receipt: release_receipt,
            feedback_state: feedback_state
          )

          canonical_payload = [
            pr_number || "none",
            head,
            tree,
            changed_scope_digest,
            review_receipt,
            release_receipt,
            feedback_state,
            merge_decision
          ].join(":")

          decision_digest = Digest::SHA256.hexdigest(canonical_payload)

          {
            pr: pr_number || "none",
            head: head,
            tree: tree,
            changed_scope_digest: changed_scope_digest,
            review_receipt: review_receipt,
            release_receipt: release_receipt,
            feedback_state: feedback_state,
            merge_decision: merge_decision,
            decision_digest: decision_digest
          }
        end

        private

        def evaluate_review_receipt(root, current_head)
          session_dir = File.join(root, ".ace-local", "review", "sessions")
          return "missing" unless Dir.exist?(session_dir)

          reviews = Dir.glob(File.join(session_dir, "*", "metadata.yml"))
          return "missing" if reviews.empty?

          latest = reviews.max_by { |f| File.mtime(f) }
          session_dir = File.dirname(latest)
          
          # Review must actually be executed, not just prepared
          return "missing" unless File.exist?(File.join(session_dir, "report.md")) || File.exist?(File.join(session_dir, "report.json"))
          
          begin
            require "yaml"
            metadata = YAML.safe_load_file(latest, permitted_classes: [Time, Date]) || {}
            return "stale" unless metadata["head"] == current_head
          rescue StandardError
            return "missing"
          end

          "current"
        end

        def evaluate_release_receipt(root, current_head)
          session_dir = File.join(root, ".ace-local", "release", "sessions")
          return "missing" unless Dir.exist?(session_dir)

          releases = Dir.glob(File.join(session_dir, "*", "metadata.yml"))
          return "missing" if releases.empty?

          latest = releases.max_by { |f| File.mtime(f) }
          begin
            require "yaml"
            metadata = YAML.safe_load_file(latest, permitted_classes: [Time, Date]) || {}
            return "stale" unless metadata["head"] == current_head
          rescue StandardError
            return "missing"
          end

          "current"
        end

        def evaluate_merge_decision(auto_merge:, review_receipt:, release_receipt:, feedback_state:)
          return "report-only" unless auto_merge

          if review_receipt == "current" && release_receipt == "current" && feedback_state == "terminal"
            "authorized"
          else
            "approval-required"
          end
        end
      end
    end
  end
end
