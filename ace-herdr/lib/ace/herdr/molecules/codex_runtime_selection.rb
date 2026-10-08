# frozen_string_literal: true

require "digest"
require "fiddle"
require "securerandom"
require "ace/runtime/molecules/protected_artifact_set"
require "ace/runtime/molecules/protected_linux"
require_relative "inbox_context_service_configuration"
require_relative "codex_app_server_transport"

module Ace
  module Herdr
    module Molecules
      # Dynamic data is held separately from the immutable static installation.
      # Only the accepted original bootstrap may supply the static association.
      class CodexRuntimeSelection
        FIELDS = %w[configuration inbox_context_id installation intent native_mapping_id previous_runtime_reference
          project_id provider provider_version runtime_generation schema server_process_binding socket_gid socket_path thread_id].sort.freeze
        STATIC_ASSOCIATION = %i[cgroups configuration installation kernel manager].freeze
        BINDING_FIELDS = %w[gid groups host parent_pid pid started_at uid].freeze
        SUBMISSION_FIELDS = %w[attempt_id claim_generation client_user_message_id endpoint_reference_sha256 event_id
          payload_sha256 provider_version schema server_process_binding thread_id].freeze
        LIMIT = 65_536
        OUTPUT_ROOT = "/var/lib/lab/herdr-native-artifacts/codex"
        INTENT_FIELDS = %w[codex credentials cwd dependencies environment home inbox_context_id native_mapping_id project_id schema socket_gid socket_path thread_configuration unit_name].sort.freeze
        BOOT_BIRTH = /\Alinux:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:[1-9][0-9]*\z/
        attr_reader :data, :reference, :static_association

        class EndpointProtection
          def initialize(mounts: Ace::Runtime::Molecules::CgroupObservation::KernelFiles.new)
            @mounts = mounts
          end

          def with(path, uid:, gid:)
            handles = []
            parent = File.dirname(path)
            unless uid.is_a?(Integer) && uid.positive? && gid.is_a?(Integer) && gid.positive? && parent != "/"
              raise ValidationError, "Codex endpoint native principal differs"
            end
            # Only this final directory is writable by the exact selected native
            # process. Its root-owned parent prevents directory replacement;
            # every ancestor keeps the ordinary root protection policy.
            Ace::Runtime::Molecules::ProtectedSocket.root_path!(File.dirname(parent), directory: true)
            current = parent
            loop do
              directory = File.open(current, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
              handles << [current, directory, identity(directory.stat)]
              stat = directory.stat
              unless stat.directory? && stat.uid == (current == parent ? uid : 0) && (stat.mode & 0o022).zero? &&
                  (current != parent || stat.gid == gid && (stat.mode & 0o7777) == 0o750) &&
                  Ace::Runtime::Molecules::ProtectedArtifactSet::Protection::FILESYSTEMS.include?(
                    @mounts.mount_identity(directory).fetch("filesystem_type"))
                raise ValidationError, "Codex endpoint parent protection differs"
              end
              acl_absent!(current, "system.posix_acl_access")
              acl_absent!(current, "system.posix_acl_default")
              break if current == "/"
              current = File.dirname(current)
            end
            socket = File.lstat(path)
            unless socket.socket? && !socket.symlink? && socket.uid == uid && socket.gid == gid &&
                (socket.mode & 0o7777) == 0o660
              raise ValidationError, "Codex endpoint leaf protection differs"
            end
            acl_absent!(path, "system.posix_acl_access")
            selected = {path: path, socket: identity(socket), ancestors: handles}.freeze
            verify!(selected)
            yield selected
            verify!(selected)
          ensure
            handles&.reverse_each { |_, handle, _| handle.close unless handle.closed? }
          end

          def verify!(selected)
            unless identity(File.lstat(selected.fetch(:path))) == selected.fetch(:socket) &&
                selected.fetch(:ancestors).all? { |path, handle, original|
                  !handle.closed? && identity(handle.stat) == original && identity(File.lstat(path)) == original }
              raise ValidationError, "Codex endpoint changed during observation"
            end
            acl_absent!(selected.fetch(:path), "system.posix_acl_access")
            selected.fetch(:ancestors).each do |path, _, _|
              acl_absent!(path, "system.posix_acl_access")
              acl_absent!(path, "system.posix_acl_default")
            end
            true
          end

          private

          def identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode].freeze

          def acl_absent!(path, attribute)
            raise ValidationError, "Codex ACL observation requires Linux" unless RUBY_PLATFORM.include?("linux")
            function = Fiddle::Function.new(Fiddle::Handle::DEFAULT["lgetxattr"],
              [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SSIZE_T)
            result = function.call(path, attribute, 0, 0)
            error = Fiddle.last_error
            unless result == -1 && error == Errno::ENODATA::Errno
              raise ValidationError, "Codex endpoint ACL is unavailable or present"
            end
          rescue Fiddle::DLError
            raise ValidationError, "Codex endpoint ACL reader unavailable"
          end
        end

        def self.with(stage_reference:, configuration:, installation:, bootstrap:,
          artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(file_limit: LIMIT, total_limit: 4 * LIMIT),
          protection: EndpointProtection.new)
          unless configuration.is_a?(InboxContextServiceConfiguration) &&
              stage_reference == configuration.codex_runtime_reference
            raise ValidationError, "Codex static configuration is not selected"
          end
          bootstrap.with_inbox_context_installation(configuration: configuration, installation: installation) do |static|
            unless static.is_a?(Hash) && static.frozen? && static.keys.sort == STATIC_ASSOCIATION &&
                static.fetch(:configuration).equal?(configuration) &&
                static.fetch(:installation).is_a?(Ace::Runtime::Molecules::ExecutionUnitInstallation)
              raise ValidationError, "Codex original static installation association differs"
            end
            artifacts.with do |held|
              selection = new(stage_reference, configuration, installation, static, held, protection)
              begin
                selection.verify!
                selection.with_connection(deadline: Ace::Runtime::Molecules::ProtectedSocket.deadline(60)) { |_socket| }
                yield selection
                selection.verify!
              ensure
                selection.send(:close!)
              end
            end
          end
        rescue KeyError, TypeError, JSON::ParserError, Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
          raise ValidationError, "Codex runtime association is unavailable"
        end

        # Only the factory owner can hand this capability to its fixed Listener.
        # Admission expires with that Listener handler block, not with possession
        # of the immutable selection by an arbitrary thread.
        def handler_dispatcher(limit:)
          active!
          unless Thread.current.equal?(@thread) && limit == 8
            raise ValidationError, "Codex handler owner or bound differs"
          end
          lambda do |deadline:, &operation|
            unless deadline.is_a?(Numeric) && deadline.finite? && deadline > monotonic
              raise ValidationError, "Codex handler deadline differs"
            end
            current = Thread.current
            @mutex.synchronize do
              unless @active && !@closing && @handlers.size < limit && !@handlers.key?(current)
                raise ValidationError, "Codex handler admission unavailable"
              end
              @handlers[current] = deadline
            end
            begin
              result = operation.call
              raise ValidationError, "Codex handler original deadline expired" unless deadline > monotonic
              result
            ensure
              @mutex.synchronize { @handlers.delete(current) }
            end
          end
        end

        def verify!
          active!
          @held.verify_unchanged!
          clients = @configuration.data.fetch("native_clients")
          @static_association.fetch(:installation).verify_inbox_native_projection!(
            references: clients.values_at("codex", "pi", "herdr", "codex_runtime_intent") + clients.fetch("dependencies"),
            resources: clients.fetch("resources"), manager: @static_association.fetch(:manager))
          unless @static_association.fetch(:installation).inbox_context_configuration_reference == @configuration.reference
            raise ValidationError, "Codex original static configuration changed"
          end
          true
        end

        def submission(event_id:, attempt_id:, claim_generation:, digest:, thread:)
          verify!
          unless [event_id, attempt_id].all? { |value| InboxContextServiceConfiguration.token?(value) } &&
              claim_generation.is_a?(Integer) && claim_generation.positive? &&
              digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/) && thread == data.fetch("thread_id")
            raise ValidationError, "Codex claim association differs"
          end
          immutable({"schema" => "ace.herdr.codex-submission/v1", "provider_version" => data.fetch("provider_version"),
            "endpoint_reference_sha256" => reference.fetch("sha256"), "server_process_binding" => data.fetch("server_process_binding"),
            "thread_id" => thread, "event_id" => event_id, "attempt_id" => attempt_id, "claim_generation" => claim_generation,
            "payload_sha256" => digest, "client_user_message_id" => "ace-#{SecureRandom.hex(16)}"})
        end

        def submit(submission:, payload:, deadline:)
          verify!
          unless submission.is_a?(Hash) && submission.keys.sort == SUBMISSION_FIELDS &&
              submission.values_at("schema", "provider_version", "endpoint_reference_sha256", "server_process_binding", "thread_id") ==
                ["ace.herdr.codex-submission/v1", data.fetch("provider_version"), reference.fetch("sha256"),
                  data.fetch("server_process_binding"), data.fetch("thread_id")] &&
              submission.fetch("payload_sha256") == Digest::SHA256.hexdigest(payload)
            raise ValidationError, "Codex retained submission association differs"
          end
          result = nil
          with_connection(deadline: deadline) do |socket|
            result = CodexAppServerTransport.new.submit(socket: socket, thread: data.fetch("thread_id"),
              client_id: submission.fetch("client_user_message_id"), payload: payload, deadline: deadline)
          end
          return result unless result.fetch("accepted")
          immutable(result.merge("provider_version" => data.fetch("provider_version"),
            "endpoint_reference_sha256" => reference.fetch("sha256"), "thread_id" => data.fetch("thread_id"),
            "server_process_binding" => data.fetch("server_process_binding")))
        rescue ValidationError, Ace::Runtime::RuntimeUnavailableError, SecurityError, IOError, SystemCallError
          {"accepted" => false, "pre_submit" => result.nil?, "error" => "Codex runtime submission unavailable"}
        end

        def with_connection(deadline:)
          verify!
          original = @mutex.synchronize { @handlers[Thread.current] }
          deadline = [deadline, original].min if original
          path, peer = data.values_at("socket_path", "server_process_binding")
          kernel = @static_association.fetch(:kernel)
          @protection.with(path, uid: peer.fetch("uid"), gid: data.fetch("socket_gid")) do |endpoint|
            Ace::Runtime::Molecules::ProtectedSocket.connect(path, deadline: deadline) do |socket|
              @protection.verify!(endpoint)
              unless kernel.same?(peer, kernel.peer(socket))
                raise ValidationError, "Codex endpoint peer is not the selected original server"
              end
              pin = kernel.pin(peer)
              begin
                kernel.live!(peer)
                raise ValidationError, "Codex server lifetime ended" if kernel.exited?(pin)
                yield socket
                verify!
                kernel.live!(peer)
                unless !kernel.exited?(pin) && kernel.same?(peer, kernel.peer(socket))
                  raise ValidationError, "Codex endpoint changed across request"
                end
                @protection.verify!(endpoint)
              ensure
                pin&.close
              end
            end
          end
        end

        private

        def initialize(reference, configuration, installation, static, held, protection)
          @active, @thread, @closing = true, Thread.current, false
          @mutex, @handlers = Mutex.new, {}
          @configuration, @static_association, @held, @protection = configuration, static, held, protection
          ref!(reference)
          ref!(installation, limit: 1_048_576)
          @reference = immutable(reference)
          @data = immutable(JSON.parse(held.read!(reference), create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false))
          validate!(installation)
        end

        def active!
          allowed = @mutex.synchronize do
            admitted_deadline = @handlers[Thread.current]
            @active && (@thread.equal?(Thread.current) || admitted_deadline && admitted_deadline > monotonic)
          end
          raise ValidationError, "Codex runtime held scope expired or handler unadmitted" unless allowed
        end

        def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        def close!
          threads = @mutex.synchronize do
            @closing = true
            @handlers.keys
          end
          # The fixed handler's original absolute budget governs its work.
          # Shutdown cannot release authenticated handles while it still runs,
          # even when Listener's shorter stop deadline has already failed.
          threads.each(&:join)
          @mutex.synchronize { @active = false }
        end

        def validate!(installation)
          unless data.is_a?(Hash) && data.keys.sort == FIELDS &&
              data.values_at("schema", "provider", "provider_version") == ["ace.herdr.codex-runtime/v1", "codex", "0.159.3"] &&
              data.values_at("project_id", "inbox_context_id", "native_mapping_id") ==
                @configuration.data.values_at("project_id", "inbox_context_id", "native_mapping_id") &&
              data.fetch("configuration") == @configuration.reference && data.fetch("installation") == installation &&
              data.fetch("runtime_generation").is_a?(Integer) && data.fetch("runtime_generation").positive? &&
              data.fetch("thread_id").is_a?(String) && CodexAppServerTransport::UUID.match?(data.fetch("thread_id"))
            raise ValidationError, "Codex runtime output fields differ"
          end
          intent = data.fetch("intent")
          unless intent == @configuration.data.fetch("native_clients").fetch("codex_runtime_intent")
            raise ValidationError, "Codex runtime static intent differs"
          end
          ref!(intent)
          # Original bootstrap validates the intent/source/installation domain
          # join; independently hold its exact raw bytes in this scope too.
          @intent = JSON.parse(@held.read!(intent), create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false)
          clients = @configuration.data.fetch("native_clients")
          unless @intent.is_a?(Hash) && @intent.keys.sort == INTENT_FIELDS &&
              @intent["schema"] == "lab.codex-runtime-intent/v1" &&
              @intent.values_at("project_id", "inbox_context_id", "native_mapping_id") ==
                data.values_at("project_id", "inbox_context_id", "native_mapping_id") &&
              @intent.values_at("codex", "cwd", "environment", "dependencies") ==
                clients.values_at("codex", "cwd", "environment", "dependencies") &&
              @intent.values_at("socket_path", "socket_gid") == data.values_at("socket_path", "socket_gid")
            raise ValidationError, "Codex static runtime intent differs"
          end
          thread_configuration = @intent.fetch("thread_configuration")
          unless InboxContextServiceConfiguration.path?(@intent.fetch("home")) &&
              @intent.fetch("unit_name").is_a?(String) &&
              @intent.fetch("unit_name").bytesize.between?(1, 255) &&
              @intent.fetch("unit_name").match?(/\A[a-zA-Z0-9_.@:-]+\.service\z/) &&
              thread_configuration.is_a?(Hash) && thread_configuration.keys.sort == %w[approval_policy model sandbox] &&
              InboxContextServiceConfiguration.token?(thread_configuration.fetch("model")) &&
              thread_configuration.values_at("approval_policy", "sandbox") == ["never", "danger-full-access"]
            raise ValidationError, "Codex static startup or thread configuration differs"
          end
          expected_path = File.join(OUTPUT_ROOT, data.fetch("project_id"), data.fetch("inbox_context_id"),
            data.fetch("native_mapping_id"), "generations", data.fetch("runtime_generation").to_s,
            reference.fetch("sha256") + ".json")
          raise ValidationError, "Codex runtime output path differs" unless reference.fetch("path") == expected_path
          @held.read!(@configuration.reference)
          previous = data.fetch("previous_runtime_reference")
          if data.fetch("runtime_generation") == 1
            raise ValidationError, "initial Codex runtime has predecessor" unless previous.nil?
          else
            ref!(previous)
            predecessor = JSON.parse(@held.read!(previous), create_additions: false, max_nesting: 32,
              allow_duplicate_key: false, allow_comments: false)
            unless predecessor.is_a?(Hash) && predecessor.keys.sort == FIELDS &&
                predecessor.values_at("schema", "provider", "provider_version") ==
                  data.values_at("schema", "provider", "provider_version") &&
                predecessor.fetch("runtime_generation").is_a?(Integer) &&
                predecessor.fetch("runtime_generation") == data.fetch("runtime_generation") - 1 &&
                previous.fetch("path") == File.join(OUTPUT_ROOT, data.fetch("project_id"), data.fetch("inbox_context_id"),
                  data.fetch("native_mapping_id"), "generations", predecessor.fetch("runtime_generation").to_s,
                  previous.fetch("sha256") + ".json") &&
                predecessor.values_at("project_id", "inbox_context_id", "native_mapping_id", "thread_id", "configuration", "intent") ==
                  data.values_at("project_id", "inbox_context_id", "native_mapping_id", "thread_id", "configuration", "intent")
              raise ValidationError, "Codex runtime predecessor differs"
            end
          end
          path = data.fetch("socket_path")
          peer = data.fetch("server_process_binding")
          unless @intent.fetch("credentials").is_a?(Hash) && @intent.fetch("credentials").keys.sort == %w[gid groups uid] &&
              peer.is_a?(Hash) && peer.slice("uid", "gid", "groups") == @intent.fetch("credentials")
            raise ValidationError, "Codex runtime principal differs from static intent"
          end
          reserved_uids = [@configuration.data.fetch("owner_credentials").fetch("uid"), @configuration.data.fetch("authority").fetch("uid")] +
            @configuration.data.fetch("grants").map { |grant| grant.fetch("uid") }
          raise ValidationError, "Codex native principal overlaps context control" if reserved_uids.include?(peer.fetch("uid"))
          unless path.is_a?(String) && path.encoding == Encoding::UTF_8 && path.valid_encoding? &&
              path.bytesize.between?(1, 107) && path.start_with?("/") && !path.include?("\0") && File.expand_path(path) == path &&
              data.fetch("socket_gid").is_a?(Integer) && data.fetch("socket_gid").positive? && peer.is_a?(Hash) &&
              peer.keys.sort == BINDING_FIELDS && peer.values_at("pid", "uid", "gid").all? { |v| v.is_a?(Integer) && v.positive? } &&
              peer.fetch("parent_pid").is_a?(Integer) && peer.fetch("parent_pid").positive? &&
              peer.fetch("groups").is_a?(Array) && peer.fetch("groups").size <= 64 &&
              peer.fetch("groups").all? { |v| v.is_a?(Integer) && v >= 0 } && peer.fetch("groups") == peer.fetch("groups").sort.uniq &&
              peer.fetch("started_at").is_a?(String) && BOOT_BIRTH.match?(peer.fetch("started_at")) &&
              peer.fetch("host").is_a?(String) && peer.fetch("host").bytesize.between?(1, 255) && !peer.fetch("host").include?("\0")
            raise ValidationError, "Codex runtime endpoint or birth differs"
          end
        end

        def ref!(reference, limit: LIMIT)
          unless reference.is_a?(Hash) && reference.keys.sort == %w[bytes path sha256] &&
              InboxContextServiceConfiguration.path?(reference["path"]) && reference["bytes"].is_a?(Integer) &&
              reference["bytes"].between?(1, limit) && reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise ValidationError, "Codex runtime reference differs"
          end
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [immutable(key), immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end

        private_class_method :new
      end
    end
  end
end
