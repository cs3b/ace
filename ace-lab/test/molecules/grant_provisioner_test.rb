# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class GrantProvisionerTest < Minitest::Test
    # The trusted-read seam is stubbed at the resolver boundary (the
    # fail-closed verification has its own tests); writes hit a real
    # tmpdir path so atomicity and mode are exercised for real.
    class StubResolver
      attr_reader :documents

      def initialize(documents = {})
        @documents = documents
      end

      def read_verified(path)
        documents[path]
      end
    end

    # The initial trusted document is written to the real tmpdir path
    # AND served through the stubbed resolver, so on-disk assertions
    # after refusals describe the actual file.
    def with_provisioner(initial = nil)
      Dir.mktmpdir do |dir|
        path = File.join(dir, "authorization.yml")
        File.write(path, initial) if initial
        resolver = StubResolver.new(path => initial)
        yield Ace::Lab::Molecules::GrantProvisioner.new(
          resolver: resolver, authorization_path: path
        ), path, resolver
      end
    end

    def grants_document(principals)
      YAML.dump({"principals" => principals})
    end

    def test_creates_principals_when_document_is_absent
      with_provisioner do |provisioner, path|
        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "created", report["status"]
        assert_equal({"ace-overseer" => "created"}, report["principals"])
        written = YAML.load_file(path)
        assert_equal({"ace-overseer" => {"projects" => %w[atlas]}}, written["principals"])
        assert_equal 0o644, File.stat(path).mode & 0o777
        refute File.exist?(File.join(File.dirname(path), ".authorization.yml.tmp.#{Process.pid}"))
      end
    end

    def test_re_run_is_idempotent_and_reports_exists
      with_provisioner do |provisioner, path, resolver|
        provisioner.call(desired: {"ace-overseer" => %w[atlas]}, declared_projects: %w[atlas])
        resolver.documents[path] = File.read(path)

        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "exists", report["status"]
        assert_equal({"ace-overseer" => "exists"}, report["principals"])
        assert_empty report["kept"]
        assert_equal({"ace-overseer" => {"projects" => %w[atlas]}},
          YAML.load_file(path)["principals"])
      end
    end

    def test_converged_re_run_does_not_rewrite_the_document
      # An admin-authored comment and the file identity both survive a
      # converged wet re-run: the write is skipped, not re-emitted.
      initial = <<~YAML
        # managed by ops — do not reformat
        ---
        principals:
          ace-overseer:
            projects:
            - atlas
      YAML
      with_provisioner(initial) do |provisioner, path|
        before = File.stat(path)

        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "exists", report["status"]
        after = File.stat(path)
        assert_equal before.ino, after.ino
        assert_equal before.mtime, after.mtime
        assert_equal initial, File.read(path)
      end
    end

    def test_empty_grants_with_absent_document_is_a_no_op
      with_provisioner do |provisioner, path|
        report = provisioner.call(desired: {}, declared_projects: %w[atlas])

        assert_equal "skipped", report["status"]
        assert_empty report["principals"]
        assert_empty report["kept"]
        assert_match(/nothing to write/, report["message"])
        refute File.exist?(path)
      end
    end

    def test_malformed_principal_policy_is_refused_without_writing
      with_provisioner(grants_document({"operator" => "not-a-mapping"})) do |provisioner, path|
        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "failed", report["status"]
        assert_match(/principal projects must be an array of non-empty strings/,
          report["message"])
        assert_equal({"operator" => "not-a-mapping"},
          YAML.load_file(path)["principals"])
      end
    end

    def test_padded_principal_key_is_written_stripped_without_a_twin
      padded = YAML.dump({"principals" => {" operator " => {"projects" => %w[atlas]}}})
      with_provisioner(padded) do |provisioner, path|
        report = provisioner.call(desired: {"operator" => %w[atlas], "ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "updated", report["status"]
        assert_equal({"operator" => "exists", "ace-overseer" => "created"}, report["principals"])
        principals = YAML.load_file(path)["principals"]
        assert_equal %w[ace-overseer operator], principals.keys.sort
        assert_equal %w[atlas], principals["operator"]["projects"]
      end
    end

    def test_partial_grants_grow_and_are_reported_updated
      with_provisioner(grants_document({"ace-overseer" => {"projects" => %w[atlas]}})) do |provisioner, path|
        report = provisioner.call(
          desired: {"ace-overseer" => %w[atlas borealis]},
          declared_projects: %w[atlas borealis]
        )

        assert_equal "updated", report["status"]
        assert_equal({"ace-overseer" => "updated"}, report["principals"])
        assert_equal({"ace-overseer" => {"projects" => %w[atlas borealis]}},
          YAML.load_file(path)["principals"])
      end
    end

    def test_manifest_removing_an_existing_grant_is_refused_without_writing
      with_provisioner(grants_document({
        "ace-overseer" => {"projects" => %w[atlas borealis]},
        "operator" => {"projects" => %w[atlas]}
      })) do |provisioner, path|
        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas borealis])

        assert_equal "failed", report["status"]
        assert_match(/refusing to remove trusted grants/, report["message"])
        assert_match(/borealis/, report["message"])
        # nothing was written: the trusted document is untouched
        assert_equal %w[atlas borealis],
          YAML.load_file(path)["principals"]["ace-overseer"]["projects"]
      end
    end

    def test_undeclared_principals_are_preserved_and_reported_kept
      with_provisioner(grants_document({"operator" => {"projects" => %w[atlas]}})) do |provisioner, path|
        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "updated", report["status"]
        assert_equal %w[operator], report["kept"]
        principals = YAML.load_file(path)["principals"]
        assert_equal %w[atlas], principals["operator"]["projects"]
        assert_equal %w[atlas], principals["ace-overseer"]["projects"]
      end
    end

    def test_other_document_sections_are_preserved
      document = YAML.dump({"adapters" => {"hermes" => {"url" => "https://hermes.local"}},
                            "principals" => {"operator" => {"projects" => %w[atlas]}}})
      with_provisioner(document) do |provisioner, path|
        provisioner.call(desired: {"ace-overseer" => %w[atlas]}, declared_projects: %w[atlas])

        written = YAML.load_file(path)
        assert_equal({"hermes" => {"url" => "https://hermes.local"}}, written["adapters"])
      end
    end

    def test_dry_run_predicts_without_writing
      with_provisioner(grants_document({"operator" => {"projects" => %w[atlas]}})) do |provisioner, path|
        report = provisioner.call(
          desired: {"ace-overseer" => %w[atlas], "operator" => %w[atlas borealis]},
          declared_projects: %w[atlas borealis], dry_run: true
        )

        assert_equal "would_update", report["status"]
        assert_equal({"ace-overseer" => "would_create", "operator" => "would_update"},
          report["principals"])
        assert_equal %w[atlas], YAML.load_file(path)["principals"]["operator"]["projects"]
        refute YAML.load_file(path)["principals"].key?("ace-overseer")
      end
    end

    def test_unparseable_document_fails_without_overwrite
      with_provisioner("::: not yaml") do |provisioner, path|
        report = provisioner.call(desired: {"ace-overseer" => %w[atlas]},
          declared_projects: %w[atlas])

        assert_equal "failed", report["status"]
        assert_match(/could not be parsed as YAML; refusing to overwrite/, report["message"])
        assert_equal "::: not yaml", File.read(path)
      end
    end

    def test_foreign_grants_detection
      with_provisioner(grants_document({"operator" => {"projects" => %w[atlas zephyr]}})) do |provisioner|
        conflict = provisioner.foreign_grants?(%w[atlas borealis])

        assert_match(/refusing to overwrite a foreign lab/, conflict)
        assert_match(/zephyr/, conflict)
        assert_match(/operator/, conflict)
      end

      with_provisioner(grants_document({"operator" => {"projects" => %w[atlas]}})) do |provisioner|
        assert_nil provisioner.foreign_grants?(%w[atlas borealis])
      end

      with_provisioner do |provisioner|
        assert_nil provisioner.foreign_grants?(%w[atlas])
      end
    end

    def test_foreign_detection_raises_on_untrusted_document
      resolver = StubResolver.new
      def resolver.read_verified(_path)
        raise Ace::Lab::InvalidConfigurationError, "verification failed"
      end
      provisioner = Ace::Lab::Molecules::GrantProvisioner.new(
        resolver: resolver, authorization_path: "/etc/lab/ace-lab/authorization.yml"
      )

      assert_raises(Ace::Lab::InvalidConfigurationError) do
        provisioner.foreign_grants?(%w[atlas])
      end
    end
  end
end
