# frozen_string_literal: true
require "json"
require "digest"
require "etc"
require "rbconfig"
require "ace/runtime/molecules/protected_socket"
require "ace/runtime/molecules/protected_linux"

module Ace
  module Assign
    module Authority
      class Deployment
        PATH = "/etc/ace/assignment-authorities.json"
        TOKEN = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        attr_reader :data

        def self.load
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(PATH)
          raise ArgumentError, "deployment map is oversized" if File.size(PATH) > 65_536
          new(JSON.parse(File.read(PATH)))
        end

        def initialize(data)
          unless data.is_a?(Hash) && data["schema"] == "ace.assign.authorities/v1" &&
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

        # Validate fixed receiver placement before the owner opens a listener or
        # creates journal state. Operations/grants remain the Lab policy's job.
        def verify_receiver_paths!(authority_id)
          projects = data.fetch("launch_mappings").values.select { |map| map["authority_id"] == authority_id }.map { |map| map.fetch("project_id") }.uniq
          projects.each do |id|
            project(id).fetch("service_receivers", {}).each_value do |receiver|
              uid = receiver.fetch("executor_uid")
              root = receiver.fetch("staging_root")
              receiver_directory!(root, uid: uid)
              unless File.executable?(File.dirname(root))
                raise Ace::Runtime::RuntimeUnavailableError, "authority cannot inspect receiver staging"
              end
              stat = File.lstat(root)
              unless stat.uid == uid && (stat.mode & 0o7777) == 0o700
                raise Ace::Runtime::RuntimeUnavailableError, "receiver staging must be executor-private"
              end
              path = receiver.fetch("socket_path")
              receiver_directory!(File.dirname(path), uid: uid)
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

        def receiver_directory!(path, uid:)
          current = path
          loop do
            stat = File.lstat(current)
            unless stat.directory? && !stat.symlink? && [0, uid].include?(stat.uid) && (stat.mode & 0o022).zero?
              raise Ace::Runtime::RuntimeUnavailableError, "installed receiver ancestry is unsafe"
            end
            break if current == "/"
            current = File.dirname(current)
          end
        end
        private :receiver_directory!

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

        def validate_mapping!(id, mapping)
          required = %w[project_id authority_id launcher_uid launcher_gid launcher_groups worker_uid worker_gid
            worker_groups worker_actor worker_cwd worker_argv worker_env bootstrap bootstrap_sha256 native]
          unless mapping.is_a?(Hash) && mapping.keys.sort == required.sort
            raise ArgumentError, "launch mapping fields differ: #{id}"
          end
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
          strict!(native, %w[socket_path socket_identity executable version server_identity workspace_id])
          %w[socket_path executable].each { |key| path!(native.fetch(key)) }
          unless native["workspace_id"].is_a?(String) && native["workspace_id"].match?(/\Aw[1-9][0-9]{0,8}\z/)
            raise ArgumentError, "invalid installed native workspace ID"
          end
          identity = native.fetch("server_identity")
          strict!(identity, %w[pid uid gid groups started_at host parent_pid])
          principal!(identity, "uid", "gid", "groups")
          unless identity["uid"] == mapping["worker_uid"] && identity["gid"] == mapping["worker_gid"] &&
              identity["groups"] == mapping["worker_groups"] && identity["pid"].is_a?(Integer) && identity["pid"].positive? &&
              identity["parent_pid"].is_a?(Integer) && identity["parent_pid"].positive? &&
              identity["started_at"].is_a?(String) && identity["started_at"].match?(/\Alinux:[0-9a-f-]+:[0-9]+\z/) &&
              identity["host"].is_a?(String) && !identity["host"].empty? && native["version"] == "0.9.3" &&
              native["socket_identity"].is_a?(Array) && native["socket_identity"].size == 3 &&
              native["socket_identity"].all? { |v| v.is_a?(Integer) && v >= 0 } && native["socket_identity"].last == mapping["worker_uid"]
            raise ArgumentError, "invalid installed native server identity"
          end
          argv = mapping.fetch("worker_argv")
          env = mapping.fetch("worker_env")
          unless argv.is_a?(Array) && !argv.empty? && argv.size <= 64 && argv.all? { |v| v.is_a?(String) && !v.include?("\0") } &&
              argv.first.start_with?("/") && env.is_a?(Hash) && env.all? { |k, v| k.match?(/\A[A-Z_][A-Z0-9_]*\z/) && v.is_a?(String) && !v.include?("\0") } &&
              env.keys.none? { |key| key.match?(/\A(?:LD_|DYLD_|RUBY|BUNDLE|PYTHON)/) }
            raise ArgumentError, "invalid fixed worker argv or environment"
          end
          unless mapping["worker_actor"].is_a?(String) && !mapping["worker_actor"].empty? &&
              mapping["bootstrap_sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "invalid installed bootstrap or worker actor"
          end
        rescue KeyError, NoMethodError
          raise ArgumentError, "launch mapping is incomplete"
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

        def verify!(id, kernel: Ace::Runtime::Molecules::ProtectedLinux.new, authority_state: false)
          kernel.supported!
          map = mapping(id)
          service = authority(map.fetch("authority_id"))
          [service.fetch("uid"), map.fetch("launcher_uid"), map.fetch("worker_uid")].each { |uid| Etc.getpwuid(uid) }
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(map.fetch("bootstrap"))
          wire.root_path!(map.fetch("worker_argv").first)
          unless Digest::SHA256.file(map.fetch("bootstrap")).hexdigest == map.fetch("bootstrap_sha256") &&
              elf_architecture?(map.fetch("bootstrap")) &&
              [map.fetch("bootstrap"), map.fetch("worker_argv").first].all? { |path| (File.stat(path).mode & 0o6000).zero? && File.executable?(path) }
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
