# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class InstallManifestLoaderTest < Minitest::Test
    MANIFEST_YAML = <<~YAML
      ---
      schema_version: 1
      machine: lab01
      accounts:
        - username: ace-worker
          role: worker
          create: false
      directories:
        - path: /home/ace-worker/labs
          owner: ace-worker
          mode: "0750"
      keys:
        - account: ace-worker
      roles:
        - id: worker
          account: ace-worker
          instructions: wfi://assign/work
    YAML

    def load(path: "/etc/lab/ace-lab/install.yml", platform: "linux")
      Ace::Lab::Molecules::InstallManifestLoader.load(path: path, platform: platform)
    end

    def test_trusted_root_owned_manifest_loads_through_read_verified_seam
      # Same stub pattern as GrantResolverTest: a root-owned chain with a
      # root-owned 0600 file passes verification and yields content
      secure_dir = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, true, 0, 0o755)
      secure_file = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, false, 0, 0o600)
      path = "/etc/lab/ace-lab/install.yml"
      fake_io = Struct.new(:stat, :read, :close).new(secure_file, MANIFEST_YAML, nil)

      File.stub :lstat, ->(candidate) { candidate.to_s.end_with?("install.yml") ? secure_file : secure_dir } do
        File.stub :open, ->(_candidate, _flags) { fake_io } do
          manifest = load(path: path)

          assert_equal "lab01", manifest["machine"]
          assert_equal "/home/ace-worker/.ssh/id_ed25519", manifest["keys"].first["path"]
        end
      end
    end

    def test_missing_manifest_is_a_directed_administrator_error
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, nil do
        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load }

        assert_match(%r{install manifest: /etc/lab/ace-lab/install\.yml not found}, error.message)
        assert_match(/root-owned deployment manifest/, error.message)
      end
    end

    def test_user_owned_manifest_fails_closed
      # A user-owned file must be rejected before any parsing — a
      # caller-writable manifest could manufacture privileges
      Dir.mktmpdir do |dir|
        path = File.join(dir, "install.yml")
        File.write(path, MANIFEST_YAML)

        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load(path: path) }

        assert_match(/failed trusted deployment verification/, error.message)
        assert_match(/failing closed/, error.message)
      end
    end

    def test_unreadable_manifest_fails_closed_classified
      path = "/etc/lab/ace-lab/install.yml"

      Ace::Lab::Molecules::GrantResolver.stub :read_verified,
        ->(_path) { raise Ace::Lab::InvalidConfigurationError, "trusted authorization file failed verification" } do
        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load(path: path) }

        assert_match(/failed trusted deployment verification or could not be read/, error.message)
      end
    end

    def test_non_mapping_document_is_classified
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, "- one\n" do
        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load }

        assert_match(/manifest must be a mapping/, error.message)
      end
    end

    def test_unparseable_document_never_leaks_content
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, "secret: *private_token_canary\n" do
        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load }

        assert_match(/could not be parsed as YAML/, error.message)
        refute_includes error.message, "private_token_canary"
      end
    end

    def test_schema_invalid_manifest_reports_section_without_values
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, YAML.dump("schema_version" => 1, "machine" => "") do
        error = assert_raises(Ace::Lab::InvalidConfigurationError) { load }

        assert_match(/machine must be a non-empty string without whitespace/, error.message)
      end
    end

    def test_platform_controls_home_path_defaults
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, MANIFEST_YAML do
        manifest = load(platform: "darwin")

        assert_equal "/Users/ace-worker", manifest["accounts"].first["home"]
      end
    end
  end
end
