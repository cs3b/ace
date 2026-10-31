# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "find"

module Ace
  module Lab
    module Molecules
      # Installed specifications select identity; cached gem archives own payload
      # membership (installed gemspecs omit files). No recursive runtime sweep.
      class GemPayloadPermissions
        class Error < StandardError; end
        INVENTORY = <<~'CODE'
          require 'json'
          require 'rubygems'
          require 'rubygems/package'
          home = ARGV.shift
          Gem.use_paths(home)
          queue = [Gem::Specification.find_by_name(ARGV.shift, ARGV.shift)]
          dry_run = ARGV.shift == "dry-run"
          seen = {}; rows = []
          until queue.empty?
            spec = queue.shift
            next if seen[spec.full_name]
            seen[spec.full_name] = true
            unless spec.default_gem?
              cache = File.join(home, "cache", "#{spec.full_name}.gem")
              unless File.file?(cache) && !File.symlink?(cache) && !File.symlink?(File.dirname(cache))
                puts JSON.generate(error: "installed gem payload cache missing or symlinked: #{cache}")
                exit 1
              end
              package = Gem::Package.new(cache)
              package.verify
              unless package.spec.full_name == spec.full_name
                puts JSON.generate(error: "installed gem payload cache identity mismatch: #{cache}")
                exit 1
              end
              rows << {root: spec.full_gem_path, spec: spec.loaded_from,
                files: package.contents, executables: spec.executables,
                bindir: spec.bindir, extension: spec.extensions.empty? ? nil : spec.extension_dir}
            end
            spec.runtime_dependencies.each do |dep|
              begin
                queue << dep.to_spec
              rescue Gem::MissingSpecError
                # Convergence already predicts installing absent dependencies.
                # Validate the existing payload; do not invent future files.
                raise unless dry_run
              end
            end
          end
          puts JSON.generate(rows)
        CODE

        def initialize(gem_home:, dry_run:, privileged:)
          @declared_home = File.expand_path(gem_home)
          raise Error, "gem runtime is a symlink" if File.symlink?(@declared_home)
          @home = File.realpath(@declared_home)
          @dry_run, @privileged = dry_run, privileged
        end

        def call(name:, version:)
          # Default Ruby gems need no mutation in this runtime. With no local
          # specifications there cannot be any owned installed payload here.
          return [] unless File.directory?(File.join(@home, "specifications"))

          env = ENV.keys.grep(/\ABUNDLE/).to_h { |key| [key, nil] }
          env.merge!("RUBYOPT" => nil, "RUBYLIB" => nil, "GEM_HOME" => @home, "GEM_PATH" => @home)
          out, _err, status = Open3.capture3(env, RbConfig.ruby, "-e", INVENTORY, @home, name, version, @dry_run ? "dry-run" : "apply")
          unless status.success?
            detail = begin
              JSON.parse(out)["error"]
            rescue JSON::ParserError
              nil
            end
            raise Error, detail || "could not inventory installed gem payload #{name} #{version}"
          end

          converge(JSON.parse(out))
        rescue SystemCallError, JSON::ParserError => e
          raise Error, "gem payload permission convergence failed (#{e.class})"
        end

        def converge(rows)
          paths = {}
          executables = []
          rows.each do |row|
            root = validate(row.fetch("root"))
            raise Error, "invalid installed gem root" unless File.dirname(root) == File.join(@home, "gems")
            spec = validate(row.fetch("spec"))
            raise Error, "invalid installed gem specification" unless File.dirname(spec) == File.join(@home, "specifications")
            add(paths, spec)
            row.fetch("files").each { |file| add(paths, payload_path(root, file)) }
            row.fetch("executables").each do |exe|
              raise Error, "invalid gem executable" unless File.basename(exe) == exe && !%w[. ..].include?(exe)
              [payload_path(root, File.join(row.fetch("bindir"), exe)), File.join(@home, "bin", exe)].each do |path|
                add(paths, path)
                executables << validate(path)
              end
            end
            if (extension = row["extension"])
              extension = validate(extension)
              raise Error, "invalid gem extension directory" unless
                extension.start_with?(File.join(@home, "extensions") + "/") &&
                File.basename(extension) == File.basename(root)
              Find.find(extension) do |path|
                validate(path)
                add(paths, path)
              end
            end
          end
          changes = paths.filter_map do |path, stat|
            desired = stat.directory? || executables.include?(path) || (stat.mode & 0o111).positive? ? 0o755 : 0o644
            owner_change = @privileged && (stat.uid != 0 || stat.gid != 0)
            next if (stat.mode & 0o7777) == desired && !owner_change
            {"path" => path, "mode" => desired, "owner_change" => owner_change,
             "status" => @dry_run ? "would_normalize" : "normalized"}
          end
          # Inventory validation is complete before the first mutation.
          unless @dry_run
            changes.each do |change|
              path = validate(change.fetch("path"))
              current = File.lstat(path)
              original = paths.fetch(path)
              raise Error, "gem payload changed during permission convergence: #{path}" unless
                current.ino == original.ino && current.dev == original.dev && !current.symlink?
              File.chown(0, 0, path) if change["owner_change"]
              File.chmod(change.fetch("mode"), path)
            end
          end
          changes
        end

        private

        def payload_path(root, relative)
          path = File.expand_path(relative, root)
          raise Error, "gem payload escapes specification root" unless path.start_with?(root + "/")
          path
        end

        def validate(path)
          path = File.expand_path(path)
          if path == @declared_home || path.start_with?(@declared_home + "/")
            path = @home + path.delete_prefix(@declared_home)
          end
          raise Error, "gem payload escapes declared runtime: #{path}" unless path == @home || path.start_with?(@home + "/")
          cursor = path
          loop do
            stat = File.lstat(cursor)
            raise Error, "gem payload symlink refused: #{cursor}" if stat.symlink?
            raise Error, "unsupported gem payload: #{cursor}" unless stat.file? || stat.directory?
            break if cursor == @home
            cursor = File.dirname(cursor)
          end
          path
        end

        def add(paths, path)
          path = validate(path)
          loop do
            stat = File.lstat(path)
            raise Error, "hardlinked gem payload refused: #{path}" if stat.file? && stat.nlink > 1
            paths[path] = stat
            break if path == @home
            path = File.dirname(path)
          end
        end
      end
    end
  end
end
