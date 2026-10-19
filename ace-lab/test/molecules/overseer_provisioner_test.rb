# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class OverseerProvisionerTest < Minitest::Test
    def provisioner(dry_run: false)
      Ace::Lab::Molecules::OverseerProvisioner.new(dry_run: dry_run)
    end

    def test_creates_folder_and_gitignore_entry
      Dir.mktmpdir do |root|
        result = provisioner.call(root: root)

        assert_equal "created", result["status"]
        assert File.directory?(File.join(root, ".ace-tasks", "_overseer"))
        assert_includes File.read(File.join(root, ".gitignore")), ".ace-tasks/_overseer/"
      end
    end

    def test_re_run_reports_exists_without_rewriting
      Dir.mktmpdir do |root|
        provisioner.call(root: root)
        gitignore = File.join(root, ".gitignore")
        content = File.read(gitignore)

        result = provisioner.call(root: root)

        assert_equal "exists", result["status"]
        assert_equal content, File.read(gitignore)
      end
    end

    def test_appends_to_existing_gitignore_without_destroying_content
      Dir.mktmpdir do |root|
        gitignore = File.join(root, ".gitignore")
        File.write(gitignore, ".ace-local/\n")

        result = provisioner.call(root: root)

        assert_equal "created", result["status"]
        content = File.read(gitignore)
        assert content.start_with?(".ace-local/\n")
        assert_includes content, ".ace-tasks/_overseer/"
      end
    end

    def test_recognizes_equivalent_existing_ignore_entry
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p(File.join(root, ".ace-tasks", "_overseer"))
        File.write(File.join(root, ".gitignore"), "/.ace-tasks/_overseer\n")

        result = provisioner.call(root: root)

        assert_equal "exists", result["status"]
        assert_equal "/.ace-tasks/_overseer\n", File.read(File.join(root, ".gitignore"))
      end
    end

    def test_dry_run_predicts_without_writing
      Dir.mktmpdir do |root|
        result = provisioner(dry_run: true).call(root: root)

        assert_equal "would_create", result["status"]
        refute File.exist?(File.join(root, ".ace-tasks"))
        refute File.exist?(File.join(root, ".gitignore"))
      end
    end
  end
end
