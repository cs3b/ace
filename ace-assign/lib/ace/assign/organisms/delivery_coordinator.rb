# frozen_string_literal: true
require "yaml"
require "ace/git/organisms/pull_request_lifecycle"
require_relative "../atoms/delivery_parameters"

module Ace
  module Assign
    module Organisms
      # Remote delivery is a projection of the existing attempt journal.
      # Intents precede writes; an interrupted intent permits reconciliation
      # reads only. Privileged merge is executed by qjx, never this worker.
      class DeliveryCoordinator
        def initialize(repo_root:, coordinator: nil, journal: nil, lifecycle_factory: nil, exclusion: nil, identity_resolver: nil)
          @mutex = Mutex.new
          @identity_resolver = identity_resolver || Molecules::ExecutionIdentityResolver.new
          @repo_root = repo_root
          @journal = journal || Molecules::EvidenceJournal.new(repo_root: repo_root)
          @coordinator = coordinator || AttemptCoordinator.new(repo_root: repo_root, journal: @journal)
          @factory = lifecycle_factory || ->(selection) { Ace::Git::Organisms::PullRequestLifecycle.new(**selection) }
          @exclusion = exclusion || Molecules::LifecycleExclusion.new(repo_root: repo_root)
        end

        def perform(**arguments)
          @mutex.synchronize { execute_request(**arguments) }
        end

        private

        def execute_request(assignment_id:, attempt_id:, operation:, parameters: nil, title: nil, body: nil,
          tests: nil, review: nil, service_request_id: nil)
          @identity = @identity_resolver.resolve
          unless @identity_resolver.trusted?(@identity)
            raise AttemptErrors::UnauthorizedIdentity, "Only a trusted coordinator or service may accept delivery evidence"
          end
          raise ArgumentError, "Unsupported delivery operation" unless %w[create update ready review merge status].include?(operation)
          if operation == "create" && (!title.is_a?(String) || title.strip.empty?)
            raise ArgumentError, "Create requires a concrete PR title"
          end
          if operation == "update" && title.nil? && body.nil?
            raise ArgumentError, "Update requires title or body"
          end
          raise ArgumentError, "PR body must be text" unless body.nil? || body.is_a?(String)
          params = Atoms::DeliveryParameters.validate(parameters || assignment_parameters(assignment_id))
          binding = {"assignment_id" => assignment_id, "attempt_id" => attempt_id}
          attempt = @coordinator.authoritative_attempt(binding)
          raise AttemptErrors::NotFound, "Delivery attempt not found" unless attempt
          raise AttemptErrors::ReceiptRejected, "Delivery requires a managed attempt" unless attempt.managed?
          @exclusion.with_shared(@exclusion.task_key(attempt.binding.task_id)) do
            @exclusion.with_exclusive(@exclusion.assignment_key(assignment_id)) do
              raise AttemptErrors::Conflict, "Assignment was pruned" if @exclusion.removed?(@exclusion.assignment_key(assignment_id))
              execute(binding, operation, params, title: title, body: body, tests: tests, review: review,
                service_request_id: service_request_id)
            end
          end
        end

        private

        def assignment_parameters(assignment_id)
          assignment = Molecules::AssignmentManager.new.load(assignment_id)
          raise AttemptErrors::NotFound, "Assignment not found" unless assignment
          document = YAML.safe_load_file(assignment.source_config, permitted_classes: [Time, Date])
          document.fetch("delivery")
        rescue KeyError, Errno::ENOENT, Psych::Exception
          raise ArgumentError, "Assignment needs explicit delivery parameters"
        end

        def execute(binding, operation, params, **options)
          @binding = binding
          @attempt = @coordinator.authoritative_attempt(binding)
          unless @attempt&.active? && @attempt.managed?
            raise AttemptErrors::ReceiptRejected, "Delivery attempt is no longer active"
          end
          @head = git!("rev-parse", "HEAD").strip
          selection = {server_name: params["forge_server"], use_default: params["forge_default"], repo_root: @repo_root}
          historical = events.find { |event| event.dig("payload", "stage") == "identity" }&.fetch("payload")
          selection = {server_name: historical.dig("server", "name"), use_default: false, repo_root: @repo_root} if historical
          @lifecycle = @factory.call(selection)
          server = @lifecycle.resolved_identity
          @server = server
          Atoms::DeliveryParameters.validate_url!(server.fetch("url"))
          provenance = params.fetch("pr_provenance")
          unless Ace::Git::Atoms::ServerUrl.match?(server["url"], provenance["base_repository_url"])
            raise Ace::Git::ProviderIdentityMismatchError, "Selected forge does not match delivery base"
          end
          if historical
            unless historical["server"] == server && historical["provenance"] == provenance &&
                historical["selection"] == params.slice("forge_server", "forge_default")
              raise AttemptErrors::Conflict, "Delivery identity or selection changed during attempt"
            end
          elsif !%w[status review].include?(operation)
            record("stage" => "identity", "server" => server, "provenance" => provenance,
              "selection" => params.slice("forge_server", "forge_default"))
          end
          @provenance = provenance
          pinned = Ace::Git::ResolvedServer.new(name: server.fetch("name"),
            provider: server.fetch("provider").to_sym, url: server.fetch("url"))
          @lifecycle = @factory.call(server_name: pinned.name, use_default: false,
            repo_root: @repo_root, resolved_server: pinned)
          verify_pushed_head!
          return status if operation == "status"
          return review_snapshot if operation == "review"
          pending = unresolved_intent
          return reconcile(pending) if pending
          require_evidence!(options[:tests], options[:review]) if %w[ready merge].include?(operation)
          return consume_merge(options[:service_request_id]) if operation == "merge"
          pr = current_pr
          return reconcile({"operation" => "create", "head" => @head}) if operation == "create" && pr
          raise AttemptErrors::ReceiptRejected, "Create a draft before #{operation}" if operation != "create" && !pr
          verify_pr!(pr) if pr
          intent = {"stage" => "intent", "operation" => operation, "head" => @head,
                    "input_digest" => Atoms::EvidenceDigest.digest(options.slice(:title, :body).compact),
                    "fields" => options.slice(:title, :body).compact.keys.map(&:to_s),
                    "pr_number" => pr&.number, "tests" => options[:tests], "review" => options[:review]}
          record(intent)
          receipt = case operation
          when "create"
            @lifecycle.create(head_ref: provenance["head_ref"], base_ref: provenance["base_ref"],
              head_repository_url: provenance["head_repository_url"], expected_head: @head,
              title: options[:title], body: options[:body], draft: true)
          when "update"
            @lifecycle.update(pr.number, expected_head: @head, title: options[:title], body: options[:body])
          when "ready" then @lifecycle.ready(pr.number, expected_head: @head)
          end
          verify_pr!(receipt.pull_request)
          unless receipt.operation.to_s == operation && receipt.server_name == server["name"] &&
              (operation != "create" || receipt.pull_request.draft == true) &&
              (operation != "ready" || receipt.pull_request.draft == false)
            raise Ace::Git::ProviderUnknownOutcomeError, "Delivery mutation lacks expected outcome"
          end
          record_result(operation, receipt.pull_request, "succeeded")
          status
        rescue Ace::Git::ProviderUnknownOutcomeError
          # The durable intent remains unresolved; no exception text or
          # provider payload is stored (both may contain sensitive data).
          raise
        end

        def events
          @journal.read_events(@binding.fetch("assignment_id")).select do |event|
            event["type"] == "delivery" && event["attempt_id"] == @binding.fetch("attempt_id")
          end
        end

        def record(payload)
          producer = {"actor" => @identity.actor, "role" => @identity.role, "runtime" => @identity.runtime}
          @journal.record(**@binding.transform_keys(&:to_sym), type: "delivery", payload: payload.merge("producer" => producer),
            guard: -> {
              live = @coordinator.authoritative_attempt(@binding)
              raise AttemptErrors::ReceiptRejected, "Delivery attempt is no longer active" unless live&.active?
              raise AttemptErrors::ReceiptRejected, "Candidate changed during delivery" unless git!("rev-parse", "HEAD").strip == @head
            })
        end

        def unresolved_intent
          pending = nil
          events.each do |event|
            payload = event.fetch("payload")
            pending = payload if payload["stage"] == "intent"
            pending = nil if payload["stage"] == "result" && payload["outcome"] == "succeeded"
          end
          pending
        end

        def current_pr
          result = events.reverse.find { |event| event.dig("payload", "stage") == "result" && event.dig("payload", "pr") }
          result && @lifecycle.show(result.dig("payload", "pr", "number"))
        end

        def reconcile(intent)
          raise AttemptErrors::ReceiptRejected, "Unresolved delivery belongs to an older candidate" unless intent["head"] == @head
          operation = intent.fetch("operation")
          if operation == "create"
            matches = @lifecycle.reconcile_create(**@provenance.reject { |key, _| key == "mode" }.transform_keys(&:to_sym))
            raise Ace::Git::ProviderUnknownOutcomeError, "No exact draft found; create remains unresolved" if matches.empty?
            raise Ace::Git::ProviderConflictingMatchesError, "Multiple exact drafts found" unless matches.length == 1
            pr = matches.first
            verify_pr!(pr)
            raise Ace::Git::ProviderUnknownOutcomeError, "Created PR draft state is unproven" unless pr.draft == true
          elsif operation == "ready"
            require_evidence!(intent["tests"], intent["review"])
            pr = @lifecycle.show(intent.fetch("pr_number"))
            verify_pr!(pr)
            raise Ace::Git::ProviderUnknownOutcomeError, "Readiness remains unresolved" unless pr.draft == false
          elsif operation == "update"
            pr = @lifecycle.review_metadata_snapshot(intent.fetch("pr_number")).pull_request
            verify_pr!(pr)
            observed = intent.fetch("fields").to_h { |field| [field, pr.public_send(field)] }
            unless Atoms::EvidenceDigest.digest(observed) == intent["input_digest"]
              raise Ace::Git::ProviderUnknownOutcomeError, "PR update remains unresolved"
            end
          else
            raise Ace::Git::ProviderUnknownOutcomeError, "#{operation} requires authoritative receipt reconciliation"
          end
          record_result(operation, pr, "succeeded")
          status
        end

        def require_evidence!(tests, review)
          [[tests, "check"], [review, "review-approval"]].each do |ref, kind|
            unless ref.is_a?(Hash) && ref.keys.sort == %w[attempt_id receipt_digest]
              raise AttemptErrors::ReceiptRejected, "Current accepted #{kind} evidence is required"
            end
            evidence = @coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["receipt_digest"], kind: kind)
            unless evidence["head"] == @head && evidence["assignment_id"] == @binding["assignment_id"] &&
                evidence["project_id"] == @attempt.binding.project_id
              raise AttemptErrors::ReceiptRejected, "Delivery evidence does not match assignment, project and candidate"
            end
          end
        end

        def consume_merge(request_id)
          unless request_id.is_a?(String) && request_id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/)
            raise AttemptErrors::ReceiptRejected, "Exact authorized merge service receipt is required"
          end
          request = @coordinator.service_request_status(request_id)
          unless request && request["state"] == "succeeded" && request["operation"] == "merge" &&
              request["assignment_id"] == @binding["assignment_id"] && request["attempt_id"] == @binding["attempt_id"] &&
              request["project_id"] == @attempt.binding.project_id && request["candidate_head"] == @head &&
              request["authorization"].is_a?(String) && !request["authorization"].empty?
            raise AttemptErrors::ReceiptRejected, "Exact authorized merge service receipt is required"
          end
          @coordinator.validate_service_receipt!(request, "succeeded", request["receipt"])
          pr = current_pr
          verify_pr!(pr)
          unless request.dig("target", "resource") == pr.url && pr.state.to_s == "merged" &&
              pr.merge_commit_sha.to_s.match?(/\A[0-9a-f]{40}\z/)
            raise AttemptErrors::ReceiptRejected, "Service receipt and merged PR identity do not agree"
          end
          record_result("merge", pr, "succeeded", "service_request_id" => request_id)
          status
        end

        def review_snapshot
          pr = current_pr
          raise AttemptErrors::ReceiptRejected, "Create a draft before remote review" unless pr
          verify_pr!(pr)
          snapshot = @lifecycle.review_snapshot(pr.number)
          verify_pr!(snapshot.pull_request)
          snapshot
        end

        def verify_pr!(pr)
          reference = pr && Ace::Git::Atoms::PrReference.parse(pr.url)
          unless reference && reference.number == pr.number && reference.repository_url &&
              Ace::Git::Atoms::ServerUrl.match?(reference.repository_url, @provenance["base_repository_url"])
            raise Ace::Git::ProviderIdentityMismatchError, "PR URL does not match delivery repository and number"
          end
          Atoms::DeliveryParameters.validate_url!(pr.url)
          unless pr && pr.server_name == @server["name"] && pr.number.is_a?(Integer) && pr.number.positive? &&
              pr.head_sha == @head && pr.head_ref == @provenance["head_ref"] &&
              pr.base_ref == @provenance["base_ref"] &&
              Ace::Git::Atoms::ServerUrl.match?(pr.head_repository_url, @provenance["head_repository_url"]) &&
              Ace::Git::Atoms::ServerUrl.match?(pr.base_repository_url, @provenance["base_repository_url"])
            raise Ace::Git::ProviderExpectedHeadConflictError, "PR candidate or provenance does not match delivery"
          end
        end

        def verify_pushed_head!
          output = git!("ls-remote", "--heads", @provenance["head_repository_url"], "refs/heads/#{@provenance['head_ref']}")
          expected = "#{@head}\trefs/heads/#{@provenance['head_ref']}"
          raise AttemptErrors::ReceiptRejected, "Pushed source does not match candidate" unless output.strip == expected
        end

        def record_result(operation, pr, outcome, extra = {})
          record({"stage" => "result", "operation" => operation, "head" => @head, "outcome" => outcome,
            "pr" => {"number" => pr.number, "url" => pr.url, "head_sha" => pr.head_sha,
                     "draft" => pr.draft, "state" => pr.state.to_s, "merge_commit_sha" => pr.merge_commit_sha}}.merge(extra))
        end

        def status
          attempt = @coordinator.authoritative_attempt(@binding)
          {"attempt_id" => attempt.attempt_id, "assignment_id" => @binding["assignment_id"],
           "task_id" => attempt.binding.task_id, "project_id" => attempt.binding.project_id,
           "actor" => attempt.binding.actor, "role" => attempt.binding.role, "runtime" => attempt.binding.runtime,
           "base_head" => attempt.binding.base_head, "candidate_head" => attempt.candidate_head,
           "evidence_git_ref" => @attempt.binding.evidence_git_ref, "journal_commit" => @journal.ref_value,
           "delivery" => events.map { |event| event.fetch("payload") }}
        end

        def git!(*argv)
          result = Ace::Git::Atoms::CommandExecutor.execute("git", "-C", @repo_root, *argv)
          raise AttemptErrors::EvidenceUnavailable, "Git delivery proof unavailable" unless result[:success]
          result[:output]
        end
      end
    end
  end
end
