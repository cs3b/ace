# frozen_string_literal: true
require "digest"
require "ace/lab/molecules/install_manifest_loader"
require "ace/hitl/molecules/event_observation"

module Ace::Overseer::Molecules
  # The lab reads only its own incoming messages from configured project HITL
  # owners. It does not run the project coordinator's complete observation or
  # borrow that project's interpretation of the lab's recipient alias.
  class ProjectObservations
    def initialize(root: Dir.pwd, env: ENV, loader: -> { Ace::Lab::Molecules::InstallManifestLoader.load },
      hitl_config: nil)
      @root, @env, @loader = root, env, loader
      @hitl_config = hitl_config
    end

    def call(owner:, scope:, limit:)
      empty = {"events" => [], "sources" => {}}
      return empty unless @env["ACE_TOOLCHAIN"] == "installed" && File.exist?(Ace::Lab.install_manifest_path)
      document = @loader.call
      return empty unless document.dig("coordinator", "path") == File.realpath(@root)
      config = @hitl_config || Dir.chdir(@root) { Ace::Hitl::Molecules::HitlConfigLoader.load }
      address = Ace::Hitl::Molecules::HitlAddressResolver.new(config: config).resolve(owner)
      events, sources = [], {}
      document.fetch("projects").each do |project|
        id, root = project.values_at("id", "path")
        source = "project:#{id}:hitl"
        begin
          raise Ace::Overseer::Error, "project root is not canonical" unless root != @root && File.realpath(root) == root
          projection = Dir.chdir(root) do
            manager = Ace::Hitl::Organisms::HitlManager.new
            Ace::Hitl::Molecules::EventObservation.new(manager: manager).call(scope: scope, limit: limit)
          end
          projection.fetch("events").each do |row|
            recipient = row["recipient"]
            next unless recipient.is_a?(Hash) && address.all? { |key, value| recipient[key] == value }
            events << row.merge("key" => Digest::SHA256.hexdigest("#{root}:#{row.fetch('key')}"),
              "project" => id, "project_root" => root, "owner_key" => row.fetch("key"))
          end
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
      key = Digest::SHA256.hexdigest("#{root}:project-hitl")
      {"key" => key, "id" => key, "revision" => Digest::SHA256.hexdigest(revision),
       "type" => "source-health", "status" => status, "project" => id, "project_root" => root}
    end
  end
end
