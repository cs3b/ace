# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module Molecules
      # The host-installed forge merge configuration (spec 8x3.t.xz9.5
      # integration handoff): one root-owned trusted document, the scoped
      # service identity inside it, and fail-closed loading. The real
      # deployed file is provisioned by the host at /etc/lab/ace-lab/ —
      # these tests prove the loader's closed contract. Trusted-storage
      # verification is shared with the authorization grants and exercised
      # here through the missing/untrusted cases; the shape contract is
      # proven by direct construction (tests cannot provision root-owned
      # storage).
      class ForgeMergeConfigTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir("forge-merge-config")
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def test_missing_file_is_the_actionable_config_missing_refusal
          skip "host has already installed #{ForgeMergeConfig::DEFAULT_PATH}" if
            File.readable?(ForgeMergeConfig::DEFAULT_PATH)
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            ForgeMergeConfig.load(ForgeMergeConfig::DEFAULT_PATH)
          end
          assert_includes error.message,
            "config missing: #{ForgeMergeConfig::DEFAULT_PATH}"
          assert_includes error.message, "owner: host-integrator"
        end

        def test_default_path_is_the_host_installation_path
          assert_equal "/etc/lab/ace-lab/forge-merge.yml", ForgeMergeConfig::DEFAULT_PATH
          assert_equal "host-integrator", ForgeMergeConfig::DEFAULT_ESCALATION_OWNER
        end

        def test_untrusted_storage_fails_closed
          path = File.join(@dir, "forge-merge.yml")
          File.write(path, YAML.safe_dump(valid_document))
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            ForgeMergeConfig.load(path)
          end
          assert_includes error.message, path
          assert_includes error.message, "failed the deployment ownership verification"
        end

        def test_unparseable_trusted_document_fails_closed
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            ForgeMergeConfig.new("just a string")
          end
          assert_includes error.message, "must contain exactly"
        end

        def test_valid_configuration_carries_every_closed_field
          config = ForgeMergeConfig.new(valid_document)
          assert_equal "https://forgejo.example.net", config.base_url
          assert_equal "cs3b", config.owner
          assert_equal "ace", config.repo
          assert_equal "scoped-token-value", config.token
          assert_equal 900, config.merge_timeout_seconds
          assert_equal "host-integrator", config.escalation_owner
          assert_equal true, config.review_attachment_enabled
        end

        def test_review_attachment_can_be_disabled
          config = ForgeMergeConfig.new(
            valid_document.merge("review_attachment" => {"enabled" => false})
          )
          refute config.review_attachment_enabled
        end

        def test_token_is_never_rendered_by_inspect
          config = ForgeMergeConfig.new(valid_document)
          refute_includes config.inspect, "scoped-token-value"
          assert_includes config.inspect, "[REDACTED]"
        end

        def test_unknown_or_missing_keys_refuse
          assert_raises(Ace::Lab::InvalidConfigurationError) { ForgeMergeConfig.new(nil) }
          assert_raises(Ace::Lab::InvalidConfigurationError) do
            ForgeMergeConfig.new(valid_document.merge("extra" => "x"))
          end
          assert_raises(Ace::Lab::InvalidConfigurationError) do
            ForgeMergeConfig.new(valid_document.except("token"))
          end
          assert ForgeMergeConfig.new(valid_document)
        end

        def test_misshaped_values_refuse
          [
            ["token", "short"],
            ["base_url", "http://forge.example.net"],
            ["base_url", "https://forge.example.net/api"],
            ["owner", "not/a-repo"],
            ["merge_timeout_seconds", 0],
            ["merge_timeout_seconds", "900"],
            ["escalation_owner", "host integrator"]
          ].each do |key, value|
            error = assert_raises(Ace::Lab::InvalidConfigurationError) do
              ForgeMergeConfig.new(valid_document.merge(key => value))
            end
            assert_includes error.message, key.to_s
          end
        end

        def test_misshaped_review_attachment_refuses
          [{"enabled" => "yes"}, {}, {"enabled" => true, "extra" => 1}].each do |attachment|
            assert_raises(Ace::Lab::InvalidConfigurationError) do
              ForgeMergeConfig.new(valid_document.merge("review_attachment" => attachment))
            end
          end
        end

        private

        def valid_document
          {
            "base_url" => "https://forgejo.example.net",
            "owner" => "cs3b",
            "repo" => "ace",
            "token" => "scoped-token-value",
            "merge_timeout_seconds" => 900,
            "escalation_owner" => "host-integrator",
            "review_attachment" => {"enabled" => true}
          }
        end
      end
    end
  end
end
