# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "ace/assign/organisms/prepared_work_builder"
require "ace/assign/authority/launch_driver"
require_relative "../molecules/protected_selection"
require_relative "../molecules/launch_request"
require_relative "../molecules/original_launch_child"
require_relative "protected_status"

module Ace
  module Overseer
    module Organisms
      # Compose existing owners. Retained handles are process-local observation,
      # never another authority/progress ledger or a replacement-launch grant.
      class ProtectedWorkOn
        attr_reader :children

        def initialize(selection: nil, status: nil, builder_factory: nil, driver_factory: nil,
          child_factory: nil, task_manager: nil, request_root: nil, head_reader: nil, pause: nil)
          @selection = selection || Molecules::ProtectedSelection.new
          @status = status || ProtectedStatus.new
          @builder_factory = builder_factory || ->(root) { Ace::Assign::Organisms::PreparedWorkBuilder.new(export_root: root) }
          @driver_factory = driver_factory || ->(id, deployment) { Ace::Assign::Authority::LaunchDriver.new(mapping_id: id, deployment: deployment) }
          @child_factory = child_factory || -> { Molecules::OriginalLaunchChild.new }
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
          @root = File.expand_path(request_root || File.join(Dir.pwd, ".ace-local", "overseer", "launch-requests"))
          @head_reader = head_reader || -> do
            result = Ace::Git::Atoms::CommandExecutor.execute("git", "rev-parse", "HEAD")
            raise Error, "Exact launch base is unavailable" unless result.fetch(:success)
            result.fetch(:output).strip
          end
          @pause = pause || -> { sleep 0.1 }
          @children = {}
        end

        def start(task_ref:, project:, agent: nil, runtime: "auto", dependency_reports: [], mutation_id: nil, base_head: nil, report:)
          raise Error, "Protected launch requires Herdr; tmux cannot allocate protected work" unless %w[auto herdr].include?(runtime)
          deployment, pool, visible = @selection.call(project: project, agent: agent)
          ids = agent ? [agent] : visible
          raise Error, "Protected project has no visible mapping" if ids.empty?
          mapping = nil
          ids.each do |id|
            begin
              preflight = @driver_factory.call(id, deployment).preflight
            rescue Ace::Assign::AttemptErrors::UnauthorizedIdentity
              raise if agent
              next # Attributable readonly refusal; no retained/canonical effect.
            end
            unless preflight.is_a?(Hash) && preflight.values_at("project_id", "runtime", "supported") == [project, "herdr", true]
              raise Error, "Protected Herdr capability is unavailable"
            end
            mapping = id
            break
          end
          raise Error, "No visible protected mapping admits this launcher" unless mapping
          task = @tasks.show(task_ref)
          raise Error, "Protected leaf task is unavailable" unless task
          captured_head = @head_reader.call
          unless captured_head.is_a?(String) && captured_head.match?(/\A[0-9a-f]{40}\z/) && (base_head.nil? || base_head == captured_head)
            raise Error, "Explicit reviewed code base differs from current source head"
          end
          base_head = captured_head
          mutation = mutation_id || SecureRandom.hex(16)
          unless mutation.is_a?(String) && mutation.match?(Molecules::LaunchRequest::MUTATION)
            raise Error, "Retained invocation ID is invalid"
          end
          raise Error, "Original invocation already has a child" if children.key?(mutation)
          FileUtils.mkdir_p(@root, mode: 0700)
          owner = Molecules::LaunchRequest.new(root: @root)
          prepared = @builder_factory.call(@root).call(task_ref: task.id, project_id: project, dependency_reports: dependency_reports)
          raise Error, "Code base changed during prepared input capture" unless @head_reader.call == base_head
          request = owner.publish(project_id: project, mapping_id: mapping, task_id: task.id, base_head: base_head, mutation_id: mutation, prepared: prepared)
          owner.verify_fresh!(request)
          identity = owner.identity(request)
          # The caller must write and flush this mandatory identity before any
          # child or canonical mutation. Reporting failure remains zero-child.
          report.call(identity.merge("provisioned_capacity" => pool.size, "visible_capacity" => visible.size,
            "visibility" => pool == visible ? "complete" : "partial"))
          owner.verify_fresh!(request)
          raise Error, "Code base changed before original child" unless @head_reader.call == base_head
          child = @child_factory.call
          children[mutation] = child
          child.start(request: request, definition_path: owner.definition_path(request), bundle_path: identity.fetch("prepared_bundle_path"))
          child.await_ready(status: @status)
          {"input" => identity, "child" => child}
        end

        # Keep one living owner through uncertainty. Reaping the original child
        # is not terminal/release proof and does not authorize display cleanup.
        def serve(child)
          until child.state == "exited"
            child.observe
            @pause.call unless child.state == "exited"
          end
          child
        end
      end
    end
  end
end
