# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  # Task 8xs.t.pu0.0: harness extensions project from the installed
  # gem's EXACT declared version into the manifest-declared directory,
  # with a receipt, an actually-loaded version, and a restart signal —
  # never a silent restart.
  class ExtensionProvisionerTest < Minitest::Test
    RECEIPT = ".ace-lab-extension-projection.json"

    def provisioner(gem_home, dry_run: false)
      Ace::Lab::Molecules::ExtensionProvisioner.new(gem_home: gem_home, dry_run: dry_run)
    end

    # An "installed" gem tree carrying handbook/extensions, the shape
    # RubyGems lays out under GEM_HOME/gems/<name>-<version>.
    def installed_gem(gem_home, name, version, files)
      source = File.join(gem_home, "gems", "#{name}-#{version}", "handbook", "extensions")
      files.each do |relative, content|
        path = File.join(source, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end
      source
    end

    def entry(path, gem = "ace-wake")
      {"gem" => gem, "path" => path, "account" => "lab-overseer"}
    end

    def test_projects_from_the_installed_gem_and_records_loaded_version
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        installed_gem(gem_home, "ace-wake", "0.1.0",
          {"ace-wake/index.js" => "// entry\n", "ace-wake/wake/eyes.js" => "// eyes\n"})
        target = File.join(dir, "extensions")

        report = provisioner(gem_home).call(
          extensions: [entry(target)], gems: [{"name" => "ace-wake", "version" => "0.1.0"}]
        ).first

        assert_equal "projected", report["status"]
        assert_equal "0.1.0", report["version"]
        assert_nil report["loaded_version"] # nothing was loaded before
        assert_equal true, report["restart_required"]
        assert_equal "// entry\n", File.read(File.join(target, "ace-wake", "index.js"))

        receipt = JSON.parse(File.read(File.join(target, RECEIPT)))
        assert_equal "ace-wake", receipt["gem"]
        assert_equal "0.1.0", receipt["version"]
        assert_includes receipt["files"], "ace-wake/index.js"
      end
    end

    def test_second_run_is_unchanged_without_restart_need
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        installed_gem(gem_home, "ace-wake", "0.1.0", {"ace-wake/index.js" => "// entry\n"})
        target = File.join(dir, "extensions")
        gems = [{"name" => "ace-wake", "version" => "0.1.0"}]

        provisioner(gem_home).call(extensions: [entry(target)], gems: gems)
        second = provisioner(gem_home).call(extensions: [entry(target)], gems: gems).first

        assert_equal "unchanged", second["status"]
        assert_equal "0.1.0", second["loaded_version"] # the version the harness loaded
        assert_equal false, second["restart_required"]
      end
    end

    def test_version_change_reports_restart_and_updates_loaded_version
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        installed_gem(gem_home, "ace-wake", "0.1.0", {"ace-wake/index.js" => "// v1\n"})
        target = File.join(dir, "extensions")
        gems = [{"name" => "ace-wake", "version" => "0.1.0"}]
        provisioner(gem_home).call(extensions: [entry(target)], gems: gems)

        installed_gem(gem_home, "ace-wake", "0.2.0", {"ace-wake/index.js" => "// v2\n"})
        upgraded = provisioner(gem_home).call(
          extensions: [entry(target)], gems: [{"name" => "ace-wake", "version" => "0.2.0"}]
        ).first

        assert_equal "projected", upgraded["status"]
        assert_equal "0.1.0", upgraded["loaded_version"] # what the running harness still holds
        assert_equal true, upgraded["restart_required"]
        assert_equal "// v2\n", File.read(File.join(target, "ace-wake", "index.js"))
      end
    end

    def test_dry_run_predicts_without_writing
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        installed_gem(gem_home, "ace-wake", "0.1.0", {"ace-wake/index.js" => "// entry\n"})
        target = File.join(dir, "extensions")

        report = provisioner(gem_home, dry_run: true).call(
          extensions: [entry(target)], gems: [{"name" => "ace-wake", "version" => "0.1.0"}]
        ).first

        assert_equal "projected", report["status"]
        assert_equal true, report["restart_required"]
        refute File.exist?(target), "dry-run must not create the projection"
      end
    end

    def test_stale_receipt_files_are_removed_but_user_files_are_kept
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        installed_gem(gem_home, "ace-wake", "0.1.0",
          {"ace-wake/index.js" => "// entry\n", "ace-wake/old.js" => "// old\n"})
        target = File.join(dir, "extensions")
        gems = [{"name" => "ace-wake", "version" => "0.1.0"}]
        provisioner(gem_home).call(extensions: [entry(target)], gems: gems)

        # user-authored extension in the same directory stays untouched
        user_file = File.join(target, "my-own-extension", "index.js")
        FileUtils.mkdir_p(File.dirname(user_file))
        File.write(user_file, "// mine\n")

        # the gem drops old.js in a new version
        installed_gem(gem_home, "ace-wake", "0.2.0", {"ace-wake/index.js" => "// entry2\n"})
        report = provisioner(gem_home).call(
          extensions: [entry(target)], gems: [{"name" => "ace-wake", "version" => "0.2.0"}]
        ).first

        assert_equal "projected", report["status"]
        refute File.exist?(File.join(target, "ace-wake", "old.js"))
        assert_equal "// mine\n", File.read(user_file)
      end
    end

    def test_missing_installed_gem_is_a_classified_failure
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        report = provisioner(gem_home).call(
          extensions: [entry(File.join(dir, "extensions"))],
          gems: [{"name" => "ace-wake", "version" => "0.1.0"}]
        ).first

        assert_equal "failed", report["status"]
        assert_match(/is not installed in runtime/, report["message"])
      end
    end
  end
end
