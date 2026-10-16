# frozen_string_literal: true

require "securerandom"
require "tmpdir"
require "fileutils"
require_relative "../authority/retained_input"
require_relative "../authority/prepared_work"
require_relative "../authority/transfer_codec"
require_relative "../molecules/journal_mutation"
require_relative "../models/execution_receipt"
require_relative "../models/assignment"
require_relative "../molecules/queue_scanner"

module Ace
  module Assign
    module Organisms
      # Operator protocol over the installed owner supplied by the composition.
      # Files retain requests only; every observation comes from that owner.
      class OrdinaryDriver
        Files = Authority::RetainedInput
        CONTEXT_KEYS = %w[version project_id assignment_id attempt_id scope pane supervisor_pane cwd head provider].freeze
        attr_reader :context, :path

        def initialize(path:, project:, transport:)
          @path = File.expand_path(path)
          @context = Files.json(@path)
          unless @context.is_a?(Hash) && @context.keys.sort == CONTEXT_KEYS.sort && @context["version"] == 1 &&
              @context["project_id"] == project && %w[project_id assignment_id attempt_id].all? { |key|
                @context[key].is_a?(String) && Molecules::JournalMutation::ID.match?(@context[key]) } &&
              @context["scope"].is_a?(String) && Authority::PreparedWork::SCOPE.match?(@context["scope"]) &&
              %w[pane supervisor_pane].all? { |key| @context[key].is_a?(String) && @context[key].match?(/\A[\w.:-]{1,128}\z/) } &&
              @context["cwd"].is_a?(String) && @context["cwd"].start_with?("/") &&
              File.expand_path(@context["cwd"]) == @context["cwd"] && @context["head"].is_a?(String) &&
              @context["head"].match?(/\A[0-9a-f]{40}\z/) && @context["provider"].is_a?(String) &&
              @context["provider"].bytesize.between?(1, 512)
            raise ArgumentError, "ordinary driver selection differs; retain the original context"
          end
          @root = Authority::PrivateDirectory.verify!(File.dirname(@path))
          @transport = transport
        end

        def status
          reply = read("result_status", selection)
          data = reply.fetch("data")
          unless data.values_at("project_id", "assignment_id", "attempt_id") == context.values_at("project_id", "assignment_id", "attempt_id")
            raise AttemptErrors::EvidenceUnavailable, "canonical status belongs to another execution"
          end
          data
        end

        def start(pane:)
          worker!(pane)
          mutate("start", "start_attempt", selection.merge("expected_generation" => 0,
            "pane" => pane, "scope" => context.fetch("scope"), "head" => context.fetch("head")))
        end

        def supervisor
          data = read("supervisor_status", context.slice("assignment_id")).fetch("data")
          unless data.values_at("project_id", "assignment_id") == context.values_at("project_id", "assignment_id")
            raise AttemptErrors::EvidenceUnavailable, "canonical supervisor belongs to another assignment"
          end
          data
        end

        def adopt_supervisor(pane:, generation:, previous_binding_sha256:)
          mutate("supervisor-#{generation}", "adopt_supervisor", context.slice("assignment_id").merge(
            "pane" => pane, "expected_generation" => generation, "previous_binding_sha256" => previous_binding_sha256))
        end

        def queue
          reply, bytes = snapshot("assignment_snapshot", selection.merge("kind" => "queue"))
          data = reply.fetch("data")
          unless data.values_at("project_id", "assignment_id", "attempt_id", "scope") ==
              context.values_at("project_id", "assignment_id", "attempt_id", "scope") &&
              Digest::SHA256.hexdigest(bytes) == data.fetch("sha256")
            raise AttemptErrors::EvidenceUnavailable, "canonical queue belongs to another execution"
          end
          value = JSON.parse(bytes)
          assignment = Models::Assignment.new(id: context.fetch("assignment_id"), name: "ordinary",
            created_at: Time.now.utc, source_config: "canonical", cache_dir: @root)
          state = Molecules::QueueScanner.new.scan_captured(steps: value.fetch("steps"),
            reports: value.fetch("reports"), assignment: assignment)
          scope = context.fetch("scope")
          current = state.current_in_subtree(scope)
          next_step = state.next_workable_in_subtree(scope)
          data.merge("complete" => state.subtree_complete?(scope), "failed" => state.subtree_failed?(scope),
            "current" => step(current), "next" => step(next_step), "reports" => value.fetch("reports"))
        end

        def bootstrap(output:)
          # Accepted task/context bytes are recovered from the canonical owner,
          # not the worker checkout's possibly older mutable task files.
          reply, bytes = snapshot("assignment_snapshot", selection.merge("attempt_id" => nil, "kind" => "prepared_work"))
          data = reply.fetch("data")
          unless data.values_at("project_id", "assignment_id") == context.values_at("project_id", "assignment_id")
            raise AttemptErrors::EvidenceUnavailable, "canonical preparation belongs to another assignment"
          end
          reference = data.fetch("prepared_work")
          work = Authority::PreparedWork.admit(bytes: bytes, sha256: data.fetch("sha256"), size: data.fetch("bytes"),
            head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree"), root: @root,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          unless work.reference(head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree")) == reference &&
              work.manifest.values_at("project_id", "assignment_id", "scope") == context.values_at("project_id", "assignment_id", "scope")
            raise AttemptErrors::EvidenceUnavailable, "canonical prepared scope differs"
          end
          directory = Files.create_output(output)
          inventory = work.manifest.fetch("context").each_with_index.flat_map do |entry, index|
            selected = %w[spec text].map { |kind| [kind, entry.fetch(kind)] } +
              entry.fetch("reports").each_with_index.map { |report, number| ["report-#{number}", report.fetch("file")] }
            selected.map do |kind, source|
              content = work.files.fetch(source.fetch("filename"))
              filename = "context-#{index}-#{kind}.md"
              Files.write_file(directory, filename, content)
              {"task_id" => entry.fetch("task_id"), "kind" => kind, "path" => File.join(directory, filename),
                "sha256" => Digest::SHA256.hexdigest(content), "bytes" => content.bytesize}
            end
          end
          {"project_id" => context.fetch("project_id"), **selection, "scope" => context.fetch("scope"),
            "manifest_sha256" => work.manifest_sha256, "files" => inventory, "journal_commit" => data.fetch("journal_commit")}
        end

        def progress(operation:, pane:, generation:, step: nil, report: nil, message: nil)
          worker!(pane)
          params = selection.merge("expected_generation" => generation, "pane" => pane)
          parts = []
          case operation
          when "queue_start" then params["step"] = step
          when "queue_finish"
            params["step"] = step
            parts << Files.read_file(report, 65_536)
          when "queue_fail" then params["message"] = message
          else raise ArgumentError, "unknown ordinary queue operation"
          end
          mutate("progress-#{generation}", operation, params, parts)
        end

        def submit(pane:, generation:, receipt:, artifacts: [])
          worker!(pane)
          bytes = Files.read_file(receipt, 16_384)
          value = JSON.parse(bytes)
          unless value.values_at("project_id", "assignment_id", "attempt_id", "scope") ==
              context.values_at("project_id", "assignment_id", "attempt_id", "scope") &&
              value.fetch("artifacts").size == artifacts.size
            raise ArgumentError, "result receipt differs from ordinary selection"
          end
          parts = artifacts.each_with_index.map do |file, index|
            content = Files.read_file(file, Authority::TransferCodec::LIMITS.fetch(:receipt_artifacts).last)
            unless Digest::SHA256.hexdigest(content) == value.fetch("artifacts").fetch(index).fetch("sha256")
              raise ArgumentError, "result artifact differs from its receipt"
            end
            content
          end
          reply = mutate("result", "submit_result", selection.merge("expected_generation" => generation,
            "pane" => pane, "head" => value.fetch("head"), "receipt_sha256" => Digest::SHA256.hexdigest(bytes)), [bytes] + parts)
          signal_result(reply.fetch("data"))
          reply
        end

        def adopt(pane:)
          owner = supervisor
          raise ArgumentError, "ordinary result owner pane differs" unless pane == owner.fetch("binding").fetch("pane")
          observed = status
          return {"status" => "ok", "data" => observed} if %w[succeeded failed].include?(observed.fetch("state"))
          result = observed.fetch("submitted_result")
          raise AttemptErrors::EvidenceUnavailable, "ordinary worker has not submitted a result" unless result
          mutate("adopt-#{owner.fetch('generation')}", "finish", selection.merge("pane" => pane,
            "expected_generation" => observed.fetch("generation"),
            **result.slice("result_id", "receipt_digest", "head")))
        end

        def replay(input:)
          request = Files.json(input)
          expected = request["operation"] == "adopt_supervisor" ? context.slice("assignment_id") : selection
          unless request["project_id"] == context.fetch("project_id") &&
              request.fetch("params").slice("assignment_id", "attempt_id") == expected &&
              File.dirname(File.dirname(File.expand_path(input))) == File.join(@root, "requests")
            raise ArgumentError, "recovery request differs from original execution"
          end
          reply = @transport.request(input: input)
          signal_result(reply.fetch("data")) if request.fetch("operation") == "submit_result"
          reply
        end

        private

        def selection = context.slice("assignment_id", "attempt_id")

        # A filesystem watch hint is neither execution state nor a receipt.
        # Adoption never reads this file, even after restart or forged writes.
        def signal_result(result)
          name = "hint-#{SecureRandom.hex(8)}"
          Files.write_file(@root, name, JSON.generate({"hint_only" => true,
            "project_id" => context.fetch("project_id"), **selection,
            "result_id" => result.fetch("result_id")}))
          File.rename(File.join(@root, name), File.join(@root, "result-hint.json"))
          File.open(@root) { |file| file.fsync }
        ensure
          File.unlink(File.join(@root, name)) if name && File.exist?(File.join(@root, name))
        end

        def worker!(pane)
          raise ArgumentError, "ordinary worker pane differs" unless pane == context.fetch("pane")
        end

        def step(value)
          value && {"number" => value.number, "name" => value.name, "status" => value.status.to_s,
            "instructions" => value.instructions, "workflow" => value.workflow, "skill" => value.skill}
        end

        def read(operation, params)
          Dir.mktmpdir("ordinary-read-", @root) do |directory|
            Files.write_file(directory, "request.json", JSON.generate(document(operation, params, nil, [])))
            @transport.request(input: File.join(directory, "request.json"))
          end
        end

        def snapshot(operation, params)
          Dir.mktmpdir("ordinary-read-", @root) do |directory|
            Files.write_file(directory, "request.json", JSON.generate(document(operation, params, nil, [])))
            reply = @transport.request(input: File.join(directory, "request.json"), output: File.join(directory, "snapshot"))
            entries = reply.fetch("files")
            raise AttemptErrors::EvidenceUnavailable, "canonical queue snapshot count differs" unless entries.one?
            [reply, Files.read_file(entries.first.fetch("file"), Authority::PreparedWork::MAX_TOTAL)]
          end
        end

        def mutate(key, operation, params, parts = [])
          request = retain(key, operation, params, parts)
          @transport.request(input: request).merge("request" => request)
        rescue StandardError => error
          raise error.class, "#{error.message}; recover original request #{request || key} before new work"
        end

        def retain(key, operation, params, parts)
          directory = File.join(@root, "requests")
          begin
            Dir.mkdir(directory, 0o700)
          rescue Errno::EEXIST
            Authority::PrivateDirectory.verify!(directory)
          end
          raise ArgumentError, "ordinary retained operation key is invalid" unless key.match?(/\A[a-z0-9-]{1,128}\z/)
          File.open(File.join(directory, ".lock"), File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
            lock.flock(File::LOCK_EX)
            target = File.join(directory, key)
            inventory = parts.each_with_index.map { |bytes, index|
              {"file" => "part-#{index}", "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)} }
            value = document(operation, params, nil, inventory)
            if File.exist?(target)
              Authority::PrivateDirectory.verify!(target)
              original = Files.json(File.join(target, "request.json"))
              unless original.except("mutation_id") == value.except("mutation_id")
                raise ArgumentError, "retained operation changed; replay its exact request or reconcile canonical state"
              end
            else
              scratch = Dir.mktmpdir(".prepare-", directory)
              begin
                parts.each_with_index { |bytes, index| Files.write_file(scratch, "part-#{index}", bytes) }
                value["mutation_id"] = SecureRandom.hex(16)
                Files.write_file(scratch, "request.json", JSON.generate(value) + "\n")
                File.rename(scratch, target)
                File.open(directory) { |handle| handle.fsync }
              ensure
                FileUtils.remove_entry(scratch) if File.exist?(scratch)
              end
            end
            File.join(target, "request.json")
          end
        end

        def document(operation, params, mutation, parts)
          {"version" => 1, "project_id" => context.fetch("project_id"), "operation" => operation,
            "mutation_id" => mutation, "params" => params, "parts" => parts}
        end
      end
    end
  end
end
