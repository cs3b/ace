# frozen_string_literal: true

require_relative "command_run_client"
require_relative "../molecules/command_policy"

module Ace
  module Lab
    module Organisms
      # Binds the release publication to the iy6 project-command channel: the
      # configured publish command (argv pinned in the project policy) runs
      # through the authorized executor — credentials resolve only in the
      # child after its UID drop, per the iy6 contract. The staging root is
      # materialized from canonical bytes before the run; the exact directory
      # is named by the policy's own argv, never invented here.
      class OrdinaryReleasePublisher
        def initialize(project:, policy: nil, client: nil)
          @project = project
          @policy = policy || Molecules::CommandPolicy.load(project: project)
          @client = client || CommandRunClient.new(project: project)
        end

        # Writes each staged artifact's canonical bytes into the staging root
        # the publish command's argv names. Only pending and uncertain
        # artifacts are materialized; published ones need no bytes.
        def materialize(staged, root)
          require_directory = FileUtils.mkdir_p(root, mode: 0o700)
          staged.artifacts.each do |artifact_id, entry|
            next unless %w[pending uncertain].include?(entry.fetch("state"))
            path = File.join(root, "#{entry.fetch('name')}-#{entry.fetch('version')}.gem")
            raise ArgumentError, "materialized artifact already exists" if File.exist?(path)
            File.binwrite(path, entry.fetch("bytes"))
            File.chmod(0o600, path)
          end
          root
        end

        def publish(name:, version:)
          command = @policy.commands.fetch("publish") { raise ArgumentError,
            "project policy has no publish command" }
          code = @client.run(argv: command.fetch("argv"), executor: command_executor(command),
            services: nil)
          {exit_status: code, signal: nil, output: ""}
        rescue ArgumentError
          raise
        rescue StandardError
          # Unreachable channel or lost stream: the publication organism's
          # reconciliation treats this as an attempted-effect unknown.
          {exit_status: nil, signal: "unknown", output: ""}
        end

        private

        def command_executor(command)
          grant = @policy.grants.find { |entry| entry.fetch("command") == "publish" }
          grant && grant.fetch("executor")
        end
      end
    end
  end
end
