# frozen_string_literal: true
require_relative "endcap_result_owner_fixture"
require_relative "prepared_workspace_resource_fixture"
require_relative "execution_boot_baseline_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/assign/authority/prepared_input"

module Ace
  module Assign
    module ProtectedCampaignFixture
      include EndcapResultOwnerFixture
      include PreparedWorkspaceResourceFixture
      include ExecutionBootBaselineOwnerFixture

      # The protected filesystem boundary is injected; held bytes, inode
      # replacement, Git bundles, sockets and canonical journal remain real.
      class ArtifactProtection
        def root_path!(_path); end
        def verify!(path, handle, directory:)
          raise Ace::Runtime::RuntimeUnavailableError, "unsafe fixture mode" unless
            (handle.stat.mode & 0o022).zero? && (directory ? handle.stat.directory? : handle.stat.file?)
        end
      end

      def fixture(**options, &block)
        baseline = -> { fixture_boot_baseline_reader(protection: ArtifactProtection.new) }
        Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, baseline) { super(**options, &block) }
      end

      def configure_result_owner_fixture
        File.chmod(0700, @journal.repo_root)
        @project["campaign_repository"] = @journal.repo_root
        @project["campaign_store_root"] = File.join(@root, "campaign-store")
        @campaign_manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @journal.repo_root,
          store: Ace::Review::Molecules::CampaignStore.new(root: @project.fetch("campaign_store_root")))
        @campaign_policy = @campaign_requested_policy || {"revision" => "delivery-v1", "minimum_rounds" => 3, "clean_rounds" => 2,
          "required_scopes" => ["full"], "required_checks" => ["tests"]}
        @campaign = @campaign_manager.start(subject: {"repository" => "local:#{@journal.repo_root}", "local_candidate_id" => "candidate"},
          contract: "Reviewed parent requirements", policy: @campaign_policy)
        File.chmod(0700, @project.fetch("campaign_store_root"))
        set_current_policy(@campaign_policy)
        parent_map = @map
        child_map = @map.merge("worker_cwd" => "/fixture/child-worker", "execution_scope" => @map.fetch("execution_scope").merge("slot_id" => "child-slot"))
        @deployment.define_singleton_method(:mapping) { |id| {"mapping" => parent_map, "child-mapping" => child_map}.fetch(id) }
        @deployment.define_singleton_method(:verify!) { |id, **_| mapping(id) }
        @deployment.define_singleton_method(:mapping_digest) { |id| Atoms::EvidenceDigest.digest(mapping(id)) }
        installer_bytes = "original controlled installer artifact"
        installer_path = File.join(@root, "retained-installer")
        File.binwrite(installer_path, installer_bytes)
        installer = {"path" => installer_path, "sha256" => Digest::SHA256.hexdigest(installer_bytes), "bytes" => installer_bytes.bytesize}
        @campaign_network = ExecutionScopeObservationFixtures::NETWORK_SELECTION.merge("installer_artifact" => installer)
        @campaign_boot = {"mapping" => parent_map, "child-mapping" => child_map}.to_h { |id, map|
          [id, retained_boot_baseline_artifact(root: File.realpath(@root), name: "#{id}-boot.json", map: map, installer: installer)] }
        @campaign_workspace = {"mapping" => configure_original_workspace_resource,
          "child-mapping" => configure_original_workspace_resource(mapping_id: "child-mapping", map: child_map)}
      end

      def set_current_policy(policy)
        bytes = JSON.generate("schema" => "ace.review.consumer-policy/v1", "profiles" => {"delivery" => policy})
        path = File.join(@root, "consumer-#{Digest::SHA256.hexdigest(bytes)}.json")
        File.binwrite(path, bytes); File.chmod(0600, path)
        @project["campaign_policy"] = {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end

      def candidate(_number); end

      def restart
        super
        launch = @launch
        @launch.instance_variable_set(:@scope_observer_factory, ->(id) {
          map = @deployment.mapping(id)
          installation = ExecutionScopeObservationFixtures::NETWORK_OUTPUT.merge("slot_id" => map.fetch("execution_scope").fetch("slot_id"),
            "installer_artifact_sha256" => @campaign_network.fetch("installer_artifact").fetch("sha256"))
          ExecutionScopeNativeOwnerFixture.new(map, @journal, @kernel, owner: launch,
            mapping_id: id, network_installation: installation, network_selection: @campaign_network, boot_baseline_selection: @campaign_boot.fetch(id),
            workspace_observer: @campaign_workspace.fetch(id).fetch(:observer),
            resource_identities: @campaign_workspace.fetch(id).fetch(:resources),
            parent_declarations: @campaign_workspace.fetch(id).fetch(:declarations))
        })
      end

      def call(operation, params, **options)
        if operation == "register_assignment"
          value = JSON.parse(params.fetch("definition_bytes"))
          value["review_campaign"] = {"version" => 1}.merge(@campaign.slice("campaign_id", "subject", "contract_identity"))
            .merge("policy" => @campaign.fetch("effective_policy"))
          bytes = JSON.generate(value)
          params = params.merge("definition_bytes" => bytes, "definition_digest" => Digest::SHA256.hexdigest(bytes))
        end
        super(operation, params, **options)
      end

      def start_public_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        kernel = Kernel.new; kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
      end

      def child_definition(id, execution)
        {"session_id" => id, "name" => "campaign child", "created_at" => "2026-10-08T00:00:00Z",
          "source_config" => "job.yaml", "task_id" => "task", "project_id" => "project",
          "parent" => "assignment", "campaign_execution" => execution}
      end

      def register_child(id, execution, mutation:, expected_generation: 0)
        work = PreparedRegistrationFixture.build(root: @root, definition: child_definition(id, execution), scope: "010")
        work.with_input(root: @root) do |_input, _descriptor|
          @client.call("register_assignment", work.header(expected_generation: expected_generation), mutation_id: mutation,
            upload_parts: [work.bundle], purpose: :candidate, timeout: 30)
        end
      end

    end
  end
end
