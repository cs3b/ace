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
        Policy = Atoms::CampaignPolicy
        attr_reader :store

        def initialize(repo_root: Dir.pwd, store: nil, revisions: nil, check_evidence: nil, review_evidence: nil, approval_evidence: nil, artifact_paths: {}, candidate_reader: nil)
          @repo_root = File.realpath(repo_root)
          raise ArgumentError, "canonical candidate cannot use a revision override" if candidate_reader && revisions
          @candidate_reader = candidate_reader
          @store = store || Molecules::CampaignStore.new(root: File.join(@repo_root, ".ace-local/review/campaigns"))
          @evidence = Molecules::CampaignEvidence.new(repo_root: @repo_root, check_evidence: check_evidence, review_evidence: review_evidence, approval_evidence: approval_evidence, artifact_paths: artifact_paths)
          @live_git = revisions.nil?
          @revisions = revisions || method(:git_revision)
        end

        def start(subject:, contract:, profile: "delivery", policy: nil, predecessor: nil, reason: nil, dry_run: false)
          subject = Contract.subject!(subject)
          Contract.string!(contract, "requirements contract")
          effective = policy.nil? ? Ace::Review.get("campaign", "profiles", profile) : policy
          raise Contract::Invalid, "unsupported campaign profile #{profile}" if policy.nil? && effective.nil?
          effective = Contract.policy!(effective)
          bounds = Policy.bounds!(profile: profile, policy: effective)
          validate_repository({"subject" => subject}, pr_url_for(subject))
          identity = Digest::SHA256.hexdigest(contract)
          store.transaction(dry_run: dry_run) do
            records = store.records(subject: subject)
            earlier = records.select { |r| r["subject"] == subject }
            active = earlier.find do |r|
              !r["successor"] && earlier.none? { |candidate| candidate["predecessor"] == r["id"] }
            end
            if !earlier.empty? && !active
              raise Contract::Invalid, "active contract unavailable; restore its retained campaign record"
            end
            same = active if active && active["contract_identity"] == identity
            if same
              raise Contract::Invalid, "conflicting policy for existing subject/contract" unless same["policy"] == effective && same["profile"] == profile
              raise Contract::Invalid, "conflicting predecessor" if predecessor && same["predecessor"] != predecessor
              next projection(same).merge("dry_run" => dry_run)
            end
            previous = predecessor ? store.read(predecessor) : active
            inherited = []
            if previous
              raise Contract::Invalid, "predecessor has incompatible subject" unless previous["subject"] == subject
              if previous["successor"] || earlier.any? { |candidate| candidate["predecessor"] == previous["id"] }
                raise Contract::Invalid, "predecessor already has a successor; select the active contract"
              end
              Contract.string!(reason, "contract successor reason")
              inherited = Atoms::CampaignProjection.build(previous)["findings"]
            elsif predecessor
              raise Contract::Invalid, "unknown predecessor"
            end
            id = allocate_id
            raise Contract::Invalid, "self-referential predecessor" if predecessor == id
            record = {"id" => id, "subject" => subject, "contract_identity" => identity, "contract" => contract,
              "policy" => effective, "profile" => profile, "bounds" => bounds,
              "phases" => [{"id" => "initial", "profile" => profile, "round_start" => 0, "maximum_rounds" => bounds.fetch("maximum_rounds")}],
              "execution_attempts" => [], "created_at" => Time.now.utc.iso8601(6),
              "predecessor" => previous&.dig("id"), "successor_reason" => reason,
              "inherited_findings" => inherited, "assessments" => [], "attempts" => [], "rounds" => [],
              "head_transitions" => []}
            unless dry_run
              if previous
                # Publish supersession first: an interrupted successor write
                # must leave the predecessor blocked, never newly acceptable.
                previous["successor"] = id
                store.write(previous)
              end
              store.write(record)
            end
            projection(record).merge("dry_run" => dry_run)
          end
        end

        def record_round(id, input, dry_run: false, source_digest: nil, expected_campaign: nil, consumer_profiles: nil, before_record: nil)
          Contract.object!(input, "round input")
          unknown = input.keys - %w[attempt_id round_id head base required_scopes scope_identity sessions dispositions approval]
          raise Contract::Invalid, "unknown round fields: #{unknown.join(', ')}" unless unknown.empty?
          attempt_id = Contract.id!(input["attempt_id"], "attempt ID")
          round_id = Contract.id!(input["round_id"], "round ID")
          if source_digest && !(source_digest.is_a?(String) && source_digest.match?(/\A[0-9a-f]{64}\z/))
            raise Contract::Invalid, "round source digest is invalid"
          end
          digest = Contract.digest(source_digest ? {"input" => input, "source_digest" => source_digest} : input)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            if expected_campaign && expected_campaign != {"campaign_id" => record.fetch("id"),
                "subject" => record.fetch("subject"), "contract_identity" => record.fetch("contract_identity"), "policy" => record.fetch("policy")}
              raise Contract::Invalid, "round original campaign differs"
            end
            prior = record["attempts"].find { |a| a["attempt_id"] == attempt_id }
            if prior
              raise Contract::Invalid, "conflicting replay of attempt #{attempt_id}" unless prior["input_digest"] == digest
              next projection(record).merge("replayed" => true, "recorded_complete" => prior["completed"])
            end
            raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
            ensure_review_allowed!(record)
            verify_consumer_policy!(record, consumer_profiles) if consumer_profiles
            before_record.call if before_record
            binding = round_binding(input, record)
            validate_local_commits(record, binding["head"], binding["base"])
            validate_local_full_diff(record, binding["head"], binding["base"])
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
            assessments.each do |finding|
              finding["source_artifact"] = finding["artifact"]
              finding["artifact"] = store.snapshot_finding(finding["artifact"], repo_root: @repo_root, dry_run: dry_run)
            end
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
              confirmed = round_assessments.any? { |f| f["observed_in_round"] && %w[high critical].include?(f["priority"]) &&
                f["disposition"] != "invalid" }
              round = attempt.merge("clean" => !confirmed, "policy" => record["policy"])
              record["rounds"] << round
            end
            store.write(record) unless dry_run
            projection(record).merge("recorded_complete" => complete, "dry_run" => dry_run)
          end
        end

        def resume(id, phase_id:, reason:, route:, additional_rounds:, dry_run: false)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
            if record.fetch("execution_attempts").any? { |entry| %w[running uncertain].include?(entry["status"]) }
              raise Contract::Invalid, "resolve original execution before authorizing a new phase"
            end
            phase = Policy.next_phase(record: record, phase_id: phase_id, reason: reason,
              route: route, additional_rounds: additional_rounds)
            unless record.fetch("phases").any? { |entry| entry["id"] == phase_id }
              unless %w[needs_escalation needs_diagnosis execution_failed].include?(projection(record)["outcome"])
                raise Contract::Invalid, "campaign does not require an authorized next phase"
              end
              record.fetch("phases") << phase
            end
            store.write(record) unless dry_run
            projection(record).merge("dry_run" => dry_run)
          end
        end

        # Explicit audit events use verified retained finding identity and a
        # content-addressed supporting artifact; never create review rounds.
        def assess_finding(id, input, dry_run: false)
          Contract.object!(input, "assessment")
          unless (input.keys - %w[id kind source_id reason artifact priority disposition]).empty? &&
              %w[repair_attempt severity_correction].include?(input["kind"])
            raise Contract::Invalid, "unsupported assessment fields or kind"
          end
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
            known = record.fetch("assessments").reverse.find { |entry| entry["source_id"] == input["source_id"] }
            raise Contract::Invalid, "assessment requires an existing source finding" unless known
            Contract.id!(input["id"], "assessment ID")
            digest = Contract.digest(input)
            prior = record.fetch("assessments").find { |entry| entry["assessment_id"] == input["id"] }
            if prior
              raise Contract::Invalid, "conflicting assessment replay" unless prior["assessment_digest"] == digest
              next projection(record).merge("dry_run" => dry_run, "replayed" => true)
            end
            Contract.string!(input["reason"], "assessment reason")
            event = known.merge(input).merge("id" => known.fetch("id"), "observed_in_round" => false,
              "assessment_id" => input.fetch("id"), "assessment_digest" => digest)
            if input["kind"] == "severity_correction"
              verified = @evidence.reassessment(known)
              unless verified["priority"] == input["priority"] &&
                  input["disposition"] == (verified["status"] == "invalid" ? "invalid" : (verified["status"] == "done" ? "resolved" : "open"))
                raise Contract::Invalid, "severity correction requires verified source disposition and priority"
              end
              event.merge!(verified).merge!("kind" => "severity_correction", "id" => known.fetch("id"),
                "reason" => input.fetch("reason"), "disposition" => input.fetch("disposition"))
            else
              path, reference = @evidence.artifact(input["artifact"])
              raise Contract::Invalid, "repair evidence must be nonempty" if File.size(path).zero?
              event["artifact"] = reference
            end
            event["source_artifact"] = event.fetch("artifact")
            prior = record.fetch("assessments").find { |entry| entry == event }
            unless prior
              event["artifact"] = store.snapshot_finding(event.fetch("artifact"), repo_root: @repo_root, dry_run: dry_run)
              record.fetch("assessments") << event
            end
            store.write(record) unless dry_run || prior
            projection(record).merge("dry_run" => dry_run)
          end
        end

        def reserve_execution(id, round_id:, scope:, provider:, dry_run: false)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            execution_round_projection!(id, round_id, nil)
            unless record.fetch("policy").fetch("required_scopes").include?(scope)
              raise Contract::Invalid, "execution scope is not required"
            end
            selected = record.fetch("execution_attempts").select { |entry| entry["phase_id"] == record.fetch("phases").last.fetch("id") }
            decision = Policy.retry_decision(attempts: selected, round_id: round_id, scope: scope, provider: provider)
            raise Contract::Invalid, "provider execution blocked: #{decision['next_action']}" unless decision["next_action"] == "execute"
            entry = {"id" => "execution-#{record.fetch('execution_attempts').size + 1}",
              "phase_id" => record.fetch("phases").last.fetch("id"), "round_id" => round_id,
              "scope" => scope, "provider" => provider, "status" => "running"}
            record.fetch("execution_attempts") << entry
            store.write(record) unless dry_run
            entry
          end
        end

        def complete_execution(id, execution_id:, status:, failure: nil)
          unless %w[succeeded failed uncertain].include?(status) &&
              (status != "failed" || (Policy::TERMINAL_FAILURES + Policy::TRANSIENT_FAILURES).include?(failure))
            raise Contract::Invalid, "invalid execution completion"
          end
          store.transaction do
            record = store.read(id)
            entry = record.fetch("execution_attempts").find { |attempt| attempt["id"] == execution_id }
            raise Contract::Invalid, "original execution unavailable" unless entry
            if entry["status"] != "running"
              raise Contract::Invalid, "conflicting execution completion" unless entry.values_at("status", "failure") == [status, failure]
            else
              entry.merge!("status" => status, "failure" => failure)
              store.write(record)
            end
            entry
          end
        end

        private def execution_failure(record)
          phase = record.fetch("phases").last.fetch("id")
          entries = record.fetch("execution_attempts").select { |entry| entry["phase_id"] == phase }
          entries.group_by { |entry| entry.values_at("round_id", "scope", "provider") }.each do |selection, attempts|
            round_id, scope, provider = selection
            state = Policy.retry_decision(attempts: attempts, round_id: round_id, scope: scope, provider: provider)
            if %w[terminal_failure retries_exhausted resolve_original_attempt].include?(state["next_action"])
              return "#{state["next_action"]}: #{provider}/#{scope} (#{attempts.last["failure"] || attempts.last["status"]})"
            end
          end
          nil
        end

        private def ensure_review_allowed!(record)
          result = Atoms::CampaignProjection.build(record)
          unless result.fetch("decision").fetch("remaining_rounds").positive?
            raise Contract::Invalid, "campaign round budget exhausted; authorize a next phase"
          end
          unless result.fetch("recurring_blockers").empty?
            phase = record.fetch("phases").last
            raise Contract::Invalid, "recurring blocker requires diagnosis" unless phase["route"] == "diagnosis"
          end
        end

        def status(id, profile: nil)
          store.transaction(dry_run: true) do
            record = store.read(id)
            raise Contract::Invalid, "campaign profile differs" if profile && record["profile"] != profile
            projection(record)
          end
        end

        # Produces a stable artifact snapshot without publishing/committing it.
        # Assignment receipt verification rechecks it against live campaign state.
        def finish(id, dry_run: false, profile: nil)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            raise Contract::Invalid, "campaign profile differs" if profile && record["profile"] != profile
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

        ACCEPTED_SNAPSHOT_FIELDS = %w[accepted base campaign_id contract_identity dry_run effective_policy head prefix producer result_identity reviewer schema subject].freeze

        # Bounded serialization of the same accepted record, not new authority.
        def accepted_result_snapshot(id)
          store.transaction(dry_run: true, require_lock: true) do
            record = store.read(id)
            current = projection(record)
            raise Contract::Invalid, "campaign result is not accepted" unless current["accepted"]
            approval = current.fetch("rounds").last.fetch("approval")
            immutable_projection({"schema" => "ace.review.accepted-result/v1", "campaign_id" => id,
              "accepted" => true, "dry_run" => false, "subject" => current.fetch("subject"),
              "contract_identity" => current.fetch("contract_identity"), "effective_policy" => current.fetch("effective_policy"),
              "head" => current.fetch("evidence").fetch("current_head"), "base" => current.fetch("evidence").fetch("current_base"),
              "producer" => approval.fetch("producer"), "reviewer" => approval.fetch("reviewer"),
              "result_identity" => current.fetch("result_identity"), "prefix" => {
                "attempts" => record.fetch("attempts").length, "rounds" => record.fetch("rounds").length,
                "assessments" => record.fetch("assessments").length,
                "phases" => record.fetch("phases").length, "execution_attempts" => record.fetch("execution_attempts").length}})
          end
        end

        # Hold current campaign authority across the fixed receipt/CAS consumer.
        # Never call a public transaction-owning method from this block.
        def with_verified_result!(result:, subject:, contract_identity:, policy:, head:, base:, producer:, reviewer:, consumer_profiles: nil)
          raise ArgumentError, "verified campaign result requires a block" unless block_given?
          Contract.object!(result, "campaign result")
          subject = Contract.subject!(subject)
          policy = Contract.policy!(policy)
          id = Contract.id!(result["campaign_id"], "campaign ID")
          store.transaction(dry_run: true, require_lock: true) do
            record = store.read(id)
            verify_consumer_policy!(record, consumer_profiles) if consumer_profiles
            current = projection(record)
            approval = current["rounds"].last&.fetch("approval", nil)
            compact = result["schema"] == "ace.review.accepted-result/v1"
            if compact
              prefix = accepted_snapshot_prefix!(record, result)
              unless prefix.values_at("attempts", "rounds", "assessments", "phases", "execution_attempts").map(&:length) == record.values_at("attempts", "rounds", "assessments", "phases", "execution_attempts").map(&:length)
                raise Contract::Invalid, "campaign result prefix is no longer current"
              end
            end
            result_head, result_base = compact ? result.values_at("head", "base") :
              [result.dig("evidence", "current_head"), result.dig("evidence", "current_base")]
            unless result["accepted"] == true && result["dry_run"] == false && current["accepted"] == true &&
                result["result_identity"] == current["result_identity"] &&
                current["subject"] == subject && current["contract_identity"] == contract_identity &&
                current["effective_policy"] == policy &&
                current.dig("evidence", "current_head") == head && current.dig("evidence", "current_base") == base &&
                result_head == head && result_base == base &&
                approval && approval["producer"] == producer && approval["reviewer"] == reviewer
              raise Contract::Invalid, "campaign result does not match current acceptance and expected binding"
            end
            yield immutable_projection(current)
          end
        end

        # Only a canonical accepted receipt consumer uses this historical read.
        # It verifies retained append-only rounds and every original execution;
        # a later campaign successor does not revoke a past accepted receipt.
        def verify_retained_result!(result:, subject:, contract_identity:, policy:, head:, base:, producer:, reviewer:)
          Contract.object!(result, "retained campaign result")
          store.transaction(dry_run: true, require_lock: true) do
            record = store.read(Contract.id!(result["campaign_id"], "campaign ID"))
            snapshot = accepted_snapshot_prefix!(record, result)
            attempts, rounds = snapshot.values_at("attempts", "rounds")
            result_head, result_base = result.values_at("head", "base")
            unless result["accepted"] == true && result["dry_run"] == false &&
                result["result_identity"].is_a?(String) && result["result_identity"].match?(/\A[0-9a-f]{64}\z/) &&
                record.values_at("subject", "contract_identity", "policy") == [subject, contract_identity, policy] &&
                result.values_at("subject", "contract_identity", "effective_policy") == [subject, contract_identity, policy] &&
                result_head == head && result_base == base &&
                attempts.is_a?(Array) && rounds.is_a?(Array) && !rounds.empty? &&
                record.fetch("attempts").first(attempts.length) == attempts && record.fetch("rounds").first(rounds.length) == rounds
              raise Contract::Invalid, "retained campaign result differs from original store evidence"
            end
            approval = rounds.last.fetch("approval")
            unless approval && approval.values_at("producer", "reviewer", "head") == [producer, reviewer, head]
              raise Contract::Invalid, "retained campaign approval actors differ"
            end
            attempts.each do |attempt|
              attempt.fetch("sessions").select { |session| session["completed"] }.each do |session|
                @evidence.verify_session_authority(session, head: attempt.fetch("binding").fetch("head"), historical: true)
              end
              @evidence.verify_approval_authority(attempt.fetch("approval"), historical: true) if attempt["approval"]
            end
            true
          end
        end

        private def accepted_snapshot_prefix!(record, result)
          prefix = result["prefix"]
          unless result.keys.sort == ACCEPTED_SNAPSHOT_FIELDS && result["schema"] == "ace.review.accepted-result/v1" &&
              prefix.is_a?(Hash) && prefix.keys.sort == %w[assessments attempts execution_attempts phases rounds] &&
              prefix.all? { |key, count| count.is_a?(Integer) && count.between?(0, record.fetch(key).length) } &&
              prefix.fetch("rounds").positive? && result["accepted"] == true && result["dry_run"] == false &&
              result.values_at("campaign_id", "subject", "contract_identity", "effective_policy") ==
                record.values_at("id", "subject", "contract_identity", "policy") &&
              %w[head base].all? { |key| result[key].is_a?(String) && result[key].match?(/\A[0-9a-f]{40}\z/) }
            raise Contract::Invalid, "accepted campaign snapshot selectors differ"
          end
          snapshot = record.merge(prefix.to_h { |key, count| [key, record.fetch(key).first(count)] }, "successor" => nil)
          approval = snapshot.fetch("rounds").last.fetch("approval")
          unless approval && approval.values_at("producer", "reviewer", "head") == result.values_at("producer", "reviewer", "head") &&
              result_identity_for(snapshot, result.fetch("head"), result.fetch("base")) == result["result_identity"]
            raise Contract::Invalid, "accepted campaign snapshot identity differs from retained prefix"
          end
          snapshot
        rescue KeyError, TypeError
          raise Contract::Invalid, "accepted campaign snapshot prefix is unavailable"
        end

        private def result_identity_for(record, head, base)
          Contract.digest({"campaign_id" => record["id"], "contract_identity" => record["contract_identity"],
            "policy" => record["policy"], "profile" => record["profile"], "bounds" => record["bounds"],
            "phases" => record["phases"], "execution_attempts" => record["execution_attempts"], "attempts" => record["attempts"], "assessments" => record["assessments"],
            "current_head" => head, "current_base" => base, "successor" => record["successor"]})
        end

        def with_campaign_registration!(id, subject:, contract_identity:, policy:)
          raise ArgumentError, "campaign registration requires a block" unless block_given?
          subject = Contract.subject!(subject)
          policy = Contract.policy!(policy)
          store.transaction(dry_run: true, require_lock: true) do
            record = store.read(id)
            unless !record["successor"] && record["subject"] == subject &&
                record["contract_identity"] == contract_identity && record["policy"] == policy
              raise Contract::Invalid, "campaign registration differs from active contract"
            end
            yield immutable_projection({"campaign_id" => record.fetch("id"), "subject" => record.fetch("subject"),
              "contract_identity" => record.fetch("contract_identity"), "policy" => record.fetch("policy")})
          end
        end

        # Source-owned child registration holds the pinned round while its
        # canonical definition is accepted. Parent lineage is checked by Assign.
        def with_execution_round!(id, round_id:, consumer_profiles: nil)
          raise ArgumentError, "campaign execution round requires a block" unless block_given?
          Contract.id!(round_id, "round ID")
          store.transaction(dry_run: true, require_lock: true) do
            value = execution_round_projection!(id, round_id, consumer_profiles)
            thread = Thread.current
            active = true
            recheck = lambda do
              raise Contract::Invalid, "campaign round guard is not held" unless active && Thread.current.equal?(thread)
              unless execution_round_projection!(id, round_id, consumer_profiles) == value
                raise Contract::Invalid, "campaign round changed during consumption"
              end
              true
            end
            begin
              result = yield value, recheck
              recheck.call
              result
            ensure
              active = false
            end
          end
        end

        private def execution_round_projection!(id, round_id, consumer_profiles)
          record = store.read(id)
          raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
          ensure_review_allowed!(record)
          attempt = record["attempts"].find { |entry| entry["round_id"] == round_id }
          unless attempt && record["rounds"].none? { |entry| entry["round_id"] == round_id }
            raise Contract::Invalid, "campaign execution requires a pinned incomplete round"
          end
          verify_consumer_policy!(record, consumer_profiles) if consumer_profiles
          head, base = current_revisions(record)
          binding = attempt.fetch("binding")
          unless binding.values_at("head", "base") == [head, base] && clean_candidate?
            raise Contract::Invalid, "campaign execution candidate changed"
          end
          immutable_projection({"campaign_id" => record.fetch("id"), "subject" => record.fetch("subject"),
            "contract_identity" => record.fetch("contract_identity"), "policy" => record.fetch("policy"),
            "round_id" => round_id, "binding" => binding})
        rescue KeyError, TypeError
          raise Contract::Invalid, "current campaign consumer policy is unavailable"
        end

        private def verify_consumer_policy!(record, consumer_profiles)
          current = Contract.policy!(consumer_profiles.fetch(record.fetch("profile")))
          recorded = Contract.policy!(record.fetch("policy"))
          unless %w[minimum_rounds clean_rounds].all? { |key| recorded.fetch(key) >= current.fetch(key) } &&
              %w[required_scopes required_checks].all? { |key| (current.fetch(key) - recorded.fetch(key)).empty? }
            raise Contract::Invalid, "campaign policy no longer satisfies current consumer constraints"
          end
        rescue KeyError, TypeError
          raise Contract::Invalid, "current campaign consumer policy is unavailable"
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

        def session_binding(id, round_id:, scope:, preset:, head:, base:, pr_url: nil, subjects: nil, delta_reference_head: nil, diff_manifest: nil, noop: false)
          store.transaction(dry_run: true) do
            record = store.read(id)
            raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
            ensure_review_allowed!(record)
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
            if record["subject"]["pr"] && @revisions.call("HEAD") != head
              raise Contract::Invalid, "campaign PR collection requires checkout HEAD to match fetched PR head"
            end
            actual_subjects = record["subject"]["pr"] ? ["pr:#{record['subject']['pr']}"] : Array(subjects)
            unless actual_subjects == binding["scope_identity"][scope]["subjects"]
              raise Contract::Invalid, "collected subject differs from pinned scope input"
            end
            unless binding["scope_identity"][scope]["delta_reference_head"] == delta_reference_head
              raise Contract::Invalid, "collected delta reference differs from pinned scope input"
            end
            if record["subject"]["pr"] && scope == "full" && !noop
              Contract.full_pr_coverage!(diff_manifest, head: head, base: base, delta_reference_head: delta_reference_head)
            end
            validate_repository(record, pr_url)
            validate_local_full_diff(record, head, base)
            raise Contract::Invalid, "campaign collection requires committed candidate code" unless clean_candidate?
            {"campaign_id" => id, "contract_identity" => record["contract_identity"], "subject" => record["subject"],
             "round_id" => round_id, "scope" => scope, "head" => head, "base" => base, "scope_identity" => binding["scope_identity"][scope]}
          end
        end

        private

        def immutable_projection(value)
          case value
          when Hash then value.each { |key, child| immutable_projection(key); immutable_projection(child) }
          when Array then value.each { |child| immutable_projection(child) }
          end
          value.freeze
        end

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
              raise Contract::Invalid, "full scope cannot use a delta reference" if scope_id == "full"
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
          if sessions.any? { |session| !session["completed"] && !session["findings"].empty? }
            raise Contract::Invalid, "finding assessments require completed accepted review collection"
          end
          source = sessions.flat_map { |s| s["findings"] }.map { |finding| finding.merge("observed_in_round" => true) }
          previous = Atoms::CampaignProjection.build(record)["findings"].to_h { |f| [f["id"], f] }
          input.each do |assessment|
            Contract.object!(assessment, "assessment")
            Contract.string!(assessment["source_id"], "assessment source ID")
          end
          current_ids = source.map { |finding| finding["source_id"] }
          input.reject { |assessment| current_ids.include?(assessment["source_id"]) }.each do |assessment|
            known = previous.values.find { |finding| finding["source_id"] == assessment["source_id"] }
            unless known && %w[open reopened].include?(known["disposition"])
              raise Contract::Invalid, "external disposition must resolve a known open finding"
            end
            if assessment["finding_id"] && assessment["finding_id"] != known["id"]
              raise Contract::Invalid, "earlier resolution targets a different canonical finding"
            end
            source << @evidence.resolution(known).merge("canonical_id" => known["id"])
          end
          if input.map { |a| a["source_id"] }.sort != source.map { |f| f["source_id"] }.sort
            raise Contract::Invalid, "every source finding requires exactly one verified disposition"
          end
          canonical_ids = input.map do |assessment|
            finding = source.find { |item| item["source_id"] == assessment["source_id"] }
            assessment["finding_id"] || finding["canonical_id"] || assessment["source_id"]
          end
          unless canonical_ids.uniq == canonical_ids
            raise Contract::Invalid, "one submission cannot assess a canonical finding more than once"
          end
          input.map do |assessment|
            finding = source.find { |f| f["source_id"] == assessment["source_id"] }
            canonical = assessment["finding_id"] || finding["canonical_id"] || finding["source_id"]
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
          successor = record["successor"]
          revision_error = nil
          begin
            head, base = current || current_revisions(record)
          rescue Contract::Invalid => e
            head = base = nil
            revision_error = e.message
          end
          round = record["rounds"].last
          # Availability re-hashing covers the current round's evidence plus
          # every finding snapshot. Earlier rounds' sessions and approvals are
          # validated by journal-backed historical authority reads instead:
          # their working files legitimately age (feedback resolve archives
          # and annotates finding files; test report `latest` paths move on),
          # so hashing them here would permanently block finish for any
          # campaign that resolved findings. Finding snapshots are
          # content-addressed and must remain available.
          current_attempt_ids = round ? [round["attempt_id"]] : []
          refs = record["attempts"].select { |attempt| current_attempt_ids.include?(attempt["attempt_id"]) }.flat_map do |attempt|
            attempt["sessions"].flat_map { |session| session["artifacts"] } +
              (attempt["approval"] ? [attempt["approval"]["artifact"]] + attempt["approval"]["artifacts"] : [])
          end + (record["assessments"] + record["inherited_findings"]).map { |finding| finding["artifact"] }
          available, error = @evidence.available?(refs)
          if available
            begin
              record["attempts"].each do |attempt|
                attempt["sessions"].select { |session| session["completed"] }.each do |session|
                  historical = !round || attempt["attempt_id"] != round["attempt_id"] ||
                    attempt["binding"]["head"] != head
                  @evidence.verify_session_authority(session, head: attempt["binding"]["head"], historical: historical)
                end
              end
              record["attempts"].each do |attempt|
                next unless attempt["approval"]
                next if round && attempt["attempt_id"] == round["attempt_id"] && attempt["binding"]["head"] == head
                @evidence.verify_approval_authority(attempt["approval"], historical: true)
              end
              if round && round["binding"]["head"] == head && round["approval"]
                rechecked = @evidence.approval(round["approval"]["artifact"], record: record,
                  binding: round["binding"], sessions: round["sessions"])
                raise Contract::Invalid, "accepted approval evidence changed" unless rechecked == round["approval"]
              end
            rescue Contract::Invalid => e
              available = false
              error = e.message
            end
          end
          source_head = round&.dig("binding", "head")
          source_base = round&.dig("binding", "base")
          later_attempts = round ? record["attempts"].drop_while { |a| a["attempt_id"] != round["attempt_id"] }.drop(1) : []
          blocker_ids = (record["assessments"] + record["inherited_findings"]).select do |finding|
            %w[high critical medium].include?(finding["priority"]) && finding["disposition"] != "invalid"
          end.map { |finding| finding["id"] }
          later_blocker_update = later_attempts.flat_map { |attempt| attempt["assessments"] }.any? do |finding|
            blocker_ids.include?(finding["id"])
          end
          current_evidence = !!(round && available && head && base && source_head == head && source_base == base &&
            clean_candidate? && !later_blocker_update)
          blockers = result["open_findings"].select { |f| %w[critical high medium].include?(f["priority"]) }
          reasons = []
          reasons << revision_error if revision_error
          reasons << "campaign contract superseded by #{successor}" if successor
          reasons << "search has not converged" unless result["search_converged"]
          reasons << "unresolved required High/Critical/Medium findings" unless blockers.empty?
          reasons << "later required finding assessment requires a completed current review" if later_blocker_update
          reasons << (error || "review evidence is stale or incomplete") unless current_evidence
          reasons << "independent current-head approval and executed required checks missing" unless round&.dig("approval")
          phase = record.fetch("phases").last
          decision = Policy.decision(profile: record.fetch("profile"),
            bounds: record.fetch("bounds").merge("maximum_rounds" => phase.fetch("maximum_rounds")),
            phase_rounds: record.fetch("rounds").size - phase.fetch("round_start"),
            completed_rounds: record.fetch("rounds").size, clean_streak: result.fetch("clean_streak"),
            accepted: reasons.empty?, recurrence: !result.fetch("recurring_blockers").empty?,
            execution_failure: execution_failure(record))
          reasons << decision.fetch("execution_failure") if decision["execution_failure"]
          reasons << "recurring blocker requires diagnosis" unless result.fetch("recurring_blockers").empty?
          result.merge(decision).merge("decision" => decision, "active_contract" => successor.nil?, "superseded_by" => successor, "evidence" => {"valid" => current_evidence, "available" => available,
            "source_head" => source_head, "current_head" => head, "source_base" => source_base,
            "current_base" => base, "reason" => error || revision_error}, "accepted" => decision.fetch("accepted"), "reasons" => reasons,
            "result_identity" => result_identity_for(record, head, base))
        end

        def observe(record, head, base)
          last = record["head_transitions"].last
          return if last && last["head"] == head && last["base"] == base
          record["head_transitions"] << {"head" => head, "base" => base, "observed_at" => Time.now.utc.iso8601(6)}
        end

        def validate_local_commits(record, head, base)
          return unless @live_git && record["subject"]["local_candidate_id"]
          if @candidate_reader
            [head, base].each { |revision| @candidate_reader.commit!(revision) }
            return
          end
          [head, base].each do |revision|
            _, status = Open3.capture2("git", "cat-file", "-e", "#{revision}^{commit}",
              chdir: @repo_root, err: File::NULL)
            raise Contract::Invalid, "local campaign revision is not an available Git commit: #{revision}" unless status.success?
          end
        end

        def validate_local_full_diff(record, head, base)
          return unless @live_git && record["subject"]["local_candidate_id"] &&
            record["policy"]["required_scopes"].include?("full")
          if @candidate_reader
            raise Contract::Invalid, "local full scope cannot review an empty Git diff" unless @candidate_reader.full_diff?(base, head)
            return
          end
          _, stderr, status = Open3.capture3("git", "diff", "--quiet", "--no-ext-diff", "--no-textconv",
            base, head, "--", chdir: @repo_root)
          raise Contract::Invalid, "local full scope cannot review an empty Git diff" if status.exitstatus == 0
          raise Contract::Invalid, "local full diff unavailable: #{stderr.strip}" unless status.exitstatus == 1
        end

        def current_revisions(record)
          if @candidate_reader
            head, base = @candidate_reader.head, @candidate_reader.base
            validate_local_commits(record, head, base)
            validate_local_full_diff(record, head, base)
            return [head, base]
          end
          if @live_git && record["subject"]["pr"]
            metadata = fetch_pr_metadata(record["subject"])
            raise Contract::Invalid, metadata[:error] unless metadata[:success]
            value = metadata[:metadata]
            validate_repository(record, value["url"])
            return [Contract.sha!(value["headRefOid"], "live PR head"),
              Contract.sha!(value["baseRefOid"], "live PR base")]
          end
          head, base = @revisions.call("HEAD"), @revisions.call("base", record)
          if base
            validate_local_commits(record, head, base)
            validate_local_full_diff(record, head, base)
          end
          [head, base]
        end

        def fetch_pr_metadata(subject)
          server = configured_pr_server(subject["repository"])
          # Only head/base identity is consumed here; skip the full diff/
          # comment/check inventory.
          result = Molecules::PrProvider.new(server_name: server.name).fetch_metadata(subject["pr"])
          result[:success] ? result : result.merge(error: "PR source unavailable: #{result[:error]}")
        rescue Ace::Git::Error, ArgumentError => e
          {success: false, error: "PR source unavailable: #{e.message}"}
        end

        def clean_candidate?
          return @candidate_reader.clean? if @candidate_reader
          return true unless @live_git
          out, status = Open3.capture2("git", "status", "--porcelain", "-z", "--untracked-files=all",
            chdir: @repo_root, err: File::NULL)
          status.success? && out.split("\0").all? { |entry| entry.start_with?("?? .ace-local/") }
        end

        def pr_url_for(subject)
          return nil unless subject["pr"]
          parsed = Ace::Git::Atoms::PrIdentifier.parse(subject["pr"])
          server = configured_pr_server(subject["repository"])
          suffix = (server.provider == :forgejo) ? "pulls" : "pull"
          # Clone-form server URLs (trailing .git) are not valid web bases.
          web_base = server.url.delete_suffix("/").sub(/\.git\z/i, "")
          "#{web_base}/#{suffix}/#{parsed.number}"
        end

        def git_revision(ref, record = nil)
          return ref == "base" ? @candidate_reader.base : @candidate_reader.head if @candidate_reader
          # Local base is the latest explicit committed pin. PR revisions use
          # the existing provider adapter in current_revisions.
          if ref == "base"
            return record["attempts"].last&.dig("binding", "base") || @revisions.call("HEAD")
          end
          out, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo_root, err: File::NULL)
          raise Contract::Invalid, "live repository HEAD unavailable" unless status.success?
          Contract.sha!(out.strip, "live HEAD")
        end

        def validate_repository(record, pr_url)
          subject = record["subject"]
          if subject["pr"]
            server = configured_pr_server(subject["repository"])
            parsed = Ace::Git::Atoms::PrIdentifier.parse(subject["pr"])
            selected_repo = Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2)[1]
            supplied = Ace::Git::Atoms::PrReference.parse(pr_url)
            unless parsed.repo&.casecmp?(selected_repo) && supplied &&
                supplied.number == parsed.number.to_i && supplied.repository_url ==
                  Ace::Git::Atoms::ServerUrl.normalize(server.url)
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

        def configured_pr_server(repository)
          matches = Ace::Git::ServerRegistry.matching_servers(repository)
          unless matches.one?
            raise Contract::Invalid,
              "PR repository #{repository} must match exactly one configured forge server"
          end
          matches.first
        end

        def allocate_id
          value = Ace::B36ts.encode(Time.now)
          value = (value.to_i(36) + 1).to_s(36).rjust(6, "0") while store.registered_id?(value)
          value
        end
      end
    end
  end
end
