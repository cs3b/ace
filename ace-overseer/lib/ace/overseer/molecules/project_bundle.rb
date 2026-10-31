# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

module Ace
  module Overseer
    module Molecules
      # A project's own Gemfile/lock and binstub select its ACE version.
      # Never load child project gems into the lab coordinator's process.
      class ProjectBundle
        def self.environment(root, env: ENV)
          names = env.keys.grep(/\ABUNDLER?_/) + %w[RUBYOPT RUBYLIB GEM_HOME GEM_PATH HERDR_PANE HERDR_TAB]
          names.to_h { |name| [name, nil] }.merge(
            "BUNDLE_GEMFILE" => File.join(root, "Gemfile"),
            "ACE_TOOLCHAIN" => "installed",
            "PATH" => [File.join(root, "bin"), env.fetch("PATH", "/usr/bin:/bin")].join(File::PATH_SEPARATOR)
          )
        end

        def self.shell_setup(root, env: ENV)
          values = environment(root, env: env).reject { |name, _| %w[HERDR_PANE HERDR_TAB].include?(name) }
          cleared, assigned = values.partition { |_, value| value.nil? }
          "unset #{cleared.map { |name, _| Shellwords.escape(name) }.join(" ")}; export " +
            assigned.map { |name, value| "#{name}=#{Shellwords.escape(value)}" }.join(" ")
        end

        def call(root:, workspace:, env: ENV)
          %w[Gemfile Gemfile.lock].each do |name|
            unless File.file?(File.join(root, name))
              raise Ace::Overseer::Error, "project bundle missing #{name}; prepare this project's published gem bundle first"
            end
          end
          binary = File.join(root, "bin", "ace-overseer")
          command = File.executable?(binary) ? [binary] : ["bundle", "exec", "ace-overseer"]
          command += ["start", "--scope", "project", "--format", "json"]
          child_env = self.class.environment(root, env: env).merge("HERDR_WORKSPACE_ID" => workspace)
          out, err, status = Open3.capture3(child_env, *command, chdir: root)
          report = JSON.parse(out)
          unless report.is_a?(Hash) && report["scope"] == "project" && report["status"].is_a?(String)
            raise Ace::Overseer::Error, "project start returned no project-scope report"
          end
          if !status.success? && %w[started reused ready].include?(report["status"])
            raise Ace::Overseer::Error, "project start exited #{status.exitstatus} despite a ready report"
          end
          report
        rescue JSON::ParserError
          raise Ace::Overseer::Error, "project bundle start returned invalid JSON#{": " + err.strip[0, 300] unless err.to_s.empty?}"
        rescue SystemCallError => e
          raise Ace::Overseer::Error, "project bundle could not start: #{e.message}"
        end
      end
    end
  end
end
