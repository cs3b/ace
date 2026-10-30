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
          Dir.glob(File.join(source_root, "**", "*")).select { |path| File.file?(path) }
            .to_h { |path| [path.delete_prefix("#{source_root}/"), path] }
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
