# frozen_string_literal: true

require "tempfile"
require "find"
require "rbconfig"
require "ace/lab"
require "ace/runtime/molecules/protected_socket"
require "ace/runtime/molecules/systemd_scope_manager"
require "ace/runtime/molecules/protected_linux"
require_relative "../auth"
require_relative "issuer_units"
require_relative "../molecules/gem_payload_permissions"

module Ace
  module Lab
    module Auth
      # Converge the fixed issuer unit graph from a root-owned installed
      # runtime. Existing different units are not overwritten: an upgrade
      # must first stop and recover the previous issuer under host control.
      class IssuerInstaller
        SYSTEMCTL = Ace::Runtime::Molecules::SystemdScopeManager::SYSTEMCTL

        def initialize(unit_dir: "/etc/systemd/system", owner_uid: 0, privileged: Process.euid.zero?,
          path_verifier: nil, runtime_verifier: nil, activation_verifier: nil, inactive_verifier: nil,
          readiness_verifier: nil, runner: nil)
          @unit_dir, @owner_uid, @privileged = unit_dir, owner_uid, privileged
          @path_verifier = path_verifier || lambda { |path, directory: false|
            Ace::Runtime::Molecules::ProtectedSocket.root_path!(path, directory: directory)
          }
          @runtime_verifier = runtime_verifier || method(:verify_runtime!)
          @runner = runner || lambda { |argv|
            Ace::Runtime::Molecules::SystemdScopeManager::Command.new.call(argv, timeout: 30)
          }
          @activation_verifier = activation_verifier || method(:verify_loaded_units!)
          @inactive_verifier = inactive_verifier || method(:verify_inactive_units!)
          @readiness_verifier = readiness_verifier || method(:verify_host!)
        end

        def call(ruby:, gem_home:, gem_root:, dry_run: false)
          raise Error, "issuer installation requires root" unless @privileged
          @readiness_verifier.call
          units = IssuerUnits.render(ruby: ruby, gem_home: gem_home, gem_root: gem_root)
          @path_verifier.call(@unit_dir, directory: true)
          @runtime_verifier.call(ruby: ruby, gem_home: gem_home, gem_root: gem_root)
          @inactive_verifier.call
          missing = units.filter_map do |name, expected|
            path = File.join(@unit_dir, name)
            next name unless File.exist?(path) || File.symlink?(path)
            stat = File.lstat(path)
            unless stat.file? && !stat.symlink? && stat.uid == @owner_uid && (stat.mode & 0o022).zero? && File.read(path) == expected
              raise Error, "issuer unit '#{name}' differs or is not safely owned; stop and recover the old issuer before replacement"
            end
            nil
          end
          return {"status" => missing.empty? ? "current" : "would_install", "units" => units.keys} if dry_run

          missing.each { |name| write_unit!(File.join(@unit_dir, name), units.fetch(name)) }
          run_systemctl!("daemon-reload")
          @activation_verifier.call(unit_dir: @unit_dir, units: units.keys)
          run_systemctl!("enable", "--now", "--", "ace-lab-auth.socket")
          run_systemctl!("is-active", "--quiet", "--", "ace-lab-auth-recovery.service")
          run_systemctl!("is-active", "--quiet", "--", "ace-lab-auth.socket")
          {"status" => missing.empty? ? "current" : "installed", "units" => units.keys}
        rescue Ace::Runtime::Error, Molecules::GemPayloadPermissions::Error, SystemCallError => e
          raise Error, "issuer installation failed (#{e.class})"
        end

        private

        def verify_host!
          Ace::Runtime::Molecules::ProtectedLinux.new.supported!
        end

        def verify_runtime!(ruby:, gem_home:, gem_root:)
          @path_verifier.call(ruby, directory: false)
          @path_verifier.call(gem_home, directory: true)
          @path_verifier.call(gem_root, directory: true)
          raise Error, "issuer Ruby is not a regular executable" unless File.file?(ruby) && File.executable?(ruby) && (File.stat(ruby).mode & 0o6000).zero?
          verify_ruby!(ruby)
          # RubyGems can evaluate installed specifications and search other
          # files in GEM_HOME. Validate the entire tree before loading either
          # a specification or a cached archive, not just package members.
          verify_owned_tree!(gem_home)
          %w[issuer-request issuer-cleanup issuer-recover].each do |name|
            path = File.join(gem_root, "libexec", name)
            @path_verifier.call(path, directory: false)
            raise Error, "issuer entry point is missing" unless File.file?(path)
          end
          version = File.basename(gem_root).delete_prefix("ace-lab-")
          spec_path = File.join(gem_home, "specifications", "ace-lab-#{version}.gemspec")
          @path_verifier.call(spec_path, directory: false)
          spec = Gem::Specification.load(spec_path)
          unless spec && spec.name == "ace-lab" && spec.version.to_s == version && spec.full_gem_path == gem_root
            raise Error, "issuer installed gem specification does not match the selected package"
          end
          changes = Molecules::GemPayloadPermissions.new(gem_home: gem_home, dry_run: true, privileged: true, require_complete: true)
            .call(name: "ace-lab", version: version)
          raise Error, "issuer gem payload is not root-owned and converged" unless changes.empty?
          true
        end

        def verify_ruby!(ruby)
          unless File.identical?(ruby, RbConfig.ruby)
            raise Error, "issuer Ruby differs from the interpreter verifying its dependencies"
          end
          prefix = File.expand_path(RbConfig::CONFIG.fetch("prefix"))
          paths = %w[rubylibdir rubyarchdir sitelibdir sitearchdir vendorlibdir vendorarchdir libdir].map do |key|
            File.expand_path(RbConfig::CONFIG.fetch(key))
          end
          paths << File.expand_path(Gem.default_dir)
          unless prefix != "/" && paths.all? { |path| path == prefix || path.start_with?(prefix + "/") }
            raise Error, "issuer Ruby has libraries outside its protected prefix"
          end
          @path_verifier.call(prefix, directory: true)
          verify_owned_tree!(prefix)
          verify_shared_libraries!
        end

        # Verify the actual executable mappings of this interpreter, including
        # the ELF loader and native extensions already loaded by auth. Checking
        # only Ruby's installation prefix misses its system shared libraries.
        def verify_shared_libraries!(maps_path: "/proc/self/maps")
          mappings = File.readlines(maps_path).filter_map do |line|
            fields = line.split(nil, 6)
            raise Error, "issuer process mapping is malformed" unless fields.size >= 5
            next unless fields[1].include?("x")
            path = fields[5]&.strip
            next if path.nil? || path.start_with?("[")
            unless path.start_with?("/") && !path.end_with?(" (deleted)")
              raise Error, "issuer executable mapping is unavailable"
            end
            resolved = File.realpath(path)
            @path_verifier.call(resolved, directory: false)
            stat = File.stat(resolved)
            unless stat.file? && stat.ino == Integer(fields[4], 10)
              raise Error, "issuer executable mapping changed"
            end
            resolved
          end
          raise Error, "issuer executable mappings are unavailable" if mappings.empty?
          true
        rescue SystemCallError, ArgumentError
          raise Error, "issuer shared libraries could not be verified"
        end

        def verify_owned_tree!(root)
          Find.find(root) do |path|
            stat = File.lstat(path)
            unless (stat.file? || stat.directory?) && !stat.symlink? && stat.uid == @owner_uid &&
                (stat.mode & 0o022).zero? && (!stat.file? || stat.nlink == 1)
              raise Error, "issuer runtime contains an unsafe path"
            end
          end
        end

        def write_unit!(path, contents)
          Tempfile.create([".ace-lab-auth-", ".tmp"], @unit_dir) do |file|
            file.write(contents)
            file.flush
            file.fsync
            file.chmod(0o644)
            File.rename(file.path, path)
          end
        end

        def run_systemctl!(*args)
          argv = [SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", *args]
          raise Error, "systemd issuer operation failed" unless @runner.call(argv)
        end

        def verify_inactive_units!
          %w[ace-lab-auth.socket ace-lab-auth.service ace-lab-auth-recovery.service].each do |name|
            argv = [SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", "show", "--all",
                    "--property=Id,ActiveState", "--", name]
            fields = @runner.call(argv).to_s.lines.to_h { |line| line.chomp.split("=", 2) }
            unless fields["Id"] == name && fields["ActiveState"] == "inactive"
              raise Error, "issuer unit '#{name}' is not inactive; stop and recover it first"
            end
          end
        rescue ArgumentError
          raise Error, "systemd issuer state response is malformed"
        end

        def verify_loaded_units!(unit_dir:, units:)
          units.each do |name|
            query_name = name
            argv = [SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", "show", "--all",
                    "--property=Id,LoadState,FragmentPath,DropInPaths,NeedDaemonReload,User,Type,KillMode,RemainAfterExit,Accept", "--", query_name]
            output = @runner.call(argv)
            fields = output.to_s.lines.to_h { |line| line.chomp.split("=", 2) }
            unless fields["Id"] == query_name && fields["LoadState"] == "loaded" &&
                fields["FragmentPath"] == File.join(unit_dir, name) && fields["DropInPaths"] == "" && fields["NeedDaemonReload"] == "no"
              raise Error, "loaded issuer unit '#{name}' differs or has overrides"
            end
            expected = case name
            when "ace-lab-auth.service"
              {"User" => "root", "Type" => "simple", "KillMode" => "control-group"}
            when "ace-lab-auth-recovery.service"
              {"User" => "root", "Type" => "oneshot", "RemainAfterExit" => "yes"}
            when "ace-lab-auth.socket"
              {"Accept" => "no"}
            else
              raise Error, "unexpected issuer unit"
            end
            unless expected.all? { |key, value| fields[key] == value }
              raise Error, "effective issuer unit '#{name}' has an unsafe lifecycle policy"
            end
          end
        rescue ArgumentError
          raise Error, "systemd issuer unit response is malformed"
        end
      end
    end
  end
end
