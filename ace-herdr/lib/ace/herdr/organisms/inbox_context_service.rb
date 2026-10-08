# frozen_string_literal: true

require_relative "../molecules/codex_runtime_selection"

require_relative "../molecules/inbox_context_native_process"
require_relative "../molecules/inbox_context_completion_client"
require_relative "../molecules/native_queue_executor"
require_relative "../molecules/herdr_executor"
require_relative "inbox_context_server"
require_relative "inbox_context_listener"

module Ace
  module Herdr
    module Organisms
      # The generated fixed entry calls these distinct methods only after its
      # SAME installation owner selects normal start or retained initialization.
      # There is no caller-supplied Inbox, epoch or native executable fallback.
      class InboxContextService
        ASSOCIATION = %i[cgroups codex_runtime configuration installation kernel manager].freeze
        attr_reader :epoch, :configuration

        def initialize(configuration:, epoch:, association:, listener:, store:)
          @configuration, @epoch, @listener, @store = configuration, epoch, listener, store
          @association = association.slice(:cgroups, :configuration, :installation, :kernel, :manager).freeze
        end

        def serve
          observed = Molecules::InboxContextLifetime.new(**@association).capture_epoch!
          raise ValidationError, "context service epoch changed before ingress" unless observed == @epoch
          @listener.serve
        ensure
          close
        end

        def close
          raise ValidationError, "context service handlers remain unresolved" unless @listener.quiescent?
          @store.close
        end

        def self.start!(stage:, installation:, bootstrap:)
          run!(stage: stage, installation: installation, bootstrap: bootstrap, initialize_context: false)
        end

        def self.provision!(stage:, installation:, bootstrap:)
          run!(stage: stage, installation: installation, bootstrap: bootstrap, initialize_context: true)
        end

        def self.run!(stage:, installation:, bootstrap:, initialize_context:)
          configuration = Molecules::InboxContextServiceConfiguration.load(stage: stage)
          Molecules::CodexRuntimeSelection.with(stage_reference: configuration.codex_runtime_reference,
            configuration: configuration, installation: installation, bootstrap: bootstrap) do |codex_runtime|
            constructed = nil
            owner_method = initialize_context ? :with_initial_inbox_context : :with_inbox_context_service
            prepared = bootstrap.public_send(owner_method, configuration: configuration, installation: installation, codex_runtime: codex_runtime) do |association|
              unless association.is_a?(Hash) && association.keys.sort == ASSOCIATION && association.frozen? &&
                  association.fetch(:configuration).is_a?(Molecules::InboxContextServiceConfiguration) &&
                  association.fetch(:configuration).reference == configuration.reference && association.fetch(:configuration).data == configuration.data &&
                  association.fetch(:codex_runtime).equal?(codex_runtime) && codex_runtime.static_association.all? { |key, value|
                    association.fetch(key).equal?(value) }
                raise ValidationError, "context service owner association differs"
              end
              selected = association.fetch(:configuration)
              clients = selected.data.fetch("native_clients")
              association.fetch(:installation).verify_inbox_native_projection!(
                references: clients.values_at("codex", "pi", "herdr", "codex_runtime_intent") + clients.fetch("dependencies"),
                resources: clients.fetch("resources"), manager: association.fetch(:manager))
              lifetime = Molecules::InboxContextLifetime.new(**association.slice(:cgroups, :configuration, :installation, :kernel, :manager))
              epoch = lifetime.capture_epoch!
              data = selected.data
              keys = Molecules::InboxContextKey.new(context_id: data.fetch("inbox_context_id"),
                public_key_path: data.fetch("key").fetch("public_key_path"), config_path: data.fetch("key").fetch("configuration_path"))
              key = keys.selected
              process = Molecules::InboxContextNativeProcess.new(configuration: selected)
              process.verify!
              inbox = Inbox.new(deliveries_dir: data.fetch("deliveries_dir"), receipt_public_key: key.fetch(:key),
                executor: Molecules::HerdrExecutor.new(binary: clients.fetch("herdr").fetch("path"), process: process),
                native: Molecules::NativeQueueExecutor.new(codex_runtime: association.fetch(:codex_runtime),
                  pi_client: clients.fetch("pi").fetch("path"), process: process))
              store = Molecules::InboxContextStore.new(root: data.fetch("state_root"), uid: data.fetch("owner_credentials").fetch("uid"))
              owner = InboxContextOwner.new(context_id: data.fetch("inbox_context_id"), deliveries_dir: data.fetch("deliveries_dir"),
                grants: data.fetch("grants"), store: store, keys: keys, epoch: epoch, kernel: association.fetch(:kernel), inbox: inbox,
                completion: Molecules::InboxContextCompletionClient.new(authority: data.fetch("authority"),
                  project_id: data.fetch("project_id"), mapping_id: data.fetch("native_mapping_id"), kernel: association.fetch(:kernel)))
              if initialize_context
                begin
                  owner.provision!
                rescue Molecules::InboxContextStore::AlreadyProvisioned
                  owner.observe_initialized_epoch!
                end
              else
                owner.activate_epoch!
              end
              server = InboxContextServer.new(owner: owner, context_id: data.fetch("inbox_context_id"), kernel: association.fetch(:kernel))
              listener = InboxContextListener.new(configuration: selected, server: server, kernel: association.fetch(:kernel),
                handler_dispatcher: codex_runtime.handler_dispatcher(limit: InboxContextListener::MAX_HANDLERS))
              constructed = new(configuration: selected, epoch: epoch, association: association, listener: listener, store: store)
            rescue Exception
              store&.close
              raise
            end
            # The initial owner completes its bounded existing Installer phase
            # before returning this prepared instance. It cannot retain operator
            # exclusion through the listener's unbounded serving lifetime.
            unless prepared.is_a?(self) && prepared.configuration.reference == configuration.reference
              raise ValidationError, "context service startup acknowledgement differs"
            end
            prepared.serve
          ensure
            constructed&.close if constructed.is_a?(self)
          end
        end
        private_class_method :run!
        private_class_method :new
      end
    end
  end
end
