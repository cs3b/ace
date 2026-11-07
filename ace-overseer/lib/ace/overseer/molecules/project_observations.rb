# frozen_string_literal: true
require "digest"
require "json"
require_relative "../atoms/observation_sources"
require "ace/lab/molecules/install_manifest_loader"
require "ace/herdr/molecules/bounded_process"
require "ace/support/cli/toolchain"

module Ace::Overseer::Molecules
  # The lab reads the same public projection as each configured project.
  # Tasks, reports and assignments remain in that project's existing owners.
  class ProjectObservations
    BUDGET_SECONDS = 20
    def initialize(root: Dir.pwd, env: ENV, loader: -> { Ace::Lab::Molecules::InstallManifestLoader.load },
      runner: Ace::Herdr::Molecules::BoundedProcess.method(:call),
      clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @root, @env, @loader, @runner, @clock = root, env, loader, runner, clock
    end

    def call(owner:, scope:, limit:)
      empty = {"events" => [], "sources" => {}}
      return empty unless @env["ACE_TOOLCHAIN"] == "installed" &&
        (@env["ACE_LAB_SESSION"] == "1" || File.exist?(Ace::Lab.install_manifest_path))
      document = @loader.call
      return empty unless document.dig("coordinator", "path") == File.realpath(@root)
      events, sources = [], {}
      deadline = @clock.call + BUDGET_SECONDS
      document.fetch("projects").each do |project|
        id, root = project.values_at("id", "path")
        source = "project:#{id}"
        begin
          raise Ace::Overseer::Error, "project root is not canonical" unless root != @root && File.realpath(root) == root
          remaining = deadline - @clock.call
          raise Timeout::Error, "project observation budget exhausted" unless remaining.positive?
          result = @runner.call([Ace::Support::Cli::Toolchain.executable("ace-overseer"), "observe",
            "--owner", owner, "--scope", scope, "--limit", limit.to_s],
            environment: @env.to_h.merge(Ace::Support::Cli::Toolchain.child_environment).compact,
            chdir: root, timeout_s: remaining, output_limit: 2_097_152, cleanup_group: true)
          raise Ace::Overseer::Error, "project observation failed" unless result.status.success? && !result.oversized
          value = JSON.parse(result.stdout)
          unless value["schema"] == "ace.hitl.observation/v1" && value["events"].is_a?(Array) &&
              value["settled"].is_a?(Array) && value["sources"].is_a?(Hash) &&
              (Ace::Overseer::Atoms::ObservationSources::REQUIRED - value["sources"].keys).empty?
            raise Ace::Overseer::Error, "project observation is incomplete"
          end
          rows = (value.fetch("events") + value.fetch("settled")).map do |row|
            unless row.is_a?(Hash) && %w[key revision id type].all? { |key| row[key].is_a?(String) }
              raise Ace::Overseer::Error, "project event is incomplete"
            end
            row.merge("key" => Digest::SHA256.hexdigest("#{root}:#{row.fetch('key')}"),
              "project" => id, "project_root" => root, "owner_key" => row.fetch("key"))
          end
          health = value.fetch("sources").to_h do |name, state|
            unless name.is_a?(String) && name.match?(/\A[a-zA-Z0-9_.:-]{1,64}\z/) &&
                state.is_a?(Hash) && %w[ok degraded].include?(state["status"])
              raise Ace::Overseer::Error, "project source health is incomplete"
            end
            ["#{source}:#{name}", state]
          end
          events.concat(rows)
          sources.merge!(health)
          sources[source] = {"status" => "ok"}
          events << project_health(root, id, "ok")
        rescue StandardError => error
          sources[source] = {"status" => "degraded", "error" => error.class.name}
          events << project_health(root, id, "degraded", error.class.name)
        end
      end
      {"events" => events, "sources" => sources}
    end

    private

    def project_health(root, id, status, revision = status)
      key = Digest::SHA256.hexdigest("#{root}:project-observation")
      {"key" => key, "id" => key, "revision" => Digest::SHA256.hexdigest(revision),
       "type" => "source-health", "status" => status, "project" => id, "project_root" => root}
    end
  end
end
