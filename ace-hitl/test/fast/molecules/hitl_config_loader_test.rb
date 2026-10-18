# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Molecules
      class HitlConfigLoaderTest < AceHitlTestCase
        # The loader's own file lives at <gem_root>/lib/ace/hitl/molecules/,
        # so this resolves the REAL gem root with its shipped .ace-defaults
        # (an expansion from the test directory would land on the repo root
        # and silently disable the defaults under test).
        GEM_ROOT = File.expand_path("../../../..",
          File.dirname(Ace::Hitl::Molecules::HitlConfigLoader.method(:load).source_location.fetch(0)))

        def test_loads_shaped_project_config_from_cwd
          previous_test_mode = Ace::Support::Config.test_mode
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
            Dir.chdir(dir) { config = HitlConfigLoader.load(gem_root: GEM_ROOT) }

            assert_equal "lab01", config.dig("hitl", "machine")
            assert_equal ".ace-local/hitl", config.dig("hitl", "recipients", "overseer", "folder")
          end
        ensure
          Ace::Support::Config.test_mode = previous_test_mode
        end

        def test_loads_flat_project_config_over_real_defaults
          previous_test_mode = Ace::Support::Config.test_mode
          Ace::Support::Config.test_mode = false
          Dir.mktmpdir("hitl-cfg") do |dir|
            FileUtils.mkdir_p(File.join(dir, ".ace", "hitl"))
            File.write(File.join(dir, ".ace", "hitl", "config.yml"), <<~YAML)
              default_kind: decision
            YAML

            config = nil
            Dir.chdir(dir) { config = HitlConfigLoader.load(gem_root: GEM_ROOT) }

            # Flat project settings are never dropped by the shipped
            # defaults supplying the shaped `hitl:` key...
            assert_equal "decision", config.dig("hitl", "default_kind")
            # ...and the real defaults still merge underneath (this fails
            # when the test accidentally disables the real defaults).
            assert_equal ".ace-local/hitl", config.dig("hitl", "root_dir")
          end
        ensure
          Ace::Support::Config.test_mode = previous_test_mode
        end

        def test_flat_project_recipients_are_not_silently_dropped
          previous_test_mode = Ace::Support::Config.test_mode
          Ace::Support::Config.test_mode = false
          Dir.mktmpdir("hitl-cfg") do |dir|
            FileUtils.mkdir_p(File.join(dir, ".ace", "hitl"))
            File.write(File.join(dir, ".ace", "hitl", "config.yml"), <<~YAML)
              machine: lab01
              recipients:
                overseer:
                  machine: lab01
                  folder: .ace-local/hitl
            YAML

            config = nil
            Dir.chdir(dir) { config = HitlConfigLoader.load(gem_root: GEM_ROOT) }

            resolver = Molecules::HitlAddressResolver.new(config: config)
            address = resolver.resolve("overseer")
            assert_equal "lab01", address["machine"]
            assert_equal ".ace-local/hitl", address["folder"]
          end
        ensure
          Ace::Support::Config.test_mode = previous_test_mode
        end
      end
    end
  end
end
