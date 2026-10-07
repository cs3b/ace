# frozen_string_literal: true
require_relative "server_resource_observation"

module Ace
  module Runtime
    module Molecules
      # Pure verification of the fixed supported unit's live report. Installed
      # profile verification and original host proof authentication are separate.
      class KernelViewTopology
        VIEWS = ServerResourceObservation::VIEW_PATHS
        MOUNT_FIELDS = ServerResourceObservation::MOUNT_FIELDS.sort.freeze
        READONLY = %w[/proc/sys /sys /sys/fs/cgroup /dev /dev/shm].freeze
        APIS = {"/proc" => "proc", "/dev/pts" => "devpts", "/dev/mqueue" => "mqueue"}.freeze

        def verify!(topology:, host_ipc:, authority_socket:, writable_resources:)
          object!(topology, %w[authority_socket_identity hook_ipc_namespace_identity ipc_namespace_identity mounts views])
          ipc = topology.fetch("ipc_namespace_identity")
          namespace!(ipc)
          namespace!(topology.fetch("hook_ipc_namespace_identity"))
          namespace!(host_ipc)
          refuse! unless ipc == topology.fetch("hook_ipc_namespace_identity") && ipc != host_ipc
          socket = topology.fetch("authority_socket_identity")
          refuse! unless socket.is_a?(Array) && socket.size == 3 && socket.all? { |n| n.is_a?(Integer) && n >= 0 } &&
            socket.first(2).all?(&:positive?) && socket == authority_socket
          mounts = topology.fetch("mounts")
          refuse! unless mounts.is_a?(Array) && mounts.size.between?(1, 256)
          mounts.each { |mount| mount!(mount) }
          refuse! unless mounts.map { |row| row.fetch("mount_id") }.uniq.size == mounts.size
          roots = mounts.select { |row| row.fetch("mountpoint") == "/" }
          refuse! unless !roots.empty? && roots.all? { |row| readonly?(row) }
          views = topology.fetch("views")
          refuse! unless views.is_a?(Array) && views.size == VIEWS.size && views.map { |view| view.fetch("path") }.sort == VIEWS.sort
          by_path = views.to_h do |view|
            object!(view, %w[device inode mount_id path type])
            refuse! unless view["type"] == "directory" && %w[device inode mount_id].all? { |key| positive?(view[key]) }
            row = mounts.find { |mount| mount.fetch("mount_id") == view.fetch("mount_id") }
            refuse! unless row && covers?(row.fetch("mountpoint"), view.fetch("path"))
            [view.fetch("path"), row]
          end
          READONLY.each { |path| refuse! unless readonly?(by_path.fetch(path)) }
          APIS.each do |path, filesystem|
            row = by_path.fetch(path)
            refuse! unless row.fetch("mountpoint") == path && row.fetch("root") == "/" && row.fetch("filesystem_type") == filesystem
          end
          refuse! unless by_path.fetch("/dev").fetch("filesystem_type") == "tmpfs" && by_path.fetch("/dev").fetch("mountpoint") == "/dev"
          mounts.each do |row|
            next if readonly?(row)
            api = APIS[row.fetch("mountpoint")]
            next if api && row == by_path.fetch(row.fetch("mountpoint")) && row.fetch("filesystem_type") == api
            refuse! if %w[/dev /proc /sys].any? { |root| covers?(root, row.fetch("mountpoint")) }
            refuse! unless writable_resources.any? do |resource|
              row.values_at("mountpoint", "major_minor", "root") == resource.values_at("view_path", "major_minor", "filesystem_path") &&
                row.fetch("filesystem_type") == resource.fetch("filesystem_type")
            end
          end
          %w[/tmp /var/tmp].each do |path|
            row = by_path.fetch(path)
            refuse! unless readonly?(row) || writable_resources.any? { |resource| resource["view_path"] == path && row["mountpoint"] == path }
          end
          true
        rescue KeyError, TypeError, NoMethodError, ArgumentError
          refuse!
        end

        private

        def mount!(row)
          object!(row, MOUNT_FIELDS)
          refuse! unless positive?(row["mount_id"]) && row["parent_id"].is_a?(Integer) && row["parent_id"] >= 0 &&
            row["major_minor"].is_a?(String) && row["major_minor"].match?(/\A[0-9]+:[0-9]+\z/) &&
            path?(row["root"]) && path?(row["mountpoint"]) && row["filesystem_type"].is_a?(String) &&
            row["filesystem_type"].match?(/\A[a-zA-Z0-9_.-]+\z/) && row["options"].is_a?(Array) &&
            row["options"].all? { |option| option.is_a?(String) && option.bytesize.between?(1, 128) } &&
            row["options"].uniq == row["options"] && (row["options"] & %w[ro rw]).size == 1
        end
        def object!(value, fields)
          refuse! unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end
        def namespace!(value)
          object!(value, %w[device inode])
          refuse! unless value.values.all? { |number| positive?(number) }
        end
        def positive?(number) = number.is_a?(Integer) && number.positive?
        def path?(path) = path.is_a?(String) && path.bytesize.between?(1, 4096) && path.start_with?("/") && !path.include?("\0") && File.expand_path(path) == path
        def covers?(root, path) = root == "/" || root == path || path.start_with?(root + "/")
        def readonly?(row) = row.fetch("options").include?("ro")
        def refuse! = raise(RuntimeUnavailableError, "live kernel/resource view does not match the supported profile")
      end
    end
  end
end
