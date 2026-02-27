# frozen_string_literal: true

require "yaml"
require "fileutils"

module Ace
  module Sim
    module Molecules
      class SessionStore
        class RunDirectoryExistsError < StandardError; end

        attr_reader :cache_root

        def initialize(cache_root: nil)
          @cache_root = cache_root || Ace::Sim.get("sim", "cache_root") || ".cache/ace-sim"
        end

        def run_dir_for(run_id)
          File.join(cache_root, "simulations", run_id)
        end

        def prepare_run(run_id)
          run_dir = run_dir_for(run_id)
          raise RunDirectoryExistsError, "Run directory already exists: #{run_dir}" if Dir.exist?(run_dir)

          FileUtils.mkdir_p(File.join(run_dir, "chains"))
          run_dir
        end

        def chain_dir(run_dir, provider, iteration)
          provider_slug = provider.to_s.gsub(/[^a-zA-Z0-9_-]/, "-")
          File.join(run_dir, "chains", "#{provider_slug}-#{iteration}")
        end

        def final_dir(run_dir)
          File.join(run_dir, "final")
        end

        def prepare_step_dir(run_dir, provider, iteration, step_index, step_name)
          dirname = format("%02d-%s", step_index, step_name)
          dir = File.join(chain_dir(run_dir, provider, iteration), dirname)
          FileUtils.mkdir_p(dir)
          dir
        end

        def write_session(run_dir, payload)
          write_yaml(File.join(run_dir, "session.yml"), payload)
        end

        def write_synthesis(run_dir, payload)
          write_yaml(File.join(run_dir, "synthesis.yml"), payload)
        end

        def write_yaml(path, payload)
          write_text(path, YAML.dump(payload))
        end

        def write_text(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
          path
        end
      end
    end
  end
end
