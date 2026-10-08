# frozen_string_literal: true
require "securerandom"
require "rubygems/package"
require "ace/hitl/providers/lab"
require_relative "../molecules/protected_publication_publisher"

module Ace
  module Lab
    module Organisms
      class ProtectedServiceReceiver
        # One invocation is retained by the existing receiver worker, not a
        # second effect queue. Only canonical continuation can authorize a push.
        def begin_publication!(admitted:, materialized:, deadline:)
          raise SecurityError, "publication receiver already owns an invocation" if @publication
          @publication_hitl ||= Ace::Hitl::Providers::Lab.boundary_client(
            socket_path: Ace::Hitl::Providers::Lab::DEFAULT_SOCKET_PATH,
            policy: Ace::Hitl::Providers::Lab.grants_policy(grants_path: Ace::Hitl::Providers::Lab::DEFAULT_GRANTS_PATH))
          params = admitted.fetch(:params)
          started = admitted.fetch(:started)
          unless started.fetch("executor_process_binding") == @kernel.capture(Process.pid)
            raise SecurityError, "publication original receiver differs"
          end
          @publication = admitted.merge(materialized: materialized, handles: [], challenge: nil,
            ask_id: nil, disposition: "dispatch_started")
          hold_publication_artifact!(@publication)
          verified = publication_registry!(@publication, deadline)
          return complete_publication!(@publication, verified, deadline) if %w[succeeded failed].include?(verified.fetch("classification"))
          unless verified.fetch("classification") == "absent"
            @publication[:disposition] = "uncertain"
            return publication_status("uncertain", verified.fetch("code"))
          end
          publication_push!(@publication, nil, deadline)
        rescue StandardError, SecurityError
          publication_status("uncertain", "publication_admission_unavailable")
        end

        def tick_publication!(request_id:, deadline:)
          entry = @publication
          return {"request_id" => request_id, "state" => "publication-blocked", "code" => "original-executor-unavailable"} unless entry && entry.dig(:params, "request_id") == request_id
          check_publication!(entry)
          status = publication_call!(entry, "service_status", {}, deadline).data
          if %w[succeeded failed].include?(status["state"])
            close_publication!(entry)
            return projection(status)
          end
          if entry[:disposition] == "uncertain"
            verified = publication_registry!(entry, deadline)
            return complete_publication!(entry, verified, deadline) if verified["classification"] == "succeeded"
            return publication_status("uncertain", "publication_outcome_unconfirmed")
          end
          unless status["dispatch_phase"] == "otp_pending" && status["publication_challenge_digest"] == entry.fetch(:challenge).fetch("publication_challenge_digest")
            return publication_status("uncertain", "publication_challenge_changed")
          end
          publication_ask!(entry, deadline) unless entry[:ask_created]
          ask = @publication_hitl.read(entry.fetch(:ask_id), deadline: deadline)
          check_publication_ask!(entry, ask)
          if %w[cancelled consumed].include?(ask["state"])
            entry[:ask_id] = nil
            entry[:ask_created] = false
            entry[:ask_otp] = nil
            return publication_status("publication-pending", "otp-answer-unavailable")
          end
          if ask.fetch("otp").fetch("expires_at") <= Time.now.to_i
            @publication_hitl.cancel(entry.fetch(:ask_id), reason: "otp-answer-expired", deadline: deadline)
            return publication_status("publication-pending", "otp-answer-expired")
          end
          return publication_status("publication-pending", "otp-answer-pending") unless ask["state"] == "answer-delivered"
          return publication_status("publication-pending", "otp-tick-budget") if publication_remaining!(deadline) < 1.5
          answer = @publication_hitl.consume(entry.fetch(:ask_id), timeout: 1, operation: "publish", deadline: deadline)
          otp = answer["answer"]
          unless otp.is_a?(String) && otp.match?(/\A[0-9]{6}\z/) && ask.fetch("otp").fetch("expires_at") > Time.now.to_i
            return publication_status("publication-pending", "otp-answer-unavailable")
          end
          check_publication!(entry)
          return publication_status("publication-pending", "otp-tick-budget") if publication_remaining!(deadline) < 1
          status = publication_call!(entry, "service_status", {}, deadline).data
          return publication_status("publication-pending", "otp-answer-expired") unless ask.fetch("otp").fetch("expires_at") > Time.now.to_i
          entry[:disposition] = "uncertain" # A lost issuing reply is never retried.
          issued = publication_call!(entry, "publication_continue", {
            "expected_generation" => status.fetch("generation"), "input_digest" => entry.fetch(:params).fetch("input_digest"),
            "challenge_digest" => entry.fetch(:challenge).fetch("publication_challenge_digest")}, deadline,
            mutation_id: Digest::SHA256.hexdigest("publication-continue:#{entry.fetch(:challenge).fetch('publication_challenge_digest')}")).data
          return publication_status("uncertain", "publication_issuing_unconfirmed") unless issued["invocation"] == "permitted" && issued["dispatch_phase"] == "issuing"
          entry[:started] = issued
          publication_push!(entry, otp, deadline)
        rescue StandardError, SecurityError
          publication_status("uncertain", "publication_tick_unavailable")
        ensure
          otp&.clear if otp.is_a?(String) && !otp.frozen?
          answer&.delete("answer")
        end

        def publication_active?
          !@publication.nil?
        end

        # Called only after the existing worker has stopped its bounded tick.
        # Durable uncertain state and candidate bytes remain for read-only recovery.
        def release_publication_lifetime!
          @publication&.fetch(:handles)&.each { |_path, handle, _identity| handle.close unless handle.closed? }
          @publication = nil
        end

        private

        def hold_publication_artifact!(entry)
          root = entry.fetch(:materialized).fetch("directory")
          publication = entry.fetch(:envelope).fetch("input").fetch("publication")
          components = publication.fetch("artifact_relative_path").split("/")
          paths = [root]
          components.each { |component| paths << File.join(paths.last, component) }
          paths.each_with_index do |path, index|
            handle = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            stat = handle.stat
            valid = index == paths.size - 1 ? stat.file? && stat.size.between?(1, 64 * 1024 * 1024) : stat.directory?
            unless valid && stat.uid == Process.uid && (stat.mode & 0o022).zero?
              handle.close
              raise SecurityError, "publication staging protection differs"
            end
            entry.fetch(:handles) << [path, handle, publication_identity(stat)]
          end
          entry[:artifact] = paths.last
          spec = Gem::Package.new(paths.last).spec
          unless spec.name == publication.fetch("gem_name") && spec.version.to_s == publication.fetch("version")
            raise SecurityError, "publication artifact metadata differs"
          end
          entry[:platform] = spec.platform.to_s
          check_publication!(entry)
        end

        def check_publication!(entry)
          @kernel.live!(entry.fetch(:started).fetch("executor_process_binding"))
          raise SecurityError, "publication receiver birth differs" unless @kernel.capture(Process.pid) == entry.fetch(:started).fetch("executor_process_binding")
          entry.fetch(:handles).each do |path, handle, expected|
            unless publication_identity(handle.stat) == expected && publication_identity(File.lstat(path)) == expected
              raise SecurityError, "publication held staging changed"
            end
          end
          artifact = entry.fetch(:handles).last.fetch(1)
          artifact.rewind
          digest = Digest::SHA256.new
          while (chunk = artifact.read(65_536))
            digest.update(chunk)
          end
          unless digest.hexdigest == entry.fetch(:envelope).fetch("input").fetch("target").fetch("artifact_digest")
            raise SecurityError, "publication artifact bytes differ"
          end
        end

        def publication_identity(stat)
          stat.directory? ? [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode] :
            [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode, stat.size, stat.mtime, stat.ctime]
        end

        def publication_registry!(entry, deadline)
          check_publication!(entry)
          @publication_publisher.verify!(publication: entry.fetch(:envelope).fetch("input").fetch("publication"),
            artifact_digest: entry.fetch(:params).fetch("target").fetch("artifact_digest"), platform: entry.fetch(:platform), deadline: deadline)
        end

        def publication_push!(entry, otp, deadline)
          check_publication!(entry)
          entry[:disposition] = "uncertain"
          result = @publication_publisher.push!(operation: entry.fetch(:operation),
            publication: entry.fetch(:envelope).fetch("input").fetch("publication"), artifact: entry.fetch(:artifact),
            artifact_digest: entry.fetch(:params).fetch("target").fetch("artifact_digest"), otp: otp, deadline: deadline)
          check_publication!(entry)
          verified = publication_registry!(entry, deadline)
          return complete_publication!(entry, verified, deadline) if %w[succeeded failed].include?(verified["classification"])
          if %w[otp-required otp-rejected otp-expired].include?(result["classification"]) && verified["classification"] == "absent"
            return retain_publication_challenge!(entry, result, deadline)
          end
          return complete_publication!(entry, result, deadline) if result["classification"] == "failed" && verified["classification"] == "absent"
          publication_status("uncertain", "publication_outcome_unconfirmed")
        end

        def retain_publication_challenge!(entry, result, deadline)
          input = entry.fetch(:envelope).fetch("input")
          params = entry.fetch(:params)
          previous = entry[:challenge]&.fetch("publication_challenge_digest")
          need = params.slice("request_id", "input_digest", "candidate_generation", "head").merge(
            "schema" => "ace.publication-otp-need/v1", "classification" => result.fetch("classification"),
            "claim_binding" => entry.fetch(:claim).fetch("claim_binding"),
            "registry" => input.fetch("publication").fetch("registry"), "gem_name" => input.fetch("publication").fetch("gem_name"),
            "version" => input.fetch("publication").fetch("version"), "artifact_digest" => input.fetch("target").fetch("artifact_digest"),
            "dispatch_event_digest" => entry.fetch(:dispatch_event_digest), "previous_challenge_digest" => previous)
          bytes = JSON.generate(need)
          status = publication_call!(entry, "service_status", {}, deadline).data
          entry[:challenge] = publication_call!(entry, "publication_challenge", {
            "input_digest" => params.fetch("input_digest"), "expected_generation" => status.fetch("generation"),
            "receipt_sha256" => Digest::SHA256.hexdigest(bytes)}, deadline,
            mutation_id: Digest::SHA256.hexdigest("publication-challenge:#{Digest::SHA256.hexdigest(bytes)}"),
            upload_parts: [bytes], purpose: :receipt_artifacts).data
          entry[:disposition] = "otp_pending"
          entry[:ask_id] = nil
          entry[:ask_created] = false
          entry[:ask_otp] = nil
          publication_ask!(entry, deadline)
          publication_status("publication-pending", result.fetch("classification"))
        end

        def publication_ask!(entry, deadline)
          entry[:ask_id] ||= "publication-#{SecureRandom.hex(12)}"
          binding = entry.fetch(:params).slice("assignment_id", "attempt_id", "request_id", "input_digest", "candidate_generation", "head").merge(
            "schema" => "ace.hitl-publication-binding/v1", "mapping_id" => @mapping_id,
            "claim_binding" => entry.fetch(:claim).fetch("claim_binding"),
            "challenge_digest" => entry.fetch(:challenge).fetch("publication_challenge_digest"))
          entry[:ask_binding] = immutable(binding)
          entry[:ask_otp] ||= immutable({"operation" => "publish", "input_digest" => binding.fetch("input_digest"),
            "result_ref" => entry.fetch(:challenge).fetch("publication_challenge_ref").fetch("ref"), "expires_at" => Time.now.to_i + 900})
          @publication_hitl.create(id: entry.fetch(:ask_id), assignment: binding.fetch("assignment_id"), attempt: binding.fetch("attempt_id"),
            project: @map.fetch("project_id"), harness: "lab-admin", plan: "Scoped RubyGems publication", kind: "otp",
            question: "Provide the RubyGems OTP for this authorized artifact publication.", ace_hitl_id: entry.fetch(:ask_id),
            publication_binding: binding, otp: entry.fetch(:ask_otp), deadline: deadline)
          entry[:ask_created] = true
        end

        def check_publication_ask!(entry, ask)
          unless ask["id"] == entry.fetch(:ask_id) && ask["publication_binding"] == entry.fetch(:ask_binding) &&
              ask["publication_requester_peer"] == entry.fetch(:started).fetch("executor_process_binding") &&
              ask.dig("otp", "input_digest") == entry.fetch(:params).fetch("input_digest") &&
              ask.dig("otp", "result_ref") == entry.fetch(:challenge).fetch("publication_challenge_ref").fetch("ref")
            raise SecurityError, "publication HITL retained request differs"
          end
        end

        def publication_call!(entry, operation, extra, deadline, **options)
          params = entry.fetch(:params).slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
          params["claim_binding"] = entry.fetch(:claim).fetch("claim_binding") unless operation == "service_status"
          @client.call(operation, params.merge(extra), timeout: publication_remaining!(deadline), **options)
        end

        def complete_publication!(entry, result, deadline)
          check_publication!(entry)
          input = entry.fetch(:envelope).fetch("input")
          evidence = JSON.generate(input.merge("schema" => "ace.publication-result/v1", "classification" => result.fetch("classification"),
            "code" => result.fetch("code"), "request_id" => entry.fetch(:params).fetch("request_id"),
            "input_digest" => entry.fetch(:params).fetch("input_digest"), "claim_binding" => entry.fetch(:claim).fetch("claim_binding")))
          receipt = entry.fetch(:envelope).fetch("request").slice(*Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge(
            "outcome" => result.fetch("classification") == "succeeded" ? "succeeded" : "failed",
            "evidence" => [{"ref" => "publication-result", "sha256" => Digest::SHA256.hexdigest(evidence)}])
          bytes = JSON.generate(receipt)
          completed = publication_call!(entry, "complete_service", {"receipt_sha256" => Digest::SHA256.hexdigest(bytes)}, deadline,
            mutation_id: Digest::SHA256.hexdigest("publication-complete:#{entry.fetch(:mutation_id)}"), upload_parts: [bytes, evidence], purpose: :receipt_artifacts).data
          return publication_status("uncertain", "publication_completion_unconfirmed") unless %w[succeeded failed].include?(completed["state"])
          close_publication!(entry)
          projection(completed)
        end

        def close_publication!(entry)
          entry.fetch(:handles).each { |_path, handle, _identity| handle.close }
          cleanup_staging(entry.fetch(:materialized).fetch("directory"), entry.fetch(:staging_identity))
          @publication = nil
        end

        def publication_remaining!(deadline)
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise IOError, "publication tick deadline expired" unless remaining.positive?
          remaining
        end

        def publication_status(state, code)
          {"request_id" => @publication&.dig(:params, "request_id"), "state" => state, "code" => code}.freeze
        end
      end
    end
  end
end
