# frozen_string_literal: true

require_relative "../errors"
require "fileutils"
require "json"

module Ace
  module Lab
    module Molecules
      # Projects harness extension assets from an INSTALLED gem's exact
      # declared version into the manifest-declared extension directory
      # (task 8xs.t.pu0.0): the manual host-lane copy of the ace-wake
      # extension is replaced by a converged, repeatable projection.
      #
      # Source of truth is the installed gem tree itself —
      # `<gem_home>/gems/<name>-<version>/handbook/extensions` — so the
      # projection always matches the exact version the manifest
      # declared (never the checkout, never a newer gem beside it).
      # Each target directory carries a receipt
      # (`.ace-lab-extension-projection.json`) recording the producing
      # gem, version and file list; ONLY receipt-listed files are ever
      # removed, so user-authored extensions in the same directory are
      # never touched. The report names the version that WAS loaded
      # before this run (`loaded_version`) and whether the projection
      # changed (`restart_required`) — a changed projection means the
      # running harness processes still hold the OLD extension; the
      # installer REPORTS the restart need, it never restarts an
      # executor on its own.
      class ExtensionProvisioner
        RECEIPT_NAME = ".ace-lab-extension-projection.json"

        # @param gem_home [String] target runtime the gems were
        #   converged into
        # @param dry_run [Boolean] predict without writing
        def initialize(gem_home:, dry_run: false)
          @gem_home = gem_home
          @dry_run = dry_run
        end

        # @param extensions [Array<Hash>] normalized manifest gemset
        #   extensions entries ({"gem" =>, "path" =>, "account" =>})
        # @param gems [Array<Hash>] declared gem set (name/version)
        # @return [Array<Hash>] one report per entry:
        #   {extension:, gem:, version:, path:, account:, status:,
        #    loaded_version:, restart_required:, files:, message:}
        def call(extensions:, gems:)
          extensions.map do |entry|
            converge(entry, gems)
          end
        end

        private

        def converge(entry, gems)
          declared = gems.find { |gem| gem["name"] == entry["gem"] }
          version = declared && declared["version"]
          source = version && gem_source_root(entry["gem"], version)

          if source.nil?
            return failed(entry, version,
              "gem '#{entry["gem"]}' is not installed in runtime '#{@gem_home}' at declared " \
              "version '#{version}'; converge the gemset first (ace-lab install)")
          end

          expected = source_files(source)
          if expected.empty?
            return failed(entry, version,
              "gem '#{entry["gem"]}' #{version} carries no handbook/extensions tree")
          end

          output_dir = entry["path"]
          receipt = read_receipt(output_dir)
          loaded_version = receipt && receipt["gem"] == entry["gem"] ? receipt["version"] : nil

          changed = projection_changed?(output_dir, expected, receipt, version)
          if !changed
            return entry_report(entry, version, "unchanged", loaded_version, false,
              receipt ? receipt.fetch("files") : expected.keys)
          end
          # dry-run predicts the projection (restart needed) without
          # writing anything
          return entry_report(entry, version, "projected", loaded_version, true, expected.keys) if @dry_run

          project(output_dir, expected, entry, version)
          entry_report(entry, version, "projected", loaded_version, true, expected.keys)
        end

        def failed(entry, version, message)
          entry_report(entry, version, "failed", nil, false, [])
            .merge("message" => message)
        end

        def entry_report(entry, version, status, loaded_version, restart_required, files)
          {"extension" => entry["gem"], "gem" => entry["gem"], "version" => version,
           "path" => entry["path"], "account" => entry["account"], "status" => status,
           "loaded_version" => loaded_version, "restart_required" => restart_required,
           "files" => files, "message" => nil}
        end

        # A projection changed when the receipt is absent, names a
        # different version, lists a different file set, or any
        # expected file's content differs on disk.
        def projection_changed?(output_dir, expected, receipt, version)
          return true if receipt.nil?
          return true if receipt["version"] != version
          return true unless receipt.fetch("files", []).sort == expected.keys.sort

          expected.any? do |relative, source|
            target = File.join(output_dir, relative)
            !File.file?(target) || !FileUtils.compare_file(source, target)
          end
        end

        def project(output_dir, expected, entry, version)
          FileUtils.mkdir_p(output_dir)
          expected.each do |relative, source|
            target = File.join(output_dir, relative)
            FileUtils.mkdir_p(File.dirname(target))
            FileUtils.cp(source, target)
          end

          # Only receipt-owned files no longer in the projection are
          # removed; a removal that fails keeps its receipt entry so a
          # later run retries it (user-authored extensions are never
          # touched).
          previous = read_receipt(output_dir)&.fetch("files", []) || []
          retained = previous.filter_map do |relative|
            target = File.join(output_dir, relative)
            next relative if expected.key?(relative)

            FileUtils.rm_f(target)
            File.exist?(target) ? relative : nil
          end

          write_receipt(output_dir, entry, version, (expected.keys + retained).sort)
        end

        def write_receipt(output_dir, entry, version, files)
          document = {
            "gem" => entry["gem"], "version" => version,
            "projected_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "files" => files.sort
          }
          File.write(File.join(output_dir, RECEIPT_NAME), JSON.pretty_generate(document))
        end

        def read_receipt(output_dir)
          path = File.join(output_dir, RECEIPT_NAME)
          return nil unless File.file?(path)

          document = JSON.parse(File.read(path))
          document.is_a?(Hash) ? document : nil
        rescue JSON::ParserError, Errno::EACCES
          nil
        end

        # The installed gem's own tree at the EXACT declared version.
        def gem_source_root(name, version)
          candidate = File.join(@gem_home, "gems", "#{name}-#{version}")
          extensions = File.join(candidate, "handbook", "extensions")
          File.directory?(extensions) ? extensions : nil
        end

        # Relative path → absolute source file for every file under the
        # gem's handbook/extensions tree (e.g. "ace-wake/index.js").
        def source_files(source_root)
          Dir.glob(File.join(source_root, "**", "*")).select { |path| File.file?(path) }
            .to_h { |path| [path.delete_prefix("#{source_root}/"), path] }
        end
      end
    end
  end
end
