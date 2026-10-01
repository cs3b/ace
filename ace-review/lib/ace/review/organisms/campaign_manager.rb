# frozen_string_literal: true

require "open3"
require "time"
require "ace/b36ts"
require_relative "../atoms/campaign_projection"
require_relative "../molecules/campaign_store"
require_relative "../molecules/campaign_evidence"

module Ace
  module Review
    module Organisms
      # Campaign history authority. Assignment attempts and approvals remain
      # owned by ace-assign; finish produces only a validated local result.
      class CampaignManager
        Contract = Atoms::CampaignContract
        attr_reader :store

        def initialize(repo_root: Dir.pwd, store: nil, revisions: nil, check_evidence: nil)
          @repo_root = File.realpath(repo_root)
          @store = store || Molecules::CampaignStore.new(root: File.join(@repo_root, ".ace-local/review/campaigns"))
          @evidence = Molecules::CampaignEvidence.new(repo_root: @repo_root, check_evidence: check_evidence)
          @live_git = revisions.nil?
          @revisions = revisions || method(:git_revision)
        end

        def start(subject:, contract:, profile: "delivery", policy: nil, predecessor: nil, reason: nil, dry_run: false)
          subject = Contract.subject!(subject)
          Contract.string!(contract, "requirements contract")
          effective = policy || Ace::Review.get("campaign", "profiles", profile)
          raise Contract::Invalid, "unsupported campaign profile #{profile}" unless effective
          effective = Contract.policy!(effective)
          validate_repository({"subject" => subject}, pr_url_for(subject))
          identity = Digest::SHA256.hexdigest(contract)
          store.transaction(dry_run: dry_run) do
            records = store.records
            same = records.find { |r| r["subject"] == subject && r["contract_identity"] == identity }
            if same
              raise Contract::Invalid, "conflicting policy for existing subject/contract" unless same["policy"] == effective
              raise Contract::Invalid, "conflicting predecessor" if predecessor && same["predecessor"] != predecessor
              next projection(same)
            end
            earlier = records.select { |r| r["subject"] == subject }
            previous = if predecessor
              store.read(predecessor)
            elsif !earlier.empty?
              # A linear successor must follow the latest retained contract.
              earlier.find { |r| earlier.none? { |candidate| candidate["predecessor"] == r["id"] } }
            end
            inherited = []
            if previous
              raise Contract::Invalid, "predecessor has incompatible subject" unless previous["subject"] == subject
              if earlier.any? { |candidate| candidate["predecessor"] == previous["id"] }
                raise Contract::Invalid, "predecessor already has a successor; select the active contract"
              end
              Contract.string!(reason, "contract successor reason")
              inherited = Atoms::CampaignProjection.build(previous)["findings"]
            elsif predecessor
              raise Contract::Invalid, "unknown predecessor"
            end
            id = allocate_id(records)
            raise Contract::Invalid, "self-referential predecessor" if predecessor == id
            record = {"id" => id, "subject" => subject, "contract_identity" => identity, "contract" => contract,
              "policy" => effective, "profile" => profile, "created_at" => Time.now.utc.iso8601(6),
              "predecessor" => previous&.dig("id"), "successor_reason" => reason,
              "inherited_findings" => inherited, "assessments" => [], "attempts" => [], "rounds" => [],
              "head_transitions" => []}
            store.write(record) unless dry_run
            projection(record).merge("dry_run" => dry_run)
          end
        end

        def record_round(id, input, dry_run: false)
          Contract.object!(input, "round input")
          unknown = input.keys - %w[attempt_id round_id head base required_scopes scope_identity sessions dispositions approval]
          raise Contract::Invalid, "unknown round fields: #{unknown.join(', ')}" unless unknown.empty?
          attempt_id = Contract.id!(input["attempt_id"], "attempt ID")
          round_id = Contract.id!(input["round_id"], "round ID")
          digest = Contract.digest(input)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            prior = record["attempts"].find { |a| a["attempt_id"] == attempt_id }
            if prior
              raise Contract::Invalid, "conflicting replay of attempt #{attempt_id}" unless prior["input_digest"] == digest
              next projection(record).merge("replayed" => true, "recorded_complete" => prior["completed"])
            end
            binding = round_binding(input, record)
            validate_local_commits(record, binding["head"], binding["base"])
            attempts = record["attempts"].select { |a| a["round_id"] == round_id }
            if attempts.any? { |a| a["binding"] != binding }
              raise Contract::Invalid, "round #{round_id} has conflicting pinned head/base/scopes/policy"
            end
            if record["rounds"].any? { |round| round["round_id"] == round_id }
              raise Contract::Invalid, "completed round #{round_id} is immutable; replay the original attempt"
            end
            raw_sessions = input["sessions"]
            raise Contract::Invalid, "sessions must be an array" unless raw_sessions.is_a?(Array)
            if !raw_sessions.empty? && attempts.empty?
              raise Contract::Invalid, "pin round with an empty attempt before collecting sessions"
            end
            sessions = raw_sessions.map { |session| @evidence.session(session, record: record, binding: binding) }
            paths = sessions.map { |s| s["path"] }
            raise Contract::Invalid, "duplicate session reference" unless paths.uniq == paths
            used = record["rounds"].flat_map { |r| r["sessions"] }.map { |s| s["path"] }
            raise Contract::Invalid, "session already counted in a completed round" unless (used & paths).empty?
            coverage = sessions.select { |s| s["completed"] }.map { |s| s["scope"] }.uniq
            complete = (binding["required_scopes"] - coverage).empty? && sessions.all? { |s| s["completed"] }
            assessments = assess(input["dispositions"], sessions, record)
            approval = input["approval"] && @evidence.approval(input["approval"], record: record,
              binding: binding, sessions: sessions)
            attempt = {"attempt_id" => attempt_id, "round_id" => round_id, "input_digest" => digest,
              "binding" => binding, "sessions" => sessions, "assessments" => assessments,
              "approval" => approval, "completed" => complete, "recorded_at" => Time.now.utc.iso8601(6)}
            record["attempts"] << attempt
            # Verified findings are retained even when another required scope
            # has not completed. Partial work cannot hide a known blocker.
            record["assessments"].concat(assessments)
            observe(record, binding["head"], binding["base"])
            if complete
              round_assessments = record["attempts"].select { |a| a["round_id"] == round_id }.flat_map { |a| a["assessments"] }
              confirmed = round_assessments.any? { |f| %w[high critical].include?(f["priority"]) &&
                f["disposition"] != "invalid" }
              round = attempt.merge("clean" => !confirmed, "policy" => record["policy"])
              record["rounds"] << round
            end
            store.write(record) unless dry_run
            projection(record).merge("recorded_complete" => complete, "dry_run" => dry_run)
          end
        end

        def status(id)
          store.transaction(dry_run: true) { projection(store.read(id)) }
        end

        # Produces a stable artifact snapshot without publishing/committing it.
        # Assignment receipt verification rechecks it against live campaign state.
        def finish(id, dry_run: false)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            begin
              head, base = current_revisions(record)
            rescue Contract::Invalid
              next projection(record).merge("dry_run" => dry_run)
            end
            observe(record, head, base) unless dry_run
            store.write(record) unless dry_run
            projection(record, current: [head, base]).merge("dry_run" => dry_run)
          end
        end

        # Called before collection by the existing review runner. A pinned empty
        # attempt must already exist, so coverage/head/base cannot be invented
        # after model execution. This method itself performs no mutation.
        def collection_base(id, round_id:)
          record = store.read(id)
          attempt = record["attempts"].find { |a| a["round_id"] == round_id }
          raise Contract::Invalid, "pin round #{round_id} before collecting reports" unless attempt
          attempt["binding"]["base"]
        end

        def session_binding(id, round_id:, scope:, preset:, head:, base:, pr_url: nil, subjects: nil, delta_reference_head: nil)
          store.transaction(dry_run: true) do
            record = store.read(id)
            attempt = record["attempts"].find { |a| a["round_id"] == round_id }
            raise Contract::Invalid, "pin round #{round_id} with record-round before collecting reports" unless attempt
            binding = attempt["binding"]
            if record["rounds"].any? { |r| r["round_id"] == round_id }
              raise Contract::Invalid, "round #{round_id} already completed"
            end
            unless binding["required_scopes"].include?(scope) && binding["scope_identity"].dig(scope, "preset") == preset &&
                binding["head"] == head && binding["base"] == base
              raise Contract::Invalid, "review does not match pinned scope/preset/head/base"
            end
            actual_subjects = record["subject"]["pr"] ? ["pr:#{record['subject']['pr']}"] : Array(subjects)
            unless actual_subjects == binding["scope_identity"][scope]["subjects"]
              raise Contract::Invalid, "collected subject differs from pinned scope input"
            end
            unless binding["scope_identity"][scope]["delta_reference_head"] == delta_reference_head
              raise Contract::Invalid, "collected delta reference differs from pinned scope input"
            end
            validate_repository(record, pr_url)
            raise Contract::Invalid, "campaign collection requires committed candidate code" unless clean_candidate?
            {"campaign_id" => id, "contract_identity" => record["contract_identity"], "subject" => record["subject"],
             "round_id" => round_id, "scope" => scope, "head" => head, "base" => base, "scope_identity" => binding["scope_identity"][scope]}
          end
        end

        private

        def round_binding(input, record)
          required = Contract.strings!(input["required_scopes"], "required_scopes")
          unless required == record["policy"]["required_scopes"]
            raise Contract::Invalid, "round must pin every required policy scope"
          end
          scopes = Contract.object!(input["scope_identity"], "scope_identity")
          unless scopes.keys.sort == required.sort && scopes.values.all? { |s| s.is_a?(Hash) }
            raise Contract::Invalid, "scope_identity must pin preset and subjects for every required scope"
          end
          scopes.each do |scope_id, scope|
            raise Contract::Invalid, "unknown scope identity fields" unless (scope.keys - %w[preset subjects delta_reference_head]).empty?
            Contract.string!(scope["preset"], "scope preset")
            subjects = Contract.strings!(scope["subjects"], "scope subjects")
            expected_diff = "diff:#{input['base']}..#{input['head']}"
            if scope_id == "full" && record["subject"]["local_candidate_id"] && subjects != [expected_diff]
              raise Contract::Invalid, "local full scope requires the exact pinned diff selector"
            end
            if subjects.any? { |subject| subject.start_with?("diff:") && subject != expected_diff }
              raise Contract::Invalid, "diff scope must use the exact pinned base and head"
            end
            if scope.key?("delta_reference_head")
              raise Contract::Invalid, "delta scope requires a PR subject" unless record["subject"]["pr"]
              Contract.sha!(scope["delta_reference_head"], "delta reference head")
            end
          end
          {"round_id" => input["round_id"], "head" => Contract.sha!(input["head"], "head"),
           "base" => Contract.sha!(input["base"], "base"), "required_scopes" => required,
           "scope_identity" => scopes, "policy_identity" => Contract.digest(record["policy"])}
        end

        def assess(input, sessions, record)
          raise Contract::Invalid, "dispositions must be an array" unless input.is_a?(Array)
          source = sessions.flat_map { |s| s["findings"] }
          input.each do |assessment|
            Contract.object!(assessment, "assessment")
            Contract.string!(assessment["source_id"], "assessment source ID")
          end
          if input.map { |a| a["source_id"] }.sort != source.map { |f| f["source_id"] }.sort
            raise Contract::Invalid, "every source finding requires exactly one verified disposition"
          end
          previous = Atoms::CampaignProjection.build(record)["findings"].to_h { |f| [f["id"], f] }
          input.map do |assessment|
            finding = source.find { |f| f["source_id"] == assessment["source_id"] }
            canonical = assessment["finding_id"] || finding["source_id"]
            Contract.string!(canonical, "finding ID")
            disposition = case finding["status"]
            when "invalid" then "invalid"
            when "done" then "resolved"
            else "open"
            end
            requested = assessment["disposition"] || disposition
            if requested == "reopened"
              unless previous[canonical] && previous[canonical]["disposition"] == "resolved" &&
                  finding["source_id"] != previous[canonical]["source_id"] && disposition == "open"
                raise Contract::Invalid, "reopening requires a new evidenced occurrence of a resolved finding"
              end
            elsif requested != disposition
              raise Contract::Invalid, "assessment contradicts verified source disposition"
            end
            if canonical != finding["source_id"] && !previous.key?(canonical)
              raise Contract::Invalid, "canonical finding does not exist"
            end
            reason = Contract.string!(assessment["reason"], "assessment reason")
            finding.merge("id" => canonical, "disposition" => requested, "reason" => reason)
          end
        end

        def projection(record, current: nil)
          result = Atoms::CampaignProjection.build(record)
          revision_error = nil
          begin
            head, base = current || current_revisions(record)
          rescue Contract::Invalid => e
            head = base = nil
            revision_error = e.message
          end
          round = record["rounds"].last
          refs = record["attempts"].flat_map do |attempt|
            attempt["sessions"].flat_map { |session| session["artifacts"] } +
              (attempt["approval"] ? [attempt["approval"]["artifact"]] + attempt["approval"]["artifacts"] : [])
          end + (record["assessments"] + record["inherited_findings"]).map { |finding| finding["artifact"] }
          available, error = @evidence.available?(refs)
          if round && round["approval"] && available
            begin
              rechecked = @evidence.approval(round["approval"]["artifact"], record: record,
                binding: round["binding"], sessions: round["sessions"])
              raise Contract::Invalid, "accepted approval evidence changed" unless rechecked == round["approval"]
            rescue Contract::Invalid => e
              available = false
              error = e.message
            end
          end
          source_head = round&.dig("binding", "head")
          source_base = round&.dig("binding", "base")
          later_attempts = round ? record["attempts"].drop_while { |a| a["attempt_id"] != round["attempt_id"] }.drop(1) : []
          later_high = later_attempts.flat_map { |attempt| attempt["assessments"] }.any? do |finding|
            %w[high critical].include?(finding["priority"]) && finding["disposition"] != "invalid"
          end
          current_evidence = !!round && available && head && base && source_head == head && source_base == base &&
            clean_candidate? && !later_high
          blockers = result["open_findings"].select { |f| %w[critical high].include?(f["priority"]) }
          reasons = []
          reasons << revision_error if revision_error
          reasons << "search has not converged" unless result["search_converged"]
          reasons << "unresolved High/Critical findings" unless blockers.empty?
          reasons << "later confirmed High/Critical requires a completed current review" if later_high
          reasons << (error || "review evidence is stale or incomplete") unless current_evidence
          reasons << "independent current-head approval and executed required checks missing" unless round&.dig("approval")
          result.merge("evidence" => {"valid" => current_evidence, "available" => available,
            "source_head" => source_head, "current_head" => head, "source_base" => source_base,
            "current_base" => base, "reason" => error || revision_error}, "accepted" => reasons.empty?, "reasons" => reasons,
            "result_identity" => Contract.digest({"campaign_id" => record["id"],
              "contract_identity" => record["contract_identity"], "policy" => record["policy"],
              "attempts" => record["attempts"], "assessments" => record["assessments"],
              "current_head" => head, "current_base" => base}))
        end

        def observe(record, head, base)
          last = record["head_transitions"].last
          return if last && last["head"] == head && last["base"] == base
          record["head_transitions"] << {"head" => head, "base" => base, "observed_at" => Time.now.utc.iso8601(6)}
        end

        def validate_local_commits(record, head, base)
          return unless @live_git && record["subject"]["local_candidate_id"]
          [head, base].each do |revision|
            _, status = Open3.capture2("git", "cat-file", "-e", "#{revision}^{commit}",
              chdir: @repo_root, err: File::NULL)
            raise Contract::Invalid, "local campaign revision is not an available Git commit: #{revision}" unless status.success?
          end
        end

        def current_revisions(record)
          if @live_git && record["subject"]["pr"]
            metadata = Molecules::GhPrFetcher.fetch_metadata(record["subject"]["pr"])
            raise Contract::Invalid, metadata[:error] unless metadata[:success]
            value = metadata[:metadata]
            validate_repository(record, value["url"])
            return [Contract.sha!(value["headRefOid"], "live PR head"),
              Contract.sha!(value["baseRefOid"], "live PR base")]
          end
          head, base = @revisions.call("HEAD"), @revisions.call("base", record)
          validate_local_commits(record, head, base) if base
          [head, base]
        end

        def clean_candidate?
          return true unless @live_git
          out, status = Open3.capture2("git", "status", "--porcelain", chdir: @repo_root, err: File::NULL)
          status.success? && out.strip.empty?
        end

        def pr_url_for(subject)
          return nil unless subject["pr"]
          parsed = Ace::Git::Atoms::PrIdentifier.parse(subject["pr"])
          "#{subject['repository'].delete_suffix('/')}/pull/#{parsed.number}"
        end

        def git_revision(ref, record = nil)
          # Local campaigns pin base to the first round. PR campaigns consult
          # only the existing GitHub adapter, with no hidden forge fallback.
          if ref == "base"
            return record["attempts"].first&.dig("binding", "base") || @revisions.call("HEAD") unless record["subject"]["pr"]
            metadata = Molecules::GhPrFetcher.fetch_metadata(record["subject"]["pr"])
            raise Contract::Invalid, metadata[:error] unless metadata[:success]
            return metadata[:metadata]["baseRefOid"]
          end
          out, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo_root, err: File::NULL)
          raise Contract::Invalid, "live repository HEAD unavailable" unless status.success?
          Contract.sha!(out.strip, "live HEAD")
        end

        def validate_repository(record, pr_url)
          subject = record["subject"]
          if subject["pr"]
            unless subject["repository"].start_with?("https://github.com/")
              raise Contract::Invalid, "unsupported PR source; no configured adapter for #{subject['repository']}"
            end
            parsed = Ace::Git::Atoms::PrIdentifier.parse(subject["pr"])
            expected = "#{subject['repository'].delete_suffix('/')}/pull/#{parsed.number}"
            unless subject["repository"].delete_prefix("https://github.com/").delete_suffix("/") == parsed.repo &&
                pr_url == expected
              raise Contract::Invalid, "PR session belongs to a different repository or PR"
            end
          else
            raise Contract::Invalid, "local campaign cannot use PR session" if pr_url
            # local: identity is explicit and validated against the checkout.
            unless subject["repository"] == "local:#{@repo_root}"
              raise Contract::Invalid, "local repository identity must be local:#{@repo_root}"
            end
          end
        end

        def allocate_id(records)
          value = Ace::B36ts.encode(Time.now)
          value = (value.to_i(36) + 1).to_s(36).rjust(6, "0") while records.any? { |r| r["id"] == value }
          value
        end
      end
    end
  end
end
