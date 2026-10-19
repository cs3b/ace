# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class ProjectRegistryTest < Minitest::Test
    def registry
      Ace::Lab::Molecules::ProjectRegistry.new
    end

    def project(id: "atlas", path: nil, remote: "git@forge:atlas/atlas.git", label: "Atlas")
      {"id" => id, "label" => label, "path" => path, "remote" => remote}
    end

    def test_registers_project_in_a_new_registry_document
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        result = registry.register(root: root, project: project(path: path))

        assert_equal "created", result["status"]
        document = YAML.safe_load_file(File.join(root, ".ace", "lab", "config.yml"))
        entry = document.dig("topology", "projects").first
        assert_equal "atlas", entry["id"]
        assert_equal path, entry["path"]
        assert_equal "git@forge:atlas/atlas.git", entry["remote"]
        # The written document is a valid lab configuration for consumers
        Ace::Lab::Atoms::TopologySchema.normalize!(document)
      end
    end

    def test_re_register_reports_exists_without_rewriting
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))
        file = File.join(root, ".ace", "lab", "config.yml")
        content = File.read(file)

        result = registry.register(root: root, project: project(path: path))

        assert_equal "exists", result["status"]
        assert_equal content, File.read(file)
      end
    end

    def test_same_id_with_different_path_is_refused
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))

        result = registry.register(root: root, project: project(path: "#{path}-elsewhere"))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "registered at"
      end
    end

    def test_same_id_with_different_remote_is_refused
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))

        result = registry.register(root: root,
          project: project(path: path, remote: "git@forge:other/other.git"))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "remote"
      end
    end

    def test_same_path_under_different_id_is_refused
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))

        result = registry.register(root: root, project: project(id: "borealis", path: path))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "already registered as project 'atlas'"
      end
    end

    def test_unparseable_registry_is_refused_not_overwritten
      Dir.mktmpdir do |root|
        file = registry.registry_path(root)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, ":\nnot: [a, mapping\n")

        result = registry.register(root: root, project: project(path: root))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "refusing to overwrite"
      end
    end

    def test_foreign_schema_version_is_refused
      Dir.mktmpdir do |root|
        file = registry.registry_path(root)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, {"schema_version" => 99, "topology" => {"projects" => []}}.to_yaml)

        result = registry.register(root: root, project: project(path: root))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "not this lab's registry"
      end
    end

    def test_second_project_appends_to_the_same_registry
      Dir.mktmpdir do |root|
        atlas = File.join(root, "atlas")
        borealis = File.join(root, "borealis")
        registry.register(root: root, project: project(path: atlas))
        registry.register(root: root,
          project: project(id: "borealis", path: borealis, remote: nil, label: nil))

        document = YAML.safe_load_file(registry.registry_path(root))
        assert_equal %w[atlas borealis], document.dig("topology", "projects").map { |p| p["id"] }
      end
    end

    def test_non_mapping_project_entry_is_a_classified_failure_not_a_crash
      Dir.mktmpdir do |root|
        file = registry.registry_path(root)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, {"schema_version" => 1, "topology" => {"projects" => [42]}}.to_yaml)

        result = registry.register(root: root, project: project(path: root))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "not this lab's registry"
        assert_equal 42, YAML.safe_load_file(file).dig("topology", "projects").first
      end
    end

    def test_dry_run_with_invalid_id_predicts_the_wet_failure
      Dir.mktmpdir do |root|
        result = registry.register(root: root,
          project: project(id: "  ", path: File.join(root, "lab")), dry_run: true)

        assert_equal "failed", result["status"]
        assert_includes result["message"], "invalid lab configuration"
        refute File.exist?(registry.registry_path(root))

        wet = registry.register(root: root, project: project(id: "  ", path: File.join(root, "lab")))
        assert_equal "failed", wet["status"]
        assert_equal result["message"], wet["message"]
      end
    end

    def test_empty_registry_file_is_refused_with_a_clear_message
      Dir.mktmpdir do |root|
        file = registry.registry_path(root)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, "")

        result = registry.register(root: root, project: project(path: root))

        assert_equal "failed", result["status"]
        assert_includes result["message"], "exists but is empty"
        assert_equal "", File.read(file)
      end
    end

    def test_re_add_with_a_changed_label_updates_the_label
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))

        result = registry.register(root: root,
          project: project(path: path, label: "Atlas Prime"))

        assert_equal "updated", result["status"]
        document = YAML.safe_load_file(registry.registry_path(root))
        assert_equal "Atlas Prime", document.dig("topology", "projects").first["label"]
      end
    end

    def test_re_add_with_a_changed_label_in_dry_run_predicts_update_without_writing
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))
        file = registry.registry_path(root)
        content = File.read(file)

        result = registry.register(root: root,
          project: project(path: path, label: "Atlas Prime"), dry_run: true)

        assert_equal "would_update", result["status"]
        assert_equal content, File.read(file)
      end
    end

    def test_re_add_without_a_label_keeps_the_recorded_label
      Dir.mktmpdir do |root|
        path = File.join(root, "lab")
        registry.register(root: root, project: project(path: path))
        file = registry.registry_path(root)
        content = File.read(file)

        result = registry.register(root: root,
          project: project(path: path, label: nil))

        assert_equal "exists", result["status"]
        assert_equal content, File.read(file)
      end
    end

    def test_dry_run_predicts_without_writing
      Dir.mktmpdir do |root|
        result = registry.register(root: root, project: project(path: root), dry_run: true)

        assert_equal "would_create", result["status"]
        refute File.exist?(registry.registry_path(root))
      end
    end
  end
end
