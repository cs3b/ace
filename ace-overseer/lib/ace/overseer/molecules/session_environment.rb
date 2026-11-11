# frozen_string_literal: true

require "json"
require "fileutils"
require "tmpdir"
require "tempfile"
require "ace/lab/auth/session_configuration"
require "ace/support/cli/toolchain"

module Ace::Overseer::Molecules
  # Passive deployment data becomes an explicit environment for one ordinary
  # child. Files here are transient credentials, not a session state store.
  class SessionEnvironment
    BASE_KEYS = %w[HOME USER LOGNAME SHELL TERM LANG LC_ALL TZ TMPDIR PATH GEM_HOME GEM_PATH ACE_TOOLCHAIN
      HERDR_SOCKET_PATH HERDR_WORKSPACE_ID].freeze
    RESERVED = %w[ACE_TOOLCHAIN GEM_HOME GEM_PATH PATH PI_CODING_AGENT_DIR ACE_SESSION_CREDENTIALS_DIRECTORY BUNDLE_GEMFILE RUBYOPT RUBYLIB].freeze
    MAX_BYTES = 65_536
    ENVIRONMENT_ROLES = {"reviewer" => "verifier", "bootstrap-verifier" => "verifier", "bootstrap-worker" => "worker"}.freeze

    def initialize(env: ENV, manifest_loader: -> { Ace::Lab::Molecules::InstallManifestLoader.load },
      manifest_path: Ace::Lab.install_manifest_path)
      @env, @loader, @manifest_path = env, manifest_loader, manifest_path
    end

    def with_environment(root:, role:)
      environment = @env.to_h.slice(*BASE_KEYS)
      directory = nil
      handed_off = false
      args = []
      if @env["ACE_TOOLCHAIN"] == "installed"
        selection = selection_for(root, role)
        runtime = selection.runtime
        args = ["--model", "#{runtime.fetch('provider')}/#{runtime.fetch('model')}"]
        [runtime.fetch("node"), runtime.fetch("pi")].each do |path|
          raise Ace::Overseer::Error, "installed runtime executable is unavailable: #{path}" unless File.executable?(path)
        end
        directory = Dir.mktmpdir("ace-session-")
        File.chmod(0o700, directory)
        provider = runtime.fetch("provider")
        auth = read_private_json(runtime.fetch("credentials"))
        raise Ace::Overseer::Error, "model provider credentials are unavailable" unless auth[provider].is_a?(Hash) && !auth[provider].empty?
        write_private(File.join(directory, "auth.json"), provider => auth.fetch(provider))
        write_private(File.join(directory, "settings.json"), "defaultProjectTrust" => "never")
        environment = configured_environment(selection)
        environment.merge!("PI_CODING_AGENT_DIR" => directory, "ACE_SESSION_CREDENTIALS_DIRECTORY" => directory)
      else
        environment.merge!(ProjectBundle.environment(root, env: @env)).compact!
      end
      Tempfile.create(["ace-environment-", ".json"]) do |file|
        file.chmod(0o600)
        file.write(JSON.generate(environment))
        file.flush
        file.fsync
        handed_off = true
        yield file.path, directory, args
      end
    rescue StandardError
      FileUtils.remove_entry(directory) if !handed_off && directory && File.directory?(directory)
      raise
    end

    # A projection needs this project's read credentials and installed CLI,
    # not the coordinator's token or a new model-auth directory per poll.
    def observation_environment(root:)
      configured_environment(selection_for(root, "project-overseer"))
    end

    def self.cleanup(directory)
      return unless directory
      # Only our exact scratch directory; never a caller's home/config root.
      unless File.absolute_path(directory) == directory && File.dirname(directory) == Dir.tmpdir.chomp(File::SEPARATOR) &&
          File.basename(directory).start_with?("ace-session-") && !File.symlink?(directory)
        raise Ace::Overseer::Error, "invalid session credential directory"
      end
      # Pi's transcript may live beside auth.json. Keep execution evidence.
      File.unlink(File.join(directory, "auth.json")) if File.file?(File.join(directory, "auth.json"))
    end

    private

    def selection_for(root, role)
      raise Ace::Overseer::Error, "installed deployment manifest is unavailable" unless File.file?(@manifest_path)
      document = @loader.call
      project = ([document["coordinator"]] + document.fetch("projects")).compact.find do |entry|
        root == entry["path"] || root.start_with?("#{entry['path']}/.ace-wt/")
      end
      raise Ace::Overseer::Error, "execution directory is not a configured project" unless project
      Ace::Lab::Auth::SessionConfiguration.new(loader: -> { document }).resolve(
        project: project.fetch("id"), role: ENVIRONMENT_ROLES.fetch(role, role))
    end

    def configured_environment(selection)
      environment = @env.to_h.slice(*BASE_KEYS)
      if selection.environment_file
        values = read_private_json(selection.environment_file)
        unless values.all? { |key, value| key.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) && value.is_a?(String) && !value.include?("\0") } &&
            (values.keys & RESERVED).empty? && values.keys.none? { |key| key.start_with?("BUNDLE", "BUNDLER_") }
          raise Ace::Overseer::Error, "role environment contains invalid or reserved variables"
        end
        environment.merge!(values)
      end
      runtime = selection.runtime
      environment.merge("HERDR_SOCKET_PATH" => runtime.fetch("herdr").fetch("socket"),
        "ACE_TOOLCHAIN" => "installed", "GEM_HOME" => selection.gem_home,
        "GEM_PATH" => selection.gem_home,
        "PATH" => ([File.join(selection.gem_home, "bin"), File.dirname(runtime.fetch("node")), File.dirname(runtime.fetch("pi"))] + runtime.fetch("path")).uniq.join(File::PATH_SEPARATOR))
    end

    def read_private_json(path)
      File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
        stat = file.stat
        unless stat.file? && [0, Process.uid].include?(stat.uid) && (stat.mode & 0o777) == 0o600 && stat.size <= MAX_BYTES
          raise Ace::Overseer::Error, "credential source must be a private regular file"
        end
        value = JSON.parse(file.read(MAX_BYTES + 1), create_additions: false, max_nesting: 8)
        raise Ace::Overseer::Error, "credential source must be a JSON object" unless value.is_a?(Hash)
        value
      end
    rescue JSON::ParserError, SystemCallError
      raise Ace::Overseer::Error, "configured credential source is unavailable or invalid"
    end

    def write_private(path, value)
      File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) { |file| file.write(JSON.generate(value)) }
    end
  end
end
