# frozen_string_literal: true

require "rubygems"
require "shellwords"

module Ace
  module Support
    module Cli
      # Selection policy, not authority: project data/configuration remain usable.
      module Toolchain
        class Error < StandardError; end

        module_function

        def installed?
          mode = ENV.fetch("ACE_TOOLCHAIN", "auto")
          raise Error, "unknown ACE_TOOLCHAIN #{mode.inspect}; use auto or installed" unless %w[auto installed].include?(mode)

          mode == "installed"
        end

        def installed_spec?(spec)
          return false unless spec.loaded_from && File.file?(spec.loaded_from)

          root = File.realpath(spec.base_dir)
          gem_path = File.realpath(spec.full_gem_path)
          specification = File.realpath(spec.loaded_from)
          gem_path.start_with?("#{root}/gems/") &&
            specification.start_with?("#{root}/specifications/")
        rescue Errno::ENOENT
          false
        end

        def verify_loaded!
          return unless installed?

          Gem.loaded_specs.each_value do |spec|
            next if installed_spec?(spec) || spec.default_gem?

            raise Error, "installed toolchain loaded source dependency #{spec.name}: #{spec.full_gem_path}"
          end
          roots = Gem.loaded_specs.values.select { |spec| installed_spec?(spec) }
            .map { |spec| "#{File.realpath(spec.full_gem_path)}/" }
          $LOADED_FEATURES.grep(%r{/lib/ace/}).each do |feature|
            actual = File.realpath(feature)
            next if roots.any? { |root| actual.start_with?(root) }

            raise Error, "installed toolchain loaded source code outside its gem closure: #{actual}"
          end
        end

        def executable(name, project_root: nil, prefer_project: true)
          unless installed?
            candidate = File.join(project_root, "bin", name) if project_root && prefer_project
            return candidate if candidate && File.executable?(candidate)

            return name
          end

          verify_loaded!
          spec = Gem::Specification.find_all.select do |entry|
            entry.executables.include?(name) && installed_spec?(entry)
          end.max_by(&:version)
          raise Error, "installed executable #{name} unavailable; install its published gem" unless spec

          path = File.join(spec.full_gem_path, spec.bindir, name)
          unless File.executable?(path) && File.realpath(path).start_with?("#{File.realpath(spec.full_gem_path)}/")
            raise Error, "installed executable #{name} missing or outside its gem: #{path}"
          end
          path
        end

        # Bundler/Ruby source injection must not leak into subprocesses. Domain
        # environment (including credentials) is inherited, never inspected here.
        def child_environment
          return {} unless installed?

          ENV.keys.grep(/\ABUNDLER?_/).to_h { |key| [key, nil] }.merge(
            "RUBYOPT" => nil, "RUBYLIB" => nil, "ACE_TOOLCHAIN" => "installed",
            "GEM_HOME" => Gem.dir, "GEM_PATH" => Gem.path.join(File::PATH_SEPARATOR),
            "PATH" => [Gem.bindir, File.dirname(Gem.ruby), ENV.fetch("PATH", "")].join(File::PATH_SEPARATOR)
          )
        end

        def shell_setup
          return "" unless installed?

          names = (ENV.keys.grep(/\ABUNDLER?_/) +
            %w[BUNDLE_GEMFILE BUNDLE_PATH BUNDLE_BIN_PATH BUNDLER_SETUP RUBYOPT RUBYLIB]).uniq
          path = [Gem.bindir, File.dirname(Gem.ruby), ENV.fetch("PATH", "")].join(File::PATH_SEPARATOR)
          values = {"ACE_TOOLCHAIN" => "installed", "GEM_HOME" => Gem.dir,
                    "GEM_PATH" => Gem.path.join(File::PATH_SEPARATOR), "PATH" => path}
          "unset #{names.map { |name| Shellwords.escape(name) }.join(" ")}; export " +
            values.map { |name, value| "#{name}=#{Shellwords.escape(value)}" }.join(" ") + "; "
        end

        def shell_command(name, *args)
          shell_setup + Shellwords.join([executable(name), *args])
        end

        def evidence
          {"mode" => installed? ? "installed" : "auto",
           "gems" => Gem.loaded_specs.values.select { |spec| spec.name.start_with?("ace-") }
             .to_h do |spec|
               [spec.name, {"version" => spec.version.to_s, "path" => spec.full_gem_path,
                            "executables" => spec.executables.to_h { |name| [name, File.join(spec.full_gem_path, spec.bindir, name)] }}]
             end}
        end
      end
    end
  end
end
