# frozen_string_literal: true

require "find"
require "yaml"
require "ace/runtime"
require "ace/runtime/molecules/protected_socket"
require_relative "../errors"

module Ace
  module Herdr
    module Molecules
      # Installed Linux lab agents load only host-managed Pi extensions.
      # The existing root-owned lab manifest declares their location; no
      # second registry or agent-writable discovery path is introduced.
      module InstalledPiExtensions
        MANIFEST_DIR = "/etc/lab/ace-lab"
        MANIFEST = "#{MANIFEST_DIR}/install.yml"
        module_function

        def arguments(env: ENV, manifest: MANIFEST, manifest_dir: MANIFEST_DIR, platform: RUBY_PLATFORM)
          if env["ACE_LAB_SESSION"] == "1" && (env["ACE_TOOLCHAIN"] != "installed" || !platform.include?("linux"))
            raise ExecutorUnavailableError, "isolated lab sessions require the installed Linux runtime"
          end
          return [] unless env["ACE_TOOLCHAIN"] == "installed" && platform.include?("linux")
          if env["ACE_LAB_SESSION"] == "1" && !File.exist?(manifest_dir) && !File.symlink?(manifest_dir)
            raise ExecutorUnavailableError, "isolated lab session requires the protected install manifest"
          end
          return [] unless File.exist?(manifest_dir) || File.symlink?(manifest_dir)

          guard = Ace::Runtime::Molecules::ProtectedSocket
          guard.root_path!(manifest, directory: false)
          raise ExecutorUnavailableError, "installed lab manifest is not a regular file" unless File.file?(manifest)
          document = YAML.safe_load(File.read(manifest), permitted_classes: [], aliases: false)
          rows = document.is_a?(Hash) && document.dig("gemset", "extensions")
          matches = rows.is_a?(Array) ? rows.select { |row| row.is_a?(Hash) && row["gem"] == "ace-wake" } : []
          raise ExecutorUnavailableError, "installed lab must declare exactly one ace-wake extension path" unless matches.size == 1
          root = matches.fetch(0)["path"]
          guard.root_path!(root, directory: true)
          wake = File.join(root, "ace-wake")
          guard.root_path!(wake, directory: true)
          Find.find(wake) do |path|
            stat = File.lstat(path)
            unless (stat.file? || stat.directory?) && !stat.symlink? && stat.uid.zero? && (stat.mode & 0o022).zero?
              raise ExecutorUnavailableError, "installed ace-wake contains an unsafe path"
            end
          end
          entry = File.join(wake, "index.js")
          integration = File.join(root, "herdr-agent-state.ts")
          [entry, integration].each do |path|
            guard.root_path!(path, directory: false)
            raise ExecutorUnavailableError, "installed Pi extension is not a regular file" unless File.file?(path)
          end
          ["--no-extensions", "--extension", entry, "--extension", integration]
        rescue Ace::Runtime::Error, SystemCallError, Psych::Exception, TypeError, ArgumentError
          raise ExecutorUnavailableError, "installed Pi extension configuration is unavailable or unsafe"
        end

        def reject_override!(args)
          return if args.none? { |arg| arg.is_a?(String) && (arg == "--no-extensions" || arg == "-ne" || arg.start_with?("--extension=") || arg == "--extension" || arg.start_with?("-e")) }

          raise ExecutorUnavailableError, "installed lab Pi extension arguments cannot be overridden"
        end
      end
    end
  end
end
