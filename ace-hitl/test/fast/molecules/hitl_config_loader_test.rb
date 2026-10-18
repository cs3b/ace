# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Molecules
      class HitlConfigLoaderTest < AceHitlTestCase
        def test_loads_shaped_project_config_from_cwd
          Ace::Support::Config.test_mode = false
          Dir.mktmpdir("hitl-cfg") do |dir|
            FileUtils.mkdir_p(File.join(dir, ".ace", "hitl"))
            File.write(File.join(dir, ".ace", "hitl", "config.yml"), <<~YAML)
              hitl:
                machine: lab01
                recipients:
                  overseer:
                    machine: lab01
                    folder: .ace-local/hitl
            YAML

            config = nil
            Dir.chdir(dir) { config = HitlConfigLoader.load(gem_root: File.expand_path("../../../..", __dir__)) }

            assert_equal "lab01", config.dig("hitl", "machine")
            assert_equal ".ace-local/hitl", config.dig("hitl", "recipients", "overseer", "folder")
          end
        ensure
          Ace::Support::Config.test_mode = nil
        end

        def test_loads_flat_project_config
          Ace::Support::Config.test_mode = false
          Dir.mktmpdir("hitl-cfg") do |dir|
            FileUtils.mkdir_p(File.join(dir, ".ace", "hitl"))
            File.write(File.join(dir, ".ace", "hitl", "config.yml"), <<~YAML)
              default_kind: decision
            YAML

            config = nil
            Dir.chdir(dir) { config = HitlConfigLoader.load(gem_root: File.expand_path("../../../..", __dir__)) }

            assert_equal "decision", config.dig("hitl", "default_kind")
          end
        ensure
          Ace::Support::Config.test_mode = nil
        end
      end
    end
  end
end
