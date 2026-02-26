# frozen_string_literal: true

require "fileutils"
require "yaml"
require "securerandom"
require "ace/b36ts"
require "ace/core/config_discovery"

module Ace
  module Taskflow
    module Molecules
      # Handles deterministic storage for next-phase simulation artifacts.
      class SimulationSessionStore
        DEFAULT_CACHE_DIR = ".cache/ace-taskflow/simulations"

        def initialize(cache_root: nil)
          @cache_root = resolve_cache_root(cache_root)
        end

        attr_reader :cache_root

        def create_session_dir!(run_id)
          validate_run_id!(run_id)
          session_dir = File.join(@cache_root, run_id)
          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def write_yaml_artifact(session_dir, filename, data)
          write_artifact(session_dir, filename, YAML.dump(data))
        end

        def write_markdown_artifact(session_dir, filename, content)
          write_artifact(session_dir, filename, content.to_s)
        end

        private

        def resolve_cache_root(cache_root)
          root = cache_root || configured_cache_dir || DEFAULT_CACHE_DIR
          return root if root.start_with?("/")

          project_root = Ace::Core::ConfigDiscovery.project_root || Dir.pwd
          File.join(project_root, root)
        end

        def configured_cache_dir
          config = Ace::Taskflow.configuration.config
          config.dig("review", "next_phase", "cache_dir") ||
            config.dig("taskflow", "review", "next_phase", "cache_dir")
        end

        def validate_run_id!(run_id)
          return if Ace::B36ts.valid?(run_id)

          raise ArgumentError, "Invalid run_id format: #{run_id.inspect}. Expected 6-char ace-b36ts ID."
        end

        def write_artifact(session_dir, filename, content)
          FileUtils.mkdir_p(session_dir)
          target_path = File.join(session_dir, filename)
          tmp_path = "#{target_path}.tmp.#{Process.pid}.#{SecureRandom.hex(4)}"
          File.write(tmp_path, content)
          File.rename(tmp_path, target_path)
          target_path
        end
      end
    end
  end
end
