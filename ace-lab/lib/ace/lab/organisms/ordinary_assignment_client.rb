# frozen_string_literal: true

require "securerandom"
require "ace/assign/authority/retained_input"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/organisms/prepared_work_builder"
require_relative "../molecules/ordinary_owner_config"

module Ace
  module Lab
    module Organisms
      # File inputs retain the exact mutation and bytes across response loss.
      # Only Assign's installed owner registers, advances and accepts execution.
      class OrdinaryAssignmentClient
        A = Ace::Assign::Authority
        Files = A::RetainedInput
        REQUEST_KEYS = %w[version project_id operation mutation_id params parts].freeze

        def initialize(project:, config: nil, client_factory: nil)
          @project = project
          @config = config || Molecules::OrdinaryOwnerConfig.load(project: project)
          unless @config.is_a?(Molecules::OrdinaryOwnerConfig) && @config.project == project
            raise ArgumentError, "ordinary assignment project selection differs"
          end
          @client_factory = client_factory || ->(**options) { A::OrdinaryClient.new(**options) }
        end

        # Preparation produces input only, so it is also available on the host.
        # Reusing an existing output directory never rebuilds or resubmits work.
        def self.prepare(project:, task:, pane:, output:, dependency_reports: [])
          unless project.is_a?(String) && Molecules::OrdinaryOwnerConfig::ID.match?(project) &&
              pane.is_a?(String) && Molecules::OrdinaryOwnerConfig::PANE.match?(pane)
            raise ArgumentError, "preparation requires project and native pane selectors"
          end
          directory = Files.create_output(output)
          prepared = Ace::Assign::Organisms::PreparedWorkBuilder.new(export_root: directory)
            .call(task_ref: task, project_id: project, dependency_reports: dependency_reports)
          definition = JSON.parse(prepared.fetch("definition_bytes"))
          reference = definition.fetch("prepared_work")
          request = {"version" => 1, "project_id" => project, "operation" => "register_assignment",
            "mutation_id" => SecureRandom.hex(16), "params" => {
              "assignment_id" => prepared.fetch("assignment_id"), "pane" => pane, "expected_generation" => 0,
              "definition_digest" => Digest::SHA256.hexdigest(prepared.fetch("definition_bytes")),
              "prepared_head" => prepared.fetch("head"), "prepared_tree" => prepared.fetch("tree"),
              "manifest_sha256" => reference.fetch("manifest_sha256")},
            "parts" => [{"file" => "prepared.bundle", "bytes" => prepared.fetch("bytes"), "sha256" => prepared.fetch("sha256")}]}
          Files.write_file(directory, "definition.json", prepared.fetch("definition_bytes"))
          Files.write_file(directory, "prepared.bundle", prepared.fetch("bundle"))
          Files.write_file(directory, "request.json", JSON.generate(request) + "\n")
          {"project_id" => project, "assignment_id" => prepared.fetch("assignment_id"),
            "scope" => prepared.fetch("scope"), "request" => File.join(directory, "request.json"), "prepared" => true}
        end

        def request(input:, output: nil)
          request = JSON.parse(Files.read_file(input, 16_384), allow_duplicate_key: false, create_additions: false, max_nesting: 24)
          unless request.is_a?(Hash) && request.keys.sort == REQUEST_KEYS.sort && request["version"].is_a?(Integer) && request["version"] == 1 &&
              request["project_id"] == @project && A::OrdinaryLifecycle::OPERATIONS.include?(request["operation"]) &&
              request["params"].is_a?(Hash) && !request["params"].key?("transfer") && request["parts"].is_a?(Array)
            raise ArgumentError, "retained ordinary request selection is invalid"
          end
          operation = request.fetch("operation")
          read = %w[registration_status assignment_snapshot result_status result_snapshot supervisor_status export_candidate review_status merge_evidence candidate_reference campaign_status].include?(operation)
          mutation = request.fetch("mutation_id")
          unless read ? mutation.nil? : mutation.is_a?(String) && Ace::Assign::Molecules::JournalMutation::ID.match?(mutation)
            raise ArgumentError, "retained mutation ID must be explicit; read operations require null"
          end
          transfer = A::OrdinaryLifecycle::TRANSFER_OPERATIONS[operation]
          download = transfer && transfer.fetch(:direction) == :download
          upload = transfer && transfer.fetch(:direction) == :upload
          unless (!!output == !!download) && (request["parts"].empty? || upload)
            raise ArgumentError, "download requires a new --output directory; only uploads accept parts"
          end
          parts = upload && read_parts(request.fetch("parts"), input, transfer.fetch(:purpose))
          # No local metadata is interpreted as successful execution. Download
          # files are merely a projection of the authenticated canonical reply.
          directory = download && Files.create_output(output)
          client = @client_factory.call(project_id: @project, service: @config.service,
            verify_selection: @config.method(:verify_owner!), scratch_root: directory || nil)
          reply = client.call(operation, request.fetch("params"), mutation_id: request.fetch("mutation_id"),
            upload_parts: parts || nil, download: !!download, purpose: transfer && transfer.fetch(:purpose))
          envelope = {"status" => "ok", "data" => reply.data, "transport" => {"replayed" => reply.replayed}}
          if download
            files = reply.parts.each_with_index.map do |bytes, index|
              name = format("part-%02d.bytes", index)
              Files.write_file(directory, name, bytes)
              {"file" => File.join(directory, name), "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
            end
            envelope["files"] = files
            Files.write_file(directory, "response.json", JSON.generate(envelope) + "\n")
          end
          envelope
        rescue JSON::ParserError
          raise ArgumentError, "retained request is not valid bounded JSON"
        end

        private

        def read_parts(entries, input, purpose)
          total, count, per_part = A::TransferCodec::LIMITS.fetch(purpose)
          unless entries.size.between?(1, count) && entries.all? { |entry|
              entry.is_a?(Hash) && entry.keys.sort == %w[bytes file sha256] && entry["file"].is_a?(String) &&
                entry["file"].bytesize.between?(1, 4096) && !entry["file"].include?("\0") &&
                entry["bytes"].is_a?(Integer) && entry["bytes"].between?(0, per_part) &&
                entry["sha256"].is_a?(String) && A::TransferCodec::SHA256.match?(entry["sha256"])
            } && entries.sum { |entry| entry.fetch("bytes") } <= total
            raise ArgumentError, "retained upload inventory is invalid"
          end
          entries.map do |entry|
            bytes = Files.read_file(File.expand_path(entry.fetch("file"), File.dirname(File.expand_path(input))), per_part)
            unless bytes.bytesize == entry.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == entry.fetch("sha256")
              raise ArgumentError, "retained upload bytes changed; preserve the original mutation"
            end
            bytes
          end
        end
      end
    end
  end
end
