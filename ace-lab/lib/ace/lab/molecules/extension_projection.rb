# frozen_string_literal: true

require_relative "../errors"
require "fileutils"
require "pathname"

module Ace
  module Lab
    module Molecules
      # Shared extension-projection primitives (task 8xs.t.pu0.0): the
      # ONE place that knows how the installed gem's handbook/extensions
      # tree is located, enumerated, and projected safely — used by both
      # ExtensionProvisioner (convergence) and Verify (readiness), so
      # the two can never drift.
      module ExtensionProjection
        RECEIPT_NAME = ".ace-lab-extension-projection.json"

        module_function

        # Installed operational extensions must not sit below a directory
        # that an agent can replace. The leaf may be created by the root
        # installer, but every existing ancestor must already be protected.
        def validate_protected_root!(path)
          unless path.is_a?(String) && path.start_with?("/") && File.expand_path(path) == path && path != "/"
            raise Ace::Lab::Error, "installed extension path must be a canonical absolute path"
          end
          current = "/"
          root_stat = File.lstat(current)
          unless root_stat.directory? && root_stat.uid.zero? && (root_stat.mode & 0o022).zero?
            raise Ace::Lab::Error, "installed extension filesystem root is not root-controlled"
          end
          path.split("/").reject(&:empty?).each do |part|
            current = File.join(current, part)
            begin
              stat = File.lstat(current)
            rescue Errno::ENOENT
              break
            end
            unless stat.directory? && !stat.symlink? && stat.uid.zero? && (stat.mode & 0o022).zero?
              raise Ace::Lab::Error, "installed extension directory is not root-controlled: #{current}"
            end
          end
          true
        rescue SystemCallError => e
          raise Ace::Lab::Error, "installed extension directory cannot be inspected (#{e.class})"
        end

        def validate_protected_files!(root, relative_paths, allow_missing: false)
          validate_protected_root!(root)
          relative_paths.each do |relative|
            validate_destination!(root, relative)
            current = root
            segments = relative.split(File::SEPARATOR)
            segments.each_with_index do |part, index|
              current = File.join(current, part)
              begin
                stat = File.lstat(current)
              rescue Errno::ENOENT
                break if allow_missing
                raise
              end
              kind_ok = index == segments.length - 1 ? stat.file? : stat.directory?
              unless kind_ok && !stat.symlink? && stat.uid.zero? && (stat.mode & 0o022).zero?
                raise Ace::Lab::Error, "installed extension path is not root-controlled: #{current}"
              end
            end
          end
          true
        rescue SystemCallError => e
          raise Ace::Lab::Error, "installed extension file cannot be inspected (#{e.class})"
        end

        # The installed gem's own tree at the EXACT declared version.
        # @return [String, nil] the handbook/extensions directory or nil
        #   when the gem (or its extensions tree) is not installed
        def gem_source_root(gem_home, name, version)
          candidate = File.join(gem_home, "gems", "#{name}-#{version}")
          extensions = File.join(candidate, "handbook", "extensions")
          File.directory?(extensions) ? extensions : nil
        end

        # Relative path → absolute source file for every file under the
        # gem's handbook/extensions tree (e.g. "ace-wake/index.js").
        # @return [Hash<String, String>]
        def source_files(source_root)
          Dir.glob(File.join(source_root, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }
            .to_h { |path| [path.delete_prefix("#{source_root}/"), path] }
        end

        def valid_receipt?(receipt)
          receipt.is_a?(Hash) && receipt["files"].is_a?(Array) && receipt["files"].all? do |path|
            path.is_a?(String) && !path.start_with?("/") && path.split("/", -1).all? { |segment| !segment.empty? && segment != "." && segment != ".." }
          end
        end

        # Resolve and fully validate a projection destination before
        # anything is written or verified (the provider_syncer
        # validate_projection_destination posture): every path
        # component under the projection directory must be a directory
        # or creatable — a symlinked component could redirect the
        # write outside the extensions directory, so it is refused.
        # @param output_dir [String] manifest-declared extension dir
        # @param relative_path [String] receipt-relative file path
        # @return [String] the validated absolute destination
        # @raise [Ace::Lab::Error] invalid or escaping destination
        def validate_destination!(output_dir, relative_path)
          segments = relative_path.to_s.split(File::SEPARATOR)
          if segments.empty? || segments.any? { |segment| segment.empty? || segment == "." || segment == ".." }
            raise Ace::Lab::Error, "cannot project #{relative_path.inspect}: invalid destination path"
          end

          begin
            current = Pathname.new(File.realpath(output_dir))
          rescue Errno::ENOENT
            # the projection directory itself does not exist yet — no
            # component below it can escape
            return File.join(output_dir, *segments)
          end
          segments.each_with_index do |segment, index|
            current = current.join(segment)
            if File.symlink?(current.to_s)
              raise Ace::Lab::Error,
                "cannot project #{relative_path} into #{output_dir}: a symlinked path component " \
                  "would escape the projection directory"
            end
            # The FINAL segment is the file itself — only intermediate
            # components must be directories (compare by position, not
            # value: "a/a/index.js" repeats "a" legitimately).
            next if index == segments.size - 1

            if !current.directory? && File.exist?(current.to_s)
              raise Ace::Lab::Error,
                "cannot project #{relative_path} into #{output_dir}: #{current} exists and is not a directory"
            end
          end
          if File.directory?(current.to_s)
            # Receipt ownership of a path never authorizes writing
            # through a directory planted at that path — cp would
            # reinterpret the destination as a container.
            raise Ace::Lab::Error,
              "cannot project #{relative_path} into #{output_dir}: #{current} exists and is a directory"
          end
          current.to_s
        rescue Errno::ENOENT
          raise Ace::Lab::Error, "cannot project #{relative_path} into #{output_dir}: projection directory vanished"
        end
      end
    end
  end
end
