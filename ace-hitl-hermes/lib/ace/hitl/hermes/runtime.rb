# frozen_string_literal: true

require "yaml"
require "ace/hitl/lifecycle"
require_relative "../hermes"

module Ace
  module Hitl
    module Hermes
      class Runtime
        attr_reader :registry, :journal, :relay, :config

        # @param credential_path_verifier [Object] the provisioning-layout
        #   verifier for remote-channel deployment facts (production:
        #   CredentialPathPolicy; tests inject a recording seam, mirroring
        #   the euid_provider pattern)
        def initialize(path, clock: -> { Time.now.utc }, credential_path_verifier: nil)
          @clock = clock
          @config_path = File.expand_path(path)
          @credential_path_verifier = credential_path_verifier
          @config = JSON.parse(File.read(path))
          unless @config.is_a?(Hash) && @config["schema"] == "ace.hitl.hermes.runtime/v1"
            raise ContractError, "runtime configuration requires runtime/v1"
          end
          @registry = Transport::Registry.load(@config.fetch("registry"))
          @journal = Transport::Journal.new(@config.fetch("state"))
          @lifecycle_routes = build_lifecycle_routes
          verify_tls_deployment! if @lifecycle_routes.values.any? { |route| route.key?(:endpoint) }
          @lifecycle_clients = {}
          @relay = Transport::Relay.new(registry: @registry, journal: @journal,
            lifecycle_for: ->(channel) { lifecycle_for(channel) },
            sender: ->(channel, question) { telegram.call(channel, question) }, clock: @clock)
        rescue JSON::ParserError, KeyError, SystemCallError, ArgumentError
          raise ContractError, "runtime configuration is unavailable or malformed"
        end

        def serve(once: false)
          verify_polling_owner!
          verify_authorities!
          @journal.actor do
            surface_registration_gaps
            poller = Transport::Poller.new(relay: @relay, telegram: telegram, journal: @journal,
              registry: @registry, clock: @clock)
            # Establish the new coverage epoch before issuing questions, so
            # a startup submission is never stamped before its coverage begins.
            begin
              poller.once
            rescue ContractError
              raise if once
            end
            loop do
              # Only an authoritative lifecycle request may be submitted.
              # A sender label is not authority or a reserved OS username.
              @registry.channels.each do |channel|
                box_channel = Molecules::HermesChannels::Channel.new(
                  name: channel["name"], machine: channel["machine"], folder: channel["folder"]
                )
                box = Organisms::HermesBox.new(channel: box_channel)
                begin
                  publish_pending(channel, box)
                rescue Ace::Hitl::Lifecycle::TransportError => e
                  raise if once
                  warn "ace-hitl-hermes: pending publication unavailable for #{channel['name']} (#{e.class}); retrying"
                  sleep 1
                  next
                end
                box.poll.messages.each do |message|
                  next unless message.question?
                  begin
                    facts = lifecycle_for(channel).read(message.id)
                    revision = facts["proposal"] ? facts.fetch("proposal").fetch("revision_id") : facts.fetch("attempt")
                    @relay.submit(channel: channel["name"], request: message.id, revision: revision)
                  rescue StandardError
                    # Pending folder + visible delivery status are retained.
                  end
                end
              end
              begin
                poller.once
              rescue ContractError
                raise if once
                sleep 1
              end
              reconcile_proposals
              break if once
            end
          end
        end

        def verify_polling_owner!
          unless @config["polling_owner"] == "ace-hitl-hermes"
            raise ContractError, "serve requires explicit polling_owner ace-hitl-hermes"
          end
          path = @config.fetch("hermes_gateway_config")
          gateway = YAML.safe_load_file(path, aliases: false)
          unless gateway.is_a?(Hash) && gateway.dig("platforms", "telegram", "enabled") == false
            raise ContractError, "disable Telegram in the configured Hermes gateway before starting serve"
          end
        rescue KeyError, SystemCallError, Psych::Exception
          raise ContractError, "cannot verify Hermes gateway Telegram polling is disabled"
        end

        private

        # Activation is atomic at the poller (spec 8xa.t.nh0): no
        # channel is enabled until every configured authority passes an
        # authenticated health and project-binding check through its own
        # route — Unix peer credentials or the verified mTLS identity.
        def verify_authorities!
          @registry.channels.each do |channel|
            client = lifecycle_for(channel)
            begin
              client.ping
              channel.fetch("projects").each { |project| client.pending(project: project) }
            rescue Ace::Hitl::Lifecycle::Error => e
              raise ContractError,
                "channel #{channel['name']} authority failed the activation health check (#{e.class})"
            end
          end
        end

        def build_lifecycle_routes
          default_socket = @config.fetch("hitl_socket")
          unless default_socket.is_a?(String) && File.absolute_path?(default_socket)
            raise ContractError, "runtime requires an absolute default HITL socket"
          end
          identities = {}
          @registry.channels.to_h do |channel|
            route = if (endpoint = channel["hitl_endpoint"])
              build_remote_route(channel, endpoint)
            else
              socket = channel.fetch("hitl_socket", default_socket)
              service_uid = channel.fetch("hitl_service_uid")
              if identities.key?(socket) && identities[socket] != service_uid
                raise ContractError, "one HITL socket cannot declare multiple service identities"
              end
              identities[socket] = service_uid
              {socket_path: socket, service_uid: service_uid}
            end
            [channel["name"], route.freeze]
          end.freeze
        end

        # The remote route binds the exact tls+tcp:// endpoint and the
        # channel's exact resolved client credential; clients cache per
        # endpoint PLUS credential identity.
        def build_remote_route(channel, endpoint)
          dns, port = Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(endpoint)
          {
            endpoint: {dns: dns, port: port},
            tls_client_credential: Ace::Hitl::Lifecycle::TlsCredentials.parse_client(
              channel.fetch("tls_client_credential"))
          }
        rescue Ace::Hitl::Lifecycle::Error => e
          raise ContractError, "remote channel #{channel['name'].inspect}: #{e.message}"
        end

        # The host deployment of the crossing must match the exact
        # provisioning layout BEFORE any connection: the runtime and
        # registry files are root:<service-group> 0640 and every
        # referenced client credential tree follows the exact
        # ownership/mode rules. Any violation refuses startup.
        def verify_tls_deployment!
          @tls_service_user = @config["tls_service_user"]
          @tls_service_group = @config["tls_service_group"]
          unless @tls_service_user.is_a?(String) && @tls_service_user.match?(/\A[a-z_][a-z0-9_-]{0,31}\z/) &&
              @tls_service_group.is_a?(String) && @tls_service_group.match?(/\A[a-z_][a-z0-9_-]{0,31}\z/)
            raise ContractError,
              "the Hermes runtime requires tls_service_user and tls_service_group for remote channels"
          end
          begin
            policy = @credential_path_verifier || Ace::Hitl::Lifecycle::CredentialPathPolicy.new(
              service_user: @tls_service_user, service_group: @tls_service_group)
            policy.verify_runtime_file!(@config_path)
            policy.verify_runtime_file!(@config.fetch("registry"))
            @lifecycle_routes.values.select { |route| route.key?(:endpoint) }
              .map { |route| route.fetch(:tls_client_credential) }.uniq.each do |credential|
              policy.verify_credential_tree!(credential)
            end
          rescue Ace::Hitl::Lifecycle::Error => e
            raise ContractError, "the Hermes TLS deployment is not provisioned (#{e.message})"
          end
        end

        def lifecycle_for(channel)
          name = channel.is_a?(Hash) ? channel.fetch("name") : channel.to_s
          route = @lifecycle_routes.fetch(name)
          @lifecycle_clients[route] ||= build_client(route)
        end

        def build_client(route)
          if route.key?(:endpoint)
            Transport::TlsClient.new(endpoint: route[:endpoint], credential: route.fetch(:tls_client_credential))
          else
            Ace::Hitl::Lifecycle::Client.new(**route)
          end
        end

        def surface_registration_gaps
          at = @clock.call.utc.iso8601
          @relay.surface_registration_gaps(at: at).each do |gap|
            warn "ace-hitl-hermes: registered #{gap['channel']} (chat #{gap['chat_id']}) after " \
              "#{gap['count']} skipped Telegram updates (#{gap['first_update_id']}-#{gap['last_update_id']}); " \
              "ingress coverage starts generation #{gap['coverage_generation']}"
          end
        end

        # The installed transport owns publication as well as Telegram polling.
        # Ask writes only scoped lifecycle state; no hidden Lab watcher or
        # HITL→Hermes dependency is required to get a question into message.v1.
        def publish_pending(channel, box)
          lifecycle = lifecycle_for(channel)
          channel["projects"].each do |project|
            lifecycle.pending(project: project).each do |facts|
              next unless facts["state"] == "created"
              envelope = Ace::Hitl::Contract::ManagedEnvelope.load(facts.fetch("envelope"), expected: {
                request_id: facts["id"], project: project, assignment_id: facts["assignment"], attempt_id: facts["attempt"]
              })
              status = @relay.delivery(channel: channel["name"], request: facts["id"])["status"]
              next unless %w[unknown failed].include?(status)
              existing = box.poll.messages.find { |message| message.id == facts["id"] }
              if existing
                unless existing.question? && existing.body == facts["question"]
                  raise ContractError, "managed question folder identity conflicts"
                end
                next
              end
              box.publish(kind: :question, id: facts["id"], body: facts["question"], sender: envelope["requester"],
                timestamp: Time.at(Integer(facts["created_at"])).utc.iso8601)
            end
          end
        rescue Ace::Hitl::Contract::InvalidEnvelope, KeyError, ArgumentError => e
          raise ContractError, "managed pending publication binding is invalid (#{e.class})"
        end

        def reconcile_proposals
          @registry.channels.each do |channel|
            begin
              lifecycle = lifecycle_for(channel)
              channel.fetch("projects").each do |project|
                after = nil
                loop do
                  page = lifecycle.proposal_due(project: project, after: after)
                  page.fetch("items").each do |proposal|
                    @relay.reconcile(channel: channel.fetch("name"), request: proposal.fetch("request_id"),
                      through: proposal.fetch("deadline"))
                  end
                  cursor = page.fetch("next")
                  break unless cursor
                  unless cursor.is_a?(String) && (!after || cursor > after)
                    raise ContractError, "proposal deadline cursor did not advance"
                  end
                  after = cursor
                end
              end
            rescue Ace::Hitl::Lifecycle::Error, ContractError => e
              warn "ace-hitl-hermes: proposal reconciliation unavailable for #{channel['name']} " \
                "(#{e.class}); deadlines deferred"
            end
          end
        end

        def telegram
          @telegram ||= Transport::Telegram.new(token_file: @config.fetch("token_file"))
        end
      end
    end
  end
end
