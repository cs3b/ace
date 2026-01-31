# frozen_string_literal: true

require "yaml"
require "fileutils"

module Ace
  module Coworker
    module CLI
      module Commands
        # Prepare a new job configuration file from a preset
        class Prepare < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Prepare a job.yaml from a preset template"

          argument :preset, required: true, desc: "Preset name (e.g., work-on-task, work-on-tasks)"

          option :taskref, type: :string, desc: "Single task reference (e.g., 123)"
          option :taskrefs, type: :string, desc: "Multiple task refs (comma-separated, range, or pattern)"
          option :output, aliases: ["-o"], type: :string, desc: "Output path for job.yaml"
          option :review_preset, type: :string, default: "batch", desc: "Review preset for batch workflows"

          def call(preset:, **options)
            # Find and load preset
            preset_path = find_preset(preset)
            unless preset_path
              warn "ERROR: Preset '#{preset}' not found"
              warn ""
              warn "Available presets:"
              list_presets.each { |p| warn "  - #{p}" }
              return 1
            end

            preset_config = YAML.safe_load_file(preset_path, permitted_classes: [Date, Time])

            # Build parameters from options
            parameters = build_parameters(preset_config, options)

            # Validate required parameters
            errors = Atoms::PresetExpander.validate_parameters(preset_config, parameters)
            if errors.any?
              warn "ERROR: #{errors.join(', ')}"
              return 1
            end

            # Expand preset into steps
            steps = Atoms::PresetExpander.expand(preset_config, parameters)

            # Generate job.yaml content
            job_config = {
              "session" => {
                "name" => generate_session_name(preset, parameters),
                "description" => preset_config["description"]
              },
              "steps" => steps
            }

            # Determine output path
            output_path = options[:output] || default_output_path

            # Write job.yaml
            FileUtils.mkdir_p(File.dirname(output_path))
            File.write(output_path, job_config.to_yaml)

            # Report success
            puts "Job configuration created: #{output_path}"
            puts ""
            puts "Session: #{job_config['session']['name']}"
            puts "Steps: #{steps.length} total"
            steps.each do |step|
              indent = step["parent"] ? "    " : "  "
              puts "#{indent}- #{step['name']} (#{step['number']})"
            end
            puts ""
            puts "Start session with: ace-coworker create #{output_path}"

            0
          end

          private

          def find_preset(name)
            # Check standard preset locations
            locations = preset_search_paths

            locations.each do |dir|
              path = File.join(dir, "#{name}.yml")
              return path if File.exist?(path)

              path_yaml = File.join(dir, "#{name}.yaml")
              return path_yaml if File.exist?(path_yaml)
            end

            nil
          end

          def preset_search_paths
            paths = []

            # Project-local presets
            paths << ".ace/coworker/presets"

            # Gem defaults
            gem_root = Gem.loaded_specs["ace-coworker"]&.gem_dir ||
                       File.expand_path("../../../../..", __dir__)
            paths << File.join(gem_root, ".ace-defaults", "coworker", "presets")

            paths
          end

          def list_presets
            presets = []
            preset_search_paths.each do |dir|
              next unless Dir.exist?(dir)

              Dir.glob(File.join(dir, "*.{yml,yaml}")).each do |path|
                presets << File.basename(path, ".*")
              end
            end
            presets.uniq.sort
          end

          def build_parameters(preset_config, options)
            params = {}

            # Handle taskref (single task)
            params["taskref"] = options[:taskref] if options[:taskref]

            # Handle taskrefs (multiple tasks)
            if options[:taskrefs]
              params["taskrefs"] = Atoms::PresetExpander.parse_array_parameter(options[:taskrefs])
            end

            # Handle review_preset
            params["review_preset"] = options[:review_preset]

            # Apply defaults from preset config
            param_defs = preset_config["parameters"] || {}
            param_defs.each do |name, config|
              next if params.key?(name)
              params[name] = config["default"] if config["default"]
            end

            params
          end

          def generate_session_name(preset, parameters)
            suffix = if parameters["taskrefs"]&.any?
                       parameters["taskrefs"].first(3).join("-")
                     elsif parameters["taskref"]
                       parameters["taskref"]
                     else
                       Time.now.strftime("%Y%m%d-%H%M%S")
                     end

            "#{preset}-#{suffix}"
          end

          def default_output_path
            timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
            "job-#{timestamp}.yaml"
          end
        end
      end
    end
  end
end
