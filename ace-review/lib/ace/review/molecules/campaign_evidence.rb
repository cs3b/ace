# frozen_string_literal: true

require "yaml"
require "date"
require "time"
require "digest"
require "json"
require_relative "../atoms/campaign_contract"
require_relative "feedback_file_reader"
require_relative "campaign_execution_evidence"

module Ace
  module Review
    module Molecules
      # Reads existing execution/session/feedback records. Caller counters and
      # verdict booleans never replace source artifacts. Snapshots are immutable;
      # current currency is rechecked without rewriting historical findings.
      class CampaignEvidence
        Contract = Atoms::CampaignContract

        def initialize(repo_root:, check_evidence: nil, review_evidence: nil, approval_evidence: nil)
          @repo_root = File.realpath(repo_root)
          authority = CampaignExecutionEvidence.new(repo_root: @repo_root)
          @check_evidence = check_evidence || authority.method(:check)
          @review_evidence = review_evidence || authority.method(:review)
          @approval_evidence = approval_evidence || authority.method(:approval)
        end

        def artifact(reference)
          Contract.object!(reference, "artifact reference")
          path = Contract.string!(reference["path"], "artifact path")
          candidate = File.expand_path(path, @repo_root)
          resolved = File.realpath(candidate)
          unless resolved.start_with?(@repo_root + File::SEPARATOR) && File.file?(resolved)
            raise Contract::Invalid, "artifact escapes repository or is not a file: #{path}"
          end
          sha = Digest::SHA256.file(resolved).hexdigest
          raise Contract::Invalid, "artifact checksum mismatch: #{path}" unless reference["sha256"] == sha
          [resolved, {"path" => resolved.delete_prefix(@repo_root + File::SEPARATOR), "sha256" => sha}]
        rescue SystemCallError => e
          raise Contract::Invalid, "artifact unavailable: #{path}: #{e.message}"
        end

        def reference(path)
          artifact("path" => path, "sha256" => Digest::SHA256.file(File.expand_path(path, @repo_root)).hexdigest).last
        rescue SystemCallError => e
          raise Contract::Invalid, "artifact unavailable: #{path}: #{e.message}"
        end

        def session(input, record:, binding:)
          Contract.object!(input, "session")
          scope = Contract.string!(input["scope"], "session scope")
          raise Contract::Invalid, "unknown session scope #{scope}" unless binding["required_scopes"].include?(scope)
          metadata_path, metadata_ref = artifact(input.fetch("metadata"))
          dir = File.dirname(metadata_path)
          raise Contract::Invalid, "session metadata must be metadata.yml" unless File.basename(metadata_path) == "metadata.yml"
          metadata = json_keys(YAML.safe_load_file(metadata_path, permitted_classes: [Time, Date, Symbol]))
          Contract.object!(metadata, "session metadata")
          expected = {"campaign_id" => record["id"], "contract_identity" => record["contract_identity"],
                      "subject" => record["subject"], "round_id" => binding["round_id"], "scope" => scope,
                      "head" => binding["head"], "base" => binding["base"],
                      "scope_identity" => binding["scope_identity"][scope]}
          unless metadata["campaign_binding"] == expected && metadata["preset"] == expected["scope_identity"]["preset"]
            raise Contract::Invalid, "session campaign/contract/scope/head/base identity mismatch"
          end
          unless metadata["head"] == binding["head"]
            raise Contract::Invalid, "session recorded head does not match the pinned head"
          end
          if record["subject"]["pr"] && scope == "full" && !metadata["noop_round"]
            Contract.full_pr_coverage!(metadata["diff_manifest"], head: binding["head"], base: binding["base"],
              delta_reference_head: binding["scope_identity"][scope]["delta_reference_head"])
          end
          refs = [metadata_ref]
          entries = if metadata["models"].is_a?(Array)
            metadata["models"]
          elsif File.file?(File.join(dir, "llm_metadata.yml"))
            refs << reference(File.join(dir, "llm_metadata.yml"))
            [json_keys(YAML.safe_load_file(File.join(dir, "llm_metadata.yml"), permitted_classes: [Time, Date, Symbol]))]
          else
            []
          end
          completed = !metadata["noop_round"] && !entries.empty?
          reports = []
          entries.each do |entry|
            Contract.object!(entry, "model execution")
            execution = entry["execution"] || {}
            complete = entry["status"] == "success" && execution["status"] == "succeeded" &&
              !execution["provider"].to_s.empty? && !execution["model"].to_s.empty? &&
              !entry["completed_at"].to_s.empty?
            next unless complete
            path = entry["output_file"].to_s
            raise Contract::Invalid, "completed execution has no report" if path.empty?
            path = File.expand_path(path, dir)
            unless File.dirname(path) == dir && File.basename(path).match?(/\Areview(?:-.*)?\.md\z/) &&
                !path.end_with?(".prompt.md", ".context.md") && File.basename(path) != "review-dev-feedback.md"
              raise Contract::Invalid, "execution report must be a session review report"
            end
            resolved, report_ref = artifact("path" => path, "sha256" => entry["report_sha256"])
            raise Contract::Invalid, "empty reviewer report" if File.read(resolved).strip.empty?
            refs << report_ref
            reports << {"artifact" => report_ref, "execution" => execution}
            prompts = entry["prompt_sha256"]
            Contract.object!(prompts, "execution prompt checksums")
            %w[system user].each do |name|
              refs << artifact("path" => File.join(dir, "#{name}.prompt.md"), "sha256" => prompts[name]).last
            end
          end
          findings = feedback(dir)
          extraction = metadata["feedback_extraction"]
          extracted = extraction.is_a?(Hash) && extraction["status"] == "succeeded"
          if extracted
            expected_ids = findings.map { |finding| finding["source_id"].split("#").last }.sort
            unless extraction["finding_ids"].is_a?(Array) && extraction["finding_ids"].sort == expected_ids &&
                extraction["report_sha256"].is_a?(Array) &&
                extraction["report_sha256"].sort == reports.map { |report| report["artifact"]["sha256"] }.sort
              raise Contract::Invalid, "feedback extraction inventory or reviewed reports changed"
            end
          end
          # One completed reviewer per needed scope suffices: a failed or
          # incomplete provider entry does not count as a reviewer, but it
          # does not invalidate the model executions that did complete.
          completed &&= reports.any?
          completed &&= extracted
          proof = completed ? @review_evidence.call(input.fetch("receipt"), head: binding["head"], artifacts: refs) : nil
          {"receipt" => input["receipt"], "execution_proof" => proof, "path" => dir.delete_prefix(@repo_root + File::SEPARATOR), "scope" => scope,
           "completed" => completed, "provider_calls" => entries.size,
           "report_files" => reports.size, "reports" => reports, "artifacts" => refs,
           "findings" => findings}
        rescue KeyError, Psych::Exception => e
          raise Contract::Invalid, "invalid session evidence: #{e.message}"
        end

        def feedback(dir)
          Dir.glob(File.join(dir, "feedback", "{*,_archived/*}.s.md"), File::FNM_EXTGLOB).sort.map do |path|
            result = FeedbackFileReader.new.read(path)
            raise Contract::Invalid, result[:error] unless result[:success]
            item = result[:feedback_item]
            if item.id.to_s.empty? || item.finding.to_s.strip.empty? || item.research.to_s.strip.empty? || item.status == "draft"
              raise Contract::Invalid, "unverified feedback: #{path}"
            end
            if item.status == "done" && item.resolution.to_s.strip.empty?
              raise Contract::Invalid, "resolved feedback requires resolution: #{path}"
            end
            {"source_id" => "#{dir.delete_prefix(@repo_root + File::SEPARATOR)}##{item.id}",
             "artifact" => reference(path), "priority" => item.priority, "status" => item.status,
             "title" => item.title, "research" => item.research, "resolution" => item.resolution}
          end
        end

        def verify_session_authority(session, head:, historical: false)
          @review_evidence.call(session.fetch("receipt"), head: head, artifacts: session.fetch("artifacts"), historical: historical)
        end

        def verify_approval_authority(approval, historical: false)
          @approval_evidence.call(approval.fetch("receipt"), head: approval.fetch("head"),
            artifacts: approval.fetch("reports"), producer: approval.fetch("producer"),
            reviewer: approval.fetch("reviewer"), historical: historical)
        end

        def resolution(previous)
          directory = previous["source_id"].split("#", 2).first
          finding = feedback(File.expand_path(directory, @repo_root)).find do |source|
            source["source_id"] == previous["source_id"]
          end
          unless finding && %w[done invalid].include?(finding["status"])
            raise Contract::Invalid, "earlier finding needs a verified terminal source disposition"
          end
          finding.merge("observed_in_round" => false)
        end

        def approval(reference, record:, binding:, sessions:)
          path, normalized = artifact(reference)
          data = JSON.parse(File.read(path))
          Contract.object!(data, "approval")
          unless data["head"] == binding["head"] && data["base"] == binding["base"] &&
              data["contract_identity"] == record["contract_identity"] &&
              data["required_scopes"] == binding["required_scopes"] && data["verdict"] == "approved"
            raise Contract::Invalid, "approval must bind the contract, head, base and all required scopes"
          end
          producer = Contract.string!(data["producer"], "approval producer")
          reviewer = Contract.string!(data["reviewer"], "approval reviewer")
          raise Contract::Invalid, "independent reviewer required (self-approval)" if producer == reviewer
          # Approval explicitly identifies completed reviewer reports, rather
          # than treating a model response or arbitrary file as a verdict.
          review_refs = data["reports"]
          unless review_refs.is_a?(Array) && !review_refs.empty?
            raise Contract::Invalid, "approval must reference executed reviewer reports"
          end
          known = sessions.flat_map { |s| s["reports"] }
          review_refs.each do |ref|
            _, validated = artifact(ref)
            report = known.find { |r| r["artifact"] == validated }
            unless report && report.dig("execution", "model") == reviewer
              raise Contract::Invalid, "approval reviewer/report was not executed in this round"
            end
          end
          approved_scopes = sessions.select do |s|
            s["reports"].any? { |r| review_refs.include?(r["artifact"]) }
          end.map { |s| s["scope"] }.uniq
          unless (binding["required_scopes"] - approved_scopes).empty?
            raise Contract::Invalid, "approval does not cover every required scope"
          end
          approval_receipt = data.fetch("receipt")
          @approval_evidence.call(approval_receipt, head: binding["head"], artifacts: review_refs,
            producer: producer, reviewer: reviewer)
          checks = data["checks"]
          raise Contract::Invalid, "approval requires executed checks" unless checks.is_a?(Array) && !checks.empty?
          check_refs = []
          checks.each do |check|
            Contract.object!(check, "check")
            Contract.string!(check["name"], "check name")
            raise Contract::Invalid, "check did not pass" unless check["verdict"] == "passed"
            accepted = @check_evidence.call(check.fetch("receipt"), head: binding["head"], name: check["name"])
            check_refs.concat(accepted.fetch("artifacts"))
          end
          unless (record["policy"]["required_checks"] - checks.map { |c| c["name"] }).empty?
            raise Contract::Invalid, "missing required checks"
          end
          {"artifact" => normalized, "artifacts" => check_refs + review_refs, "receipt" => approval_receipt,
           "reports" => review_refs, "producer" => producer,
           "reviewer" => reviewer, "head" => binding["head"], "base" => binding["base"], "checks" => checks,
           "verdict" => "approved"}
        rescue JSON::ParserError, KeyError => e
          raise Contract::Invalid, "invalid approval evidence: #{e.message}"
        end

        def available?(refs)
          refs.each { |ref| artifact(ref) }
          [true, nil]
        rescue Contract::Invalid => e
          [false, e.message]
        end

        private

        def json_keys(value)
          case value
          when Hash then value.to_h { |k, v| [k.to_s, json_keys(v)] }
          when Array then value.map { |v| json_keys(v) }
          else value
          end
        end
      end
    end
  end
end
