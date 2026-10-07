# frozen_string_literal: true
require "json"
require "digest"
require "etc"
require "rbconfig"
require "openssl"
require_relative "private_directory"
require_relative "posix_acl"
require_relative "task_context_entry"
require "ace/runtime/molecules/protected_worker_entry"
require "ace/runtime/molecules/protected_socket"
require "ace/runtime/molecules/protected_artifact_set"
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/readiness_configuration"

module Ace
  module Assign
    module Authority
      class Deployment
        PATH = "/etc/ace/assignment-authorities.json"
        TOKEN = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        attr_reader :data, :artifact_reference

        def self.load
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |artifacts|
            bytes, reference = artifacts.read_path!(PATH, limit: 65_536)
            deployment = from_verified_bytes(bytes, reference)
            artifacts.verify_unchanged!
            deployment
          end
        end

        # Trusted installer source call only; this is not a transport selector.
        # Authentication establishes fixed descriptor bytes, not installed readiness.
        def self.load_artifact(reference)
          unless reference.is_a?(Hash) && reference.keys.sort == %w[bytes path sha256] &&
              reference["path"].is_a?(String) && reference["path"].start_with?("/") &&
              !reference["path"].include?("\0") && File.expand_path(reference["path"]) == reference["path"] &&
              reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 65_536)
            raise ArgumentError, "invalid protected deployment artifact reference"
          end
          selected = reference.transform_values { |value| value.is_a?(String) ? value.dup.freeze : value }.freeze
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |artifacts|
            deployment = from_verified_bytes(artifacts.read!(selected), selected)
            artifacts.verify_unchanged!
            deployment
          end
        end

        def self.from_verified_bytes(raw, reference)
          bytes = raw.dup.force_encoding(Encoding::UTF_8)
          raise ArgumentError, "deployment artifact is not UTF-8" unless bytes.valid_encoding?
          raise ArgumentError, "deployment artifact exceeds bounds" unless bytes.bytesize.between?(1, 65_536)
          value = JSON.parse(bytes, create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false)
          deployment = new(value)
          deployment.send(:freeze_data!, deployment.data)
          deployment.instance_variable_set(:@artifact_reference, reference)
          deployment.freeze
        end
        private_class_method :from_verified_bytes

        def initialize(data)
          unless data.is_a?(Hash) && data["schema"] == "ace.assign.authorities/v2" &&
              data.keys.sort == %w[authorities launch_mappings projects schema]
            raise ArgumentError, "invalid assignment authority deployment schema"
          end
          %w[authorities launch_mappings projects].each do |section|
            unless data[section].is_a?(Hash) && data[section].keys.all? { |id| TOKEN.match?(id) }
              raise ArgumentError, "invalid #{section} mapping"
            end
          end
          @data = JSON.parse(JSON.generate(data))
          @data["authorities"].each_value do |service|
            strict!(service, %w[uid gid groups socket_path state_root composition])
            unless %w[launch services].include?(service["composition"])
              raise ArgumentError, "unknown installed authority composition"
            end
            principal!(service, "uid", "gid", "groups")
            %w[socket_path state_root].each { |key| path!(service.fetch(key)) }
          end
          @data["projects"].each_value do |project|
            raise ArgumentError, "invalid project mapping" unless project.is_a?(Hash)
            keys = %w[journal_repository evidence_git_ref evidence_checkout_root assignment_root candidate_root
              launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids peer_credentials]
            keys << "service_receivers" if project.key?("service_receivers")
            keys << "inbox_contexts" if project.key?("inbox_contexts")
            strict!(project, keys)
            %w[journal_repository evidence_checkout_root assignment_root candidate_root].each { |key| path!(project.fetch(key)) }
            unless project["evidence_git_ref"] == "refs/ace/execution"
              raise ArgumentError, "protected authority uses the canonical execution ref"
            end
            role_uids = %w[launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids].flat_map do |key|
              values = project.fetch(key)
              unless values.is_a?(Array) && values.all? { |id| id.is_a?(Integer) && id.positive? } && values == values.sort.uniq
                raise ArgumentError, "invalid project principal allowlist"
              end
              values
            end.uniq.sort
            peers = project.fetch("peer_credentials")
            unless peers.is_a?(Hash) && peers.keys.sort == role_uids.map(&:to_s).sort
              raise ArgumentError, "fixed project peer credentials are incomplete"
            end
            peers.each do |uid, peer|
              strict!(peer, %w[gid groups scratch_root])
              principal!(peer.merge("uid" => Integer(uid, 10)), "uid", "gid", "groups")
              path!(peer.fetch("scratch_root"))
            end
            receivers = project.fetch("service_receivers", {})
            unless receivers.is_a?(Hash) && receivers.keys.all? { |id| id.is_a?(String) && TOKEN.match?(id) }
              raise ArgumentError, "invalid installed service receiver mapping"
            end
            receivers.each_value do |receiver|
              strict!(receiver, %w[executor_uid socket_path staging_root])
              uid = receiver.fetch("executor_uid")
              conflicting = %w[launcher_uids reviewer_uids worker_uids supervisor_uids].flat_map { |key| project.fetch(key) }
              unless uid.is_a?(Integer) && uid.positive? && project.fetch("service_executor_uids").include?(uid) && !conflicting.include?(uid)
                raise ArgumentError, "receiver requires an unambiguous mapped executor"
              end
              %w[socket_path staging_root].each { |key| path!(receiver.fetch(key)) }
            end
          end
          @data["launch_mappings"].each { |id, mapping| validate_mapping!(id, mapping) }
          validate_execution_slots!
          validate_inbox_contexts!
          endpoints = @data.fetch("authorities").values.map { |service| service.fetch("socket_path") }
          receivers = @data.fetch("projects").values.flat_map { |project| project.fetch("service_receivers", {}).values }
          protected_uids = @data.fetch("authorities").values.map { |service| service.fetch("uid") } +
            @data.fetch("projects").values.flat_map { |project| %w[launcher_uids reviewer_uids worker_uids supervisor_uids].flat_map { |key| project.fetch(key) } }
          if receivers.any? { |receiver| protected_uids.include?(receiver.fetch("executor_uid")) }
            raise ArgumentError, "receiver executor overlaps another installed role"
          end
          endpoints.concat(receivers.map { |receiver| receiver.fetch("socket_path") })
          raise ArgumentError, "authority endpoint has duplicate owners" unless endpoints.uniq.size == endpoints.size
          staging = receivers.map { |receiver| receiver.fetch("staging_root") }
          unless staging.combination(2).none? { |left, right| paths_overlap?(left, right) }
            raise ArgumentError, "receiver staging roots overlap"
          end
          if receivers.any? { |receiver| staging.any? { |root| paths_overlap?(receiver.fetch("socket_path"), root) } }
            raise ArgumentError, "receiver endpoint must be separate from private staging"
          end
          protected_roots = @data.fetch("authorities").values.map { |service| service.fetch("state_root") } +
            @data.fetch("projects").values.flat_map { |project| %w[journal_repository evidence_checkout_root assignment_root candidate_root].map { |key| project.fetch(key) } }
          if staging.any? { |root| protected_roots.any? { |protected| paths_overlap?(root, protected) } }
            raise ArgumentError, "receiver staging overlaps authority state"
          end
          repositories = @data.fetch("projects").values.map { |project| project.fetch("journal_repository") }
          raise ArgumentError, "canonical project repository has duplicate mappings" unless repositories.uniq.size == repositories.size
          @data.fetch("projects").each_key do |project_id|
            owners = @data.fetch("launch_mappings").values.select { |map| map["project_id"] == project_id }.map { |map| map.fetch("authority_id") }.uniq
            raise ArgumentError, "project must have exactly one authority owner" unless owners.size == 1
            service = authority(owners.first)
            installed = project(project_id).fetch("service_receivers", {})
            if service.fetch("composition") == "services" && installed.empty?
              raise ArgumentError, "services composition requires installed receivers"
            end
          end
        end

        # Static selection only. Live native identity comes from the attempt's
        # canonical scope stage, never from this deployment record.
        def inbox_context(mapping_id, context_id)
          map = mapping(mapping_id)
          contexts = project(map.fetch("project_id")).fetch("inbox_contexts", {})
          context = contexts.fetch(context_id) { raise AttemptErrors::EvidenceUnavailable, "installed inbox context is unavailable" }
          native = mapping(context.fetch("native_mapping_id"))
          unless native.fetch("project_id") == map.fetch("project_id") && native.fetch("authority_id") == map.fetch("authority_id")
            raise AttemptErrors::UnauthorizedIdentity, "inbox context belongs to another authority"
          end
          JSON.parse(JSON.generate(context))
        end

        def verify_inbox_context!(mapping_id, context_id)
          context = inbox_context(mapping_id, context_id)
          service = authority(mapping(mapping_id).fetch("authority_id"))
          unless Process.uid == service.fetch("uid")
            raise Ace::Runtime::RuntimeUnavailableError, "inbox resolver must run as its installed authority"
          end
          credentials = context.fetch("owner_credentials")
          path = context.fetch("control_socket_path")
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(File.dirname(path), directory: true, owner: credentials.fetch("uid"))
          identity = wire.socket_identity(path)
          unless identity.last == credentials.fetch("uid")
            raise Ace::Runtime::RuntimeUnavailableError, "installed context owner endpoint differs"
          end
          context
        rescue AttemptErrors::ReceiptRejected, OpenSSL::PKey::PKeyError, SystemCallError
          raise Ace::Runtime::RuntimeUnavailableError, "installed inbox context evidence is unavailable"
        end

        def verify_inbox_acl!(path, private_leaf: false)
          current = path
          loop do
            rows = receiver_acl.entries(current)
            if rows
              mask = rows.find { |tag, _perm, _id| tag == 16 }&.at(1) || 7
              allowed = current == path && !private_leaf ? [0] : [0, Process.uid]
              unsafe = rows.any? do |tag, perm, uid|
                effective = [2, 4, 8].include?(tag) ? perm & mask : perm
                case tag
                when 2 then !allowed.include?(uid) && (effective & 2).positive?
                when 4, 8, 32 then (effective & 2).positive?
                else false
                end
              end
              if private_leaf && current == path
                unsafe ||= rows.any? do |tag, perm, uid|
                  effective = [2, 4, 8].include?(tag) ? perm & mask : perm
                  [4, 8, 32].include?(tag) && effective.positive? || tag == 2 && uid != Process.uid && effective.positive?
                end
              end
              raise Ace::Runtime::RuntimeUnavailableError, "installed inbox access ACL is unsafe" if unsafe
            end
            break if current == "/"
            current = File.dirname(current)
          end
        end
        private :verify_inbox_acl!

        def validate_inbox_contexts!
          roots = []
          data.fetch("projects").each do |project_id, fixed_project|
            contexts = fixed_project.fetch("inbox_contexts", {})
            unless contexts.is_a?(Hash) && contexts.keys.all? { |id| id.is_a?(String) && TOKEN.match?(id) }
              raise ArgumentError, "invalid installed inbox context map"
            end
            contexts.each_value do |context|
              strict!(context, %w[control_socket_path deliveries_dir owner_credentials receipt_public_key native_mapping_id pi_queue_client pi_queue_client_sha256 supervisor_uids])
              credentials = context.fetch("owner_credentials")
              strict!(credentials, %w[gid groups uid])
              principal!(credentials, "uid", "gid", "groups")
              raise ArgumentError, "context owner group count exceeds bounds" if credentials.fetch("groups").size > 64
              %w[control_socket_path deliveries_dir receipt_public_key pi_queue_client].each { |key| path!(context.fetch(key)) }
              unless context["pi_queue_client_sha256"].is_a?(String) && context["pi_queue_client_sha256"].match?(/\A[0-9a-f]{64}\z/)
                raise ArgumentError, "invalid installed Pi identity client digest"
              end
              supervisors = context.fetch("supervisor_uids")
              unless supervisors.is_a?(Array) && supervisors.all? { |uid| uid.is_a?(Integer) && uid.positive? } &&
                  supervisors == supervisors.sort.uniq && (supervisors - fixed_project.fetch("supervisor_uids")).empty?
                raise ArgumentError, "inbox supervisors exceed installed project authority"
              end
              id = context.fetch("native_mapping_id")
              unless id.is_a?(String) && TOKEN.match?(id) && data.fetch("launch_mappings").key?(id)
                raise ArgumentError, "inbox native mapping is unavailable"
              end
              native = mapping(id)
              unless native.fetch("project_id") == project_id && authority(native.fetch("authority_id")).fetch("composition") == "services"
                raise ArgumentError, "inbox context requires its services project mapping"
              end
              roots << context.fetch("deliveries_dir")
            end
          end
          forbidden = data.fetch("projects").values.flat_map do |fixed_project|
            fixed_project.fetch("peer_credentials").values.map { |peer| peer.fetch("scratch_root") } +
              fixed_project.fetch("service_receivers", {}).values.map { |receiver| receiver.fetch("staging_root") } +
              %w[journal_repository evidence_checkout_root assignment_root candidate_root].map { |key| fixed_project.fetch(key) }
          end
          forbidden.concat(data.fetch("authorities").values.map { |service| service.fetch("state_root") })
          if roots.combination(2).any? { |left, right| paths_overlap?(left, right) } ||
              roots.any? { |root| forbidden.any? { |other| paths_overlap?(root, other) } }
            raise ArgumentError, "installed inbox private roots overlap protected state"
          end
        end
        private :validate_inbox_contexts!

        # Validate fixed receiver placement before the owner opens a listener or
        # creates journal state. Operations/grants remain the Lab policy's job.
        def verify_receiver_paths!(authority_id)
          projects = data.fetch("launch_mappings").values.select { |map| map["authority_id"] == authority_id }.map { |map| map.fetch("project_id") }.uniq
          projects.each do |id|
            project(id).fetch("service_receivers", {}).each_value do |receiver|
              uid = receiver.fetch("executor_uid")
              root = receiver.fetch("staging_root")
              credentials = project(id).fetch("peer_credentials").fetch(uid.to_s)
              groups = (credentials.fetch("groups") + [credentials.fetch("gid")]).uniq
              receiver_directory!(root, uid: uid, groups: groups)
              unless File.executable?(File.dirname(root))
                raise Ace::Runtime::RuntimeUnavailableError, "authority cannot inspect receiver staging"
              end
              stat = File.lstat(root)
              unless stat.uid == uid && (stat.mode & 0o7777) == 0o700
                raise Ace::Runtime::RuntimeUnavailableError, "receiver staging must be executor-private"
              end
              path = receiver.fetch("socket_path")
              receiver_directory!(File.dirname(path), uid: uid, groups: groups)
              unless File.executable?(File.dirname(path))
                raise Ace::Runtime::RuntimeUnavailableError, "authority cannot inspect receiver endpoint"
              end
              if File.exist?(path) || File.symlink?(path)
                endpoint = File.lstat(path)
                unless endpoint.socket? && !endpoint.symlink? && endpoint.uid == uid &&
                    endpoint.gid == project(id).fetch("peer_credentials").fetch(uid.to_s).fetch("gid") && (endpoint.mode & 0o007).zero?
                  raise Ace::Runtime::RuntimeUnavailableError, "installed receiver endpoint is unsafe"
                end
              end
            end
          end
          true
        rescue SystemCallError
          raise Ace::Runtime::RuntimeUnavailableError, "installed receiver paths are unavailable"
        end

        def receiver_directory!(path, uid:, groups:)
          current = path
          loop do
            stat = File.lstat(current)
            unless stat.directory? && !stat.symlink? && [0, uid].include?(stat.uid) && (stat.mode & 0o022).zero?
              raise Ace::Runtime::RuntimeUnavailableError, "installed receiver ancestry is unsafe"
            end
            unless receiver_acl.searchable?(current, stat: stat, uid: uid, groups: groups)
              raise Ace::Runtime::RuntimeUnavailableError, "executor cannot traverse receiver ancestry"
            end
            break if current == "/"
            current = File.dirname(current)
          end
        end
        private :receiver_directory!

        def receiver_acl
          @receiver_acl ||= PosixAcl.new
        end
        private :receiver_acl

        def paths_overlap?(left, right)
          left == right || left.start_with?(right.chomp("/") + "/") || right.start_with?(left.chomp("/") + "/")
        end
        private :paths_overlap?

        def verify_composition!(authority_id, composition:)
          unless %w[launch services].include?(composition) && authority(authority_id).fetch("composition") == composition
            raise ArgumentError, "installed authority composition differs from source entrypoint"
          end
          true
        end

        def authority(id)
          data.fetch("authorities").fetch(id)
        end

        def project(id)
          data.fetch("projects").fetch(id)
        end

        def mapping(id)
          data.fetch("launch_mappings").fetch(id)
        end

        # Canonical mapping identity shared by scope evidence and the trusted
        # provisioning owner. Resolves only this descriptor's exact mapping ID.
        def mapping_digest(id)
          Digest::SHA256.hexdigest(JSON.generate(canonical_mapping_value(mapping(id)))).freeze
        end

        def canonical_mapping_value(value)
          case value
          when Hash then value.sort.to_h.transform_values { |item| canonical_mapping_value(item) }
          when Array then value.map { |item| canonical_mapping_value(item) }
          else value
          end
        end
        private :canonical_mapping_value

        def validate_mapping!(id, mapping)
          required = %w[project_id authority_id launcher_uid launcher_gid launcher_groups worker_uid worker_gid
            worker_groups worker_actor worker_cwd worker_entry worker_env bootstrap bootstrap_sha256 native execution_scope task_context_entry]
          workspace = %w[workspace_repository_id workspace_cleanup_config]
          unless mapping.is_a?(Hash) && [required.sort, (required + workspace).sort].include?(mapping.keys.sort)
            raise ArgumentError, "launch mapping fields differ: #{id}"
          end
          if mapping.key?("workspace_repository_id")
            repository = mapping.fetch("workspace_repository_id")
            unless repository.is_a?(String) && TOKEN.match?(repository)
              raise ArgumentError, "workspace repository identity is invalid"
            end
            reference = mapping.fetch("workspace_cleanup_config")
            strict!(reference, %w[path sha256 bytes])
            path!(reference.fetch("path"))
            unless reference.fetch("path").bytesize <= 4096 && reference.fetch("path").encoding == Encoding::UTF_8 && reference.fetch("path").valid_encoding? &&
                digest?(reference.fetch("sha256")) && reference.fetch("bytes").is_a?(Integer) && reference.fetch("bytes").between?(1, 65_536)
              raise ArgumentError, "workspace cleanup configuration reference is invalid"
            end
          end
          TaskContextEntry.validate!(mapping.fetch("task_context_entry"))
          Ace::Runtime::Molecules::ProtectedWorkerEntry.validate!(mapping.fetch("worker_entry"))
          service = authority(mapping.fetch("authority_id"))
          fixed_project = project(mapping.fetch("project_id"))
          %w[launcher worker].each do |role|
            uid = mapping.fetch("#{role}_uid")
            expected = fixed_project.fetch("peer_credentials").fetch(uid.to_s)
            unless fixed_project.fetch("#{role}_uids").include?(uid) && expected["gid"] == mapping["#{role}_gid"] && expected["groups"] == mapping["#{role}_groups"]
              raise ArgumentError, "launch credentials differ from project allowlist"
            end
          end
          uids = [service.fetch("uid"), mapping.fetch("launcher_uid"), mapping.fetch("worker_uid")]
          unless uids.uniq.size == 3 && uids.all? { |uid| uid.is_a?(Integer) && uid.positive? }
            raise ArgumentError, "protected launch requires distinct non-root principals"
          end
          %w[launcher worker].each do |role|
            principal!(mapping, "#{role}_uid", "#{role}_gid", "#{role}_groups")
          end
          %w[worker_cwd bootstrap].each { |key| path!(mapping.fetch(key)) }
          native = mapping.fetch("native")
          strict!(native, %w[socket_path executable executable_sha256 version protocol workspace_id])
          %w[socket_path executable].each { |key| path!(native.fetch(key)) }
          unless native["workspace_id"].is_a?(String) && native["workspace_id"].match?(/\Aw[1-9][0-9]{0,8}\z/) &&
              native["version"] == "0.9.3" && native["protocol"] == 22 && digest?(native["executable_sha256"])
            raise ArgumentError, "invalid fixed native artifact or protocol"
          end
          scope = mapping.fetch("execution_scope")
          strict!(scope, %w[backend slot_id slice_unit service_unit unit_manifest_sha256 boundary_manifest_sha256
            root_directory runtime_directory network_namespace_path])
          unless scope["backend"] == "linux_systemd_cgroup_v2" && scope["slot_id"].is_a?(String) && TOKEN.match?(scope["slot_id"]) &&
              %w[unit_manifest_sha256 boundary_manifest_sha256].all? { |key| digest?(scope[key]) }
            raise ArgumentError, "invalid execution scope backend or manifest identity"
          end
          {"slice_unit" => ".slice", "service_unit" => ".service"}.each do |key, suffix|
            name = scope.fetch(key)
            unless name.is_a?(String) && TOKEN.match?(name) && name.end_with?(suffix) &&
                name != "-.slice" && !name.downcase.include?("overseer")
              raise ArgumentError, "invalid fixed protected unit"
            end
          end
          %w[root_directory runtime_directory network_namespace_path].each { |key| path!(scope.fetch(key)) }
          unless scope.fetch("runtime_directory").start_with?("/run/") &&
              !paths_overlap?(scope.fetch("root_directory"), scope.fetch("runtime_directory"))
            raise ArgumentError, "execution scope backing roots overlap or runtime root is invalid"
          end
          env = mapping.fetch("worker_env")
          unless env.is_a?(Hash) && env.all? { |k, v| k.match?(/\A[A-Z_][A-Z0-9_]*\z/) && v.is_a?(String) && !v.include?("\0") } &&
              env.keys.none? { |key| key.match?(/\A(?:LD_|DYLD_|RUBY|BUNDLE|PYTHON)/) }
            raise ArgumentError, "invalid fixed worker environment"
          end
          unless mapping["worker_actor"].is_a?(String) && !mapping["worker_actor"].empty? &&
              mapping["bootstrap_sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "invalid installed bootstrap or worker actor"
          end
        rescue KeyError, NoMethodError
          raise ArgumentError, "launch mapping is incomplete"
        end

        def digest?(value)
          value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
        end

        def validate_execution_slots!
          mappings = @data.fetch("launch_mappings").values
          %w[slot_id slice_unit service_unit].each do |key|
            values = mappings.map { |map| map.fetch("execution_scope").fetch(key) }
            raise ArgumentError, "execution slot has duplicate ownership" unless values.uniq.size == values.size
          end
          workers = mappings.map { |map| map.fetch("worker_uid") }
          raise ArgumentError, "protected execution slots share a worker principal" unless workers.uniq.size == workers.size
          roots = mappings.map { |map| map.fetch("execution_scope").values_at("root_directory", "runtime_directory") }
          roots.combination(2).each do |left, right|
            if left.product(right).any? { |a, b| paths_overlap?(a, b) }
              raise ArgumentError, "protected execution slot roots overlap"
            end
          end
        end

        # Original ownership cannot be recycled or hidden by a staged descriptor.
        def maintenance_inventory(candidate)
          unless candidate.is_a?(Deployment) && artifact_reference && candidate.artifact_reference && frozen? && candidate.frozen?
            raise AttemptErrors::EvidenceUnavailable, "maintenance requires authenticated immutable original and candidate descriptors"
          end
          originals = data.fetch("launch_mappings")
          proposed = candidate.data.fetch("launch_mappings")
          originals.each do |id, map|
            next unless proposed.key?(id)
            unless maintenance_association(map) == candidate.maintenance_association(proposed.fetch(id))
              raise ArgumentError, "existing maintenance mapping was reassociated: #{id}"
            end
          end
          entries = originals.map { |id, map| [id, self, map] } +
            proposed.reject { |id, _| originals.key?(id) }.map { |id, map| [id, candidate, map] }
          all = originals.map { |id, map| [id, self, map] } + proposed.map { |id, map| [id, candidate, map] }
          all.combination(2).each do |left, right|
            l_id, l_owner, l_map = left
            r_id, r_owner, r_map = right
            l_scope, r_scope = l_map.fetch("execution_scope"), r_map.fetch("execution_scope")
            shared = %w[slot_id slice_unit service_unit network_namespace_path].any? { |key| l_scope.fetch(key) == r_scope.fetch(key) }
            shared ||= l_scope.values_at("root_directory", "runtime_directory").product(
              r_scope.values_at("root_directory", "runtime_directory")).any? { |a, b| paths_overlap?(a, b) }
            if shared && (l_id != r_id || l_owner.maintenance_association(l_map) != r_owner.maintenance_association(r_map))
              raise ArgumentError, "physical execution slot has conflicting maintenance ownership"
            end
          end
          entries.sort_by(&:first).map { |entry| entry.freeze }.freeze
        end

        def maintenance_association(map)
          fixed = project(map.fetch("project_id"))
          [map.fetch("project_id"), fixed.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root"),
            authority(map.fetch("authority_id")).fetch("state_root"),
            map.fetch("execution_scope").values_at("slot_id", "slice_unit", "service_unit", "network_namespace_path")]
        end

        def freeze_data!(value)
          case value
          when Hash then value.each { |key, item| key.freeze; freeze_data!(item) }
          when Array then value.each { |item| freeze_data!(item) }
          end
          value.freeze
        end

        def strict!(value, keys)
          raise ArgumentError, "deployment fields differ" unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def path!(value)
          unless value.is_a?(String) && value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
            raise ArgumentError, "deployment path must be fixed and absolute"
          end
        end

        def principal!(value, uid_key, gid_key, groups_key)
          uid, gid, groups = value.values_at(uid_key, gid_key, groups_key)
          unless [uid, gid].all? { |id| id.is_a?(Integer) && id.positive? } && groups.is_a?(Array) &&
              groups.all? { |id| id.is_a?(Integer) && id.positive? } && groups == groups.sort.uniq
            raise ArgumentError, "invalid principal credentials"
          end
        end

        def elf_architecture?(path)
          header = File.binread(path, 20)
          expected = {"x86_64" => 62, "aarch64" => 183, "arm64" => 183}[RbConfig::CONFIG.fetch("host_cpu")]
          expected && header.bytesize == 20 && header.byteslice(0, 4) == "\x7fELF".b &&
            header.getbyte(4) == 2 && header.getbyte(5) == 1 && header.getbyte(6) == 1 &&
            header.byteslice(18, 2).unpack1("v") == expected
        end

        def verify!(id, kernel: Ace::Runtime::Molecules::ProtectedLinux.new, authority_state: false, manager: nil)
          kernel.supported!
          map = mapping(id)
          service = authority(map.fetch("authority_id"))
          [service.fetch("uid"), map.fetch("launcher_uid"), map.fetch("worker_uid")].each { |uid| Etc.getpwuid(uid) }
          wire = Ace::Runtime::Molecules::ProtectedSocket
          scope = map.fetch("execution_scope")
          manager ||= Ace::Runtime::Molecules::SystemdScopeManager.new(
            slice_unit: scope.fetch("slice_unit"), service_unit: scope.fetch("service_unit"))
          manifest = Ace::Runtime::Molecules::ExecutionUnitInstallation.new(scope: scope, native: map.fetch("native"),
            bootstrap: map.fetch("bootstrap"), worker_entry: map.fetch("worker_entry"),
            worker_uid: map.fetch("worker_uid"), worker_gid: map.fetch("worker_gid")).verify!(manager: manager)
          artifacts = manifest.fetch("artifacts")
          configuration = artifacts.find { |artifact| artifact.fetch("role") == "readiness_configuration" }
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |reader|
            bytes, = reader.read_path!(configuration.fetch("host_path"), limit: 65_536)
            unless Digest::SHA256.hexdigest(bytes) == configuration.fetch("sha256")
              raise Ace::Runtime::RuntimeUnavailableError, "readiness configuration content differs"
            end
            Ace::Runtime::Molecules::ReadinessConfiguration.decode(bytes, slot: scope.fetch("slot_id"))
              .verify_selection!(mapping_id: id, mapping: map, authority: service, installation: manifest)
            reader.verify_unchanged!
          end
          bootstrap = artifacts.find { |artifact| artifact.fetch("role") == "bootstrap" }
          executables = artifacts.select do |artifact|
            artifact.fetch("role") == "bootstrap" || (artifact.fetch("role") == "runtime_dependency" &&
              artifact.fetch("view_path") == map.fetch("worker_entry").fetch("interpreter").fetch("path"))
          end
          unless bootstrap.fetch("sha256") == map.fetch("bootstrap_sha256") && elf_architecture?(bootstrap.fetch("host_path")) &&
              executables.all? { |artifact| File.executable?(artifact.fetch("host_path")) }
            raise Ace::Runtime::RuntimeUnavailableError, "installed bootstrap or executable is unsafe"
          end
          wire.root_path!(File.dirname(service.fetch("socket_path")), directory: true, owner: service.fetch("uid"))
          if authority_state
            fixed = project(map.fetch("project_id"))
            ([service.fetch("state_root")] + %w[journal_repository evidence_checkout_root assignment_root candidate_root].map { |key| fixed.fetch(key) }).each do |path|
              wire.root_path!(path, directory: true, owner: service.fetch("uid"))
              unless (File.stat(path).mode & 0o077).zero?
                raise Ace::Runtime::RuntimeUnavailableError, "authority state root must remain private"
              end
            end
          end
          map
        end
      end
    end
  end
end
