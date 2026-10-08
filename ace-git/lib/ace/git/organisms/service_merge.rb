# frozen_string_literal: true
require "json"
require "digest"
require_relative "pull_request_lifecycle"
require_relative "../atoms/delivery_parameters"
require_relative "../atoms/service_pr_input"

module Ace
  module Git
    module Organisms
      # A fixed receiver-side operation, never a grant or a worker fallback.
      class ServiceMerge
        MAX_INPUT = 128 * 1024
        MAX_SERVICE_INPUT = 64 * 1024
        MAX_ARTIFACT = 64 * 1024
        ARTIFACT = "pr-result.txt"
        REQUEST = %w[request_id assignment_id attempt_id project_id operation input_digest target candidate_head
          executor_uid transport authorization service_id caller_uid].freeze
        EXECUTION = %w[executor_uid authority_id claim_binding candidate_generation head staging_id].freeze
        TOKEN = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        SHA = /\A[0-9a-f]{40}\z/
        DIGEST = /\A[0-9a-f]{64}\z/

        def initialize(operation: "merge", lifecycle_factory: nil, uid: -> { Process.uid }, euid: -> { Process.euid })
          raise ArgumentError, "unsupported fixed PR operation" unless Atoms::ServicePrInput::OPERATIONS.include?(operation)
          @operation = operation
          @factory = lifecycle_factory || ->(**selection) { PullRequestLifecycle.new(**selection) }
          @uid, @euid = uid, euid
        end

        def call(bytes:, root:)
          envelope = parse!(bytes)
          request, execution, input = envelope.values_at("request", "execution", "input")
          parameters = Atoms::DeliveryParameters.validate(input.fetch("delivery"))
          Atoms::ServicePrInput.validate(input, operation: @operation)
          directory, held = private_root!(root)
          begin
            lifecycle = @factory.call(server_name: parameters["forge_server"], use_default: parameters.fetch("forge_default"), repo_root: directory)
            server = if @operation == "create"
              lifecycle.resolved_repository_identity(request.fetch("target").fetch("resource"))
            else
              lifecycle.resolved_identity(request.fetch("target").fetch("resource"))
            end
            provenance = parameters.fetch("pr_provenance")
            unless Atoms::ServerUrl.match?(server.fetch("url"), provenance.fetch("base_repository_url"))
              raise ProviderIdentityMismatchError, "merge forge differs from accepted provenance"
            end
            pinned = ResolvedServer.new(name: server.fetch("name"), provider: server.fetch("provider").to_sym, url: server.fetch("url"))
            lifecycle = @factory.call(server_name: pinned.name, use_default: false, repo_root: directory, resolved_server: pinned)
            resource, head = request.fetch("target").fetch("resource"), execution.fetch("head")
            if @operation != "create"
              before = lifecycle.show(resource)
              verify_pr!(before, resource, head, server, provenance)
              if %w[update ready].include?(@operation) && before.state.to_s != "open"
                raise ProviderExpectedHeadConflictError, "protected PR edit requires an open PR"
              end
              if @operation == "update" && !before.draft
                raise ProviderExpectedHeadConflictError, "protected update requires a draft PR"
              end
            end
            title = lifecycle.draft_title(input.fetch("title")) if Atoms::ServicePrInput::DRAFT_OPERATIONS.include?(@operation)
            receipt = case @operation
            when "create"
              lifecycle.create(head_ref: provenance.fetch("head_ref"), base_ref: provenance.fetch("base_ref"),
                head_repository_url: provenance.fetch("head_repository_url"), expected_head: head,
                title: title, body: input.fetch("body"), draft: true)
            when "update"
              lifecycle.update(resource, expected_head: head, title: title, body: input.fetch("body"))
            when "ready" then lifecycle.ready(resource, expected_head: head)
            when "merge" then lifecycle.merge(resource, expected_head: head, method: input.fetch("method"))
            end
            unless receipt.is_a?(ProviderMutationReceipt) && receipt.server_name == pinned.name && receipt.operation.to_s == @operation
              raise ProviderUnknownOutcomeError, "PR response does not identify the selected operation"
            end
            after = receipt.pull_request
            raise ProviderUnknownOutcomeError, "PR response lacks its exact result" unless after.is_a?(ProviderPullRequest)
            verify_pr!(after, @operation == "create" ? after.url : resource, head, server, provenance)
            if @operation == "merge"
              unless after.state.to_s == "merged" && after.merge_commit_sha.is_a?(String) && after.merge_commit_sha.match?(SHA)
                raise ProviderUnknownOutcomeError, "merge outcome is not verified"
              end
              payload = {"server" => server, "delivery" => parameters, "method" => input.fetch("method"),
                "candidate_head" => head, "receipt" => receipt.to_h}
            else
              expected_draft = Atoms::ServicePrInput::DRAFT_OPERATIONS.include?(@operation)
              unless after.state.to_s == "open" && after.draft == expected_draft &&
                  (!expected_draft || after.title == title && after.body == input.fetch("body"))
                raise ProviderUnknownOutcomeError, "PR draft/content outcome is not verified"
              end
              payload = {"server" => server, "operation" => @operation, "input" => input,
                "candidate_head" => head, "receipt" => receipt.to_h}
            end
            artifact = "ace-service-attestation request:#{request.fetch('request_id')} input:#{request.fetch('input_digest')} outcome:succeeded\n" + JSON.generate(payload) + "\n"
            digest = publish!(directory, held, artifact)
            {"request_id" => request.fetch("request_id"), "input_digest" => request.fetch("input_digest"),
              "outcome" => "succeeded", "evidence" => [{"ref" => ARTIFACT, "sha256" => digest}]}
          ensure
            held.close
          end
        end

        private

        def parse!(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, MAX_INPUT) && bytes.dup.force_encoding(Encoding::UTF_8).valid_encoding? && !bytes.include?("\0")
            raise ArgumentError, "merge envelope is invalid or oversized"
          end
          envelope = JSON.parse(bytes, max_nesting: 16, create_additions: false,
            allow_duplicate_key: false, allow_comments: false, allow_nan: false)
          closed!(envelope, %w[version request input execution])
          raise ArgumentError, "merge envelope version differs" unless envelope["version"].is_a?(Integer) && envelope["version"] == 1
          request, execution, input = envelope.values_at("request", "execution", "input")
          closed!(request, REQUEST)
          closed!(execution, EXECUTION)
          Atoms::ServicePrInput.validate(input, operation: @operation)
          raise ArgumentError, "merge service input exceeds receiver bound" if JSON.generate(input).bytesize > MAX_SERVICE_INPUT
          closed!(input["target"], %w[resource artifact_digest])
          closed!(request["target"], %w[resource artifact_digest])
          %w[request_id assignment_id attempt_id project_id authorization service_id].each do |key|
            raise ArgumentError, "merge request identifier differs" unless request[key].is_a?(String) && request[key].match?(TOKEN)
          end
          %w[authority_id staging_id].each do |key|
            raise ArgumentError, "merge execution identifier differs" unless execution[key].is_a?(String) && execution[key].match?(TOKEN)
          end
          unless request["operation"] == @operation && request["transport"] == "unix" &&
              %w[executor_uid caller_uid].all? { |key| request[key].is_a?(Integer) && request[key].positive? } &&
              request["executor_uid"] != request["caller_uid"] && request["executor_uid"] == execution["executor_uid"] &&
              execution["executor_uid"].is_a?(Integer) &&
              request["executor_uid"] == @uid.call && request["executor_uid"] == @euid.call &&
              execution["candidate_generation"].is_a?(Integer) && execution["candidate_generation"].positive? &&
              execution["head"].is_a?(String) && execution["head"].match?(SHA) && request["candidate_head"] == execution["head"] &&
              execution["claim_binding"].is_a?(String) && execution["claim_binding"].match?(DIGEST) &&
              request["input_digest"].is_a?(String) && request["input_digest"].match?(DIGEST) &&
              request["input_digest"] == Digest::SHA256.hexdigest(JSON.generate(canonical(input))) && request["target"] == input["target"]
            raise ArgumentError, "merge original claim/input/executor join differs"
          end
          target = input.fetch("target")
          reference = target["resource"].is_a?(String) && Atoms::PrReference.parse(target["resource"])
          unless (@operation == "create" || reference && reference.repository_url) && target["resource"].is_a?(String) && target["resource"].bytesize.between?(1, 256) &&
              (target["artifact_digest"].nil? || target["artifact_digest"].is_a?(String) && target["artifact_digest"].match?(DIGEST))
            raise ArgumentError, "merge target requires an exact PR URL"
          end
          envelope
        rescue JSON::ParserError, JSON::NestingError, KeyError
          raise ArgumentError, "merge envelope is malformed"
        end

        def closed!(value, fields)
          raise ArgumentError, "merge fields differ" unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end

        def canonical(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, canonical(value.fetch(key))] }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end

        def verify_pr!(pr, resource, head, server, provenance)
          reference = Atoms::PrReference.parse(resource)
          unless pr.is_a?(ProviderPullRequest) && reference && reference.repository_url && pr.url == resource && pr.number == reference.number &&
              pr.server_name == server.fetch("name") && pr.head_sha == head &&
              pr.head_ref == provenance.fetch("head_ref") && pr.base_ref == provenance.fetch("base_ref") &&
              Atoms::ServerUrl.match?(reference.repository_url, provenance.fetch("base_repository_url")) &&
              Atoms::ServerUrl.match?(pr.head_repository_url, provenance.fetch("head_repository_url")) &&
              Atoms::ServerUrl.match?(pr.base_repository_url, provenance.fetch("base_repository_url"))
            raise ProviderExpectedHeadConflictError, "merge PR identity/head/provenance differs"
          end
        end

        def private_root!(root)
          raise ArgumentError, "merge staging root must be absolute" unless root.is_a?(String) && root.start_with?("/")
          held = File.open(root, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
          stat = held.stat
          unless stat.directory? && stat.uid == @uid.call && (stat.mode & 0o7777) == 0o700 &&
              [stat.dev, stat.ino] == File.lstat(root).then { |value| [value.dev, value.ino] }
            raise ArgumentError, "merge staging root is not private"
          end
          [root, held]
        rescue StandardError
          held&.close
          raise
        end

        def publish!(root, held, bytes)
          raise ProviderUnknownOutcomeError, "merge result exceeds evidence bound" unless bytes.bytesize <= MAX_ARTIFACT
          stat = held.stat
          identity = [stat.dev, stat.ino]
          unless stat.directory? && stat.uid == @uid.call && (stat.mode & 0o7777) == 0o700 &&
              identity == File.lstat(root).then { |value| [value.dev, value.ino] }
            raise ProviderUnknownOutcomeError, "merge staging root changed"
          end
          File.open(File.join(root, ARTIFACT), File::RDWR | File::CREAT | File::EXCL | File::NOFOLLOW | File::NONBLOCK, 0o600) do |file|
            file.write(bytes); file.flush; file.fsync; file.chmod(0o400)
            before = file.stat
            file.rewind
            captured = file.read(MAX_ARTIFACT + 1)
            after = file.stat
            unless before.file? && before.uid == @uid.call && captured == bytes &&
                [before.dev, before.ino, before.size, before.mtime, before.ctime] == [after.dev, after.ino, after.size, after.mtime, after.ctime]
              raise ProviderUnknownOutcomeError, "merge held evidence changed"
            end
            held.fsync
            raise ProviderUnknownOutcomeError, "merge staging root changed" unless identity == File.lstat(root).then { |value| [value.dev, value.ino] }
            Digest::SHA256.hexdigest(captured)
          end
        rescue SystemCallError, IOError
          raise ProviderUnknownOutcomeError, "merge evidence publication unavailable"
        end
      end
    end
  end
end
