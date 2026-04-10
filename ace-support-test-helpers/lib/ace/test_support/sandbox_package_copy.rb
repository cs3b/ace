# frozen_string_literal: true

require "fileutils"

module Ace
  module TestSupport
    # Creates deterministic E2E sandboxes and copies package sources into them.
    class SandboxPackageCopy
      DEFAULT_SANDBOX_BASE = ".ace-local/test-e2e"

      def initialize(source_root: Dir.pwd, sandbox_base: DEFAULT_SANDBOX_BASE)
        @source_root = File.expand_path(source_root)
        @sandbox_base = File.expand_path(sandbox_base, @source_root)
      end

      # Prepare a sandbox and copy a package into it.
      #
      # Exactly one of sandbox_name or sandbox_root must be provided.
      #
      # @param package_name [String] package directory to copy
      # @param sandbox_name [String, nil] sandbox folder name under .ace-local/test-e2e
      # @param sandbox_root [String, nil] explicit sandbox path
      # @return [Hash] sandbox_root, package_root, source_root, and env contract
      def prepare(package_name:, sandbox_name: nil, sandbox_root: nil)
        package = package_name.to_s.strip
        raise ArgumentError, "package_name is required" if package.empty?

        root = resolve_sandbox_root(sandbox_name: sandbox_name, sandbox_root: sandbox_root)
        source_package = File.join(@source_root, package)
        target_package = File.join(root, package)

        unless File.directory?(source_package)
          raise ArgumentError, "Package source directory not found: #{source_package}"
        end

        FileUtils.mkdir_p(root)
        FileUtils.cp_r(source_package, target_package) unless File.exist?(target_package)

        {
          sandbox_root: root,
          package_root: target_package,
          source_root: @source_root,
          env: {
            "PROJECT_ROOT_PATH" => root,
            "ACE_E2E_SOURCE_ROOT" => @source_root
          }
        }
      end

      private

      def resolve_sandbox_root(sandbox_name:, sandbox_root:)
        if sandbox_name && sandbox_root
          raise ArgumentError, "Specify only one of sandbox_name or sandbox_root"
        end

        if sandbox_name
          name = sandbox_name.to_s.strip
          raise ArgumentError, "sandbox_name cannot be empty" if name.empty?

          return File.join(@sandbox_base, name)
        end

        if sandbox_root
          root = sandbox_root.to_s.strip
          raise ArgumentError, "sandbox_root cannot be empty" if root.empty?

          return File.expand_path(root)
        end

        raise ArgumentError, "Either sandbox_name or sandbox_root is required"
      end
    end
  end
end
