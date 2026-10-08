# frozen_string_literal: true
require "ace/herdr/organisms/inbox_context_owner"
require "ace/herdr/organisms/inbox_context_server"
require "ace/assign/authority/inbox_context_original"
require "ace/assign/authority/router"
require "ace/assign/authority/server"
require_relative "../../../ace-herdr/test/support/inbox_context_owner_fixture"

module Ace
  module Assign
    # Actual owner, signed Inbox, canonical query and Server over real sockets.
    # Only installed filesystem credentials/kernel peers are controlled seams.
    module ProtectedInboxContextPipelineFixture
      include ::InboxContextEpochFixture
      class PeerKernel
        def initialize(peer); @peer = peer; end
        def live!(_identity); true; end
        def capture(_pid); @peer; end
        def same?(left, right); left == right; end
        def peer(_socket); @peer; end
      end
      class SocketFixtureWire
        def initialize(root, uid); @root, @uid = root, uid; end
        def root_path!(path, directory:, owner:)
          raise Ace::Herdr::ValidationError unless path == @root && directory && owner == @uid
        end
        def socket_identity(path)
          stat = File.lstat(path)
          raise Ace::Herdr::ValidationError unless stat.socket?
          [stat.dev, stat.ino, @uid]
        end
        def connect(path, deadline:, &block); Ace::Runtime::Molecules::ProtectedSocket.connect(path, deadline: deadline, &block); end
        def deadline(seconds); Ace::Runtime::Molecules::ProtectedSocket.deadline(seconds); end
        def write(*args, **options); Ace::Runtime::Molecules::ProtectedSocket.write(*args, **options); end
        def read(*args, **options); Ace::Runtime::Molecules::ProtectedSocket.read(*args, **options); end
      end

      def start_context_pipeline(root, context_id: "context", installed: false)
        @socket_root ||= File.realpath(Dir.mktmpdir("inbox-q-", "/tmp"))
        @context_path = installed ? @context.fetch("control_socket_path") : File.join(@socket_root, "context.sock")
        @query_path = installed ? @service.fetch("socket_path") : File.join(@socket_root, "query.sock")
        @context_listener, @query_listener = [@context_path, @query_path].map { |path| UNIXServer.new(path) }
        unless installed
          @context["owner_credentials"] = @context_peer.slice("uid", "gid", "groups")
          @context["control_socket_path"] = @context_path
        end
        state_root = File.join(root, "context-state"); Dir.mkdir(state_root, 0o700)
        config_path = File.join(root, "context-key.json")
        File.write(config_path, JSON.generate("schema" => "ace.herdr.inbox-key/v1", "context_id" => context_id, "key_generation" => 1,
          "public_key_sha256" => Digest::SHA256.hexdigest(@key.public_to_pem)))
        keys = Ace::Herdr::Molecules::InboxContextKey.new(context_id: context_id, public_key_path: @context.fetch("receipt_public_key"), config_path: config_path,
          artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: InboxContextOwnerFixture::FixtureArtifacts.new(root)))
        @context_store = Ace::Herdr::Molecules::InboxContextStore.new(root: state_root, uid: Process.uid, protection: InboxContextOwnerFixture::FixturePaths.new)
        @context_query_wire = query_wire = SocketFixtureWire.new(@socket_root, @authority_peer.fetch("uid"))
        completion = Ace::Herdr::Molecules::InboxContextCompletionClient.new(project_id: "project", mapping_id: "mapping",
          authority: @authority_peer.slice("uid", "gid", "groups").merge("socket_path" => @query_path),
          kernel: PeerKernel.new(@authority_peer), wire: query_wire)
        grants = [@authority_peer.slice("uid", "gid", "groups").merge("role" => "authority", "purposes" => %w[deliver enqueue])]
        grants << @peer.slice("uid", "gid", "groups").merge("role" => "authority", "purposes" => %w[deliver enqueue]) if @direct_fixture
        @context_keys, @context_completion, @context_grants, @context_state_root = keys, completion, grants, state_root
        @context_owner = Ace::Herdr::Organisms::InboxContextOwner.new(context_id: context_id, deliveries_dir: @context.fetch("deliveries_dir"),
          grants: grants, store: @context_store, keys: keys, kernel: @kernel, inbox: @box, completion: completion, epoch: context_owner_epoch)
        @context_owner.provision!
        client = Ace::Herdr::Molecules::InboxContextClient.new(context_id: context_id, socket_path: @context_path, owner_identity: @context_peer,
          kernel: PeerKernel.new(@context_peer), wire: SocketFixtureWire.new(@socket_root, @context_peer.fetch("uid")))
        @context_clients ||= {}
        @context_clients[context_id] = client
        @query_owner = Authority::InboxContextOriginal.new(deployment: @deployment, history: @history, authority_id: "authority",
          journals: {"project" => @journal}, kernel: @kernel)
        @query_router = Authority::Router.new(launch: @query_owner, handlers: [])
        unless installed
        @deployment.define_singleton_method(:verify_composition!) { |*args, **keywords| true }
        @deployment.define_singleton_method(:authority) { |_| {"uid" => 13000, "gid" => 13000, "groups" => [13000]} }
        selected_map = @map
        @deployment.define_singleton_method(:verify!) { |id, **| raise AttemptErrors::UnauthorizedIdentity unless id == "mapping"; selected_map }
        end
        @query_server = Authority::Server.new(authority_id: "authority", deployment: @deployment,
          lifecycle: @query_router, kernel: PeerKernel.new(@context_peer), composition: "services")
        @context_workers = []
        @context_stop = false
        @context_accept = Thread.new do
          until @context_stop
            socket = @context_listener.accept
            @context_workers << Thread.new(socket) do |connection|
              Ace::Herdr::Organisms::InboxContextServer.new(owner: @context_owner, context_id: context_id, kernel: PeerKernel.new(@authority_peer)).handle(connection)
            ensure
              connection.close
            end
          end
        rescue IOError, Errno::EBADF
          raise unless @context_stop
        end
        @query_accept = Thread.new do
          until @context_stop
            socket = @query_listener.accept
            @context_workers << Thread.new(socket) do |connection|
              raise "canonical completion queried inside lifecycle exclusion" if @launch.respond_to?(:locked) && @launch.locked
              @query_server.send(:receive, connection)
            ensure
              connection.close
            end
          end
        rescue IOError, Errno::EBADF
          raise unless @context_stop
        end
      end

      def stop_context_pipeline
        @context_stop = true
        [@context_listener, @query_listener].each { |listener| listener&.close }
        [@context_accept, @query_accept].each { |thread| thread&.value }
        @context_workers&.each(&:value)
        @context_store&.close
        FileUtils.remove_entry(@socket_root) if @socket_root && File.exist?(@socket_root)
        @socket_root = @context_clients = nil
      end

    end
  end
end
