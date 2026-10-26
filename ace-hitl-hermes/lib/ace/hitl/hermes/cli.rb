# frozen_string_literal: true

require "ace/support/cli"
require "optparse"
require "fileutils"
require "yaml"
require "ace/support/fs"
require_relative "runtime"
require_relative "organisms/native_sync"

module Ace
  module Hitl
    module Hermes
      module CLI
        def self.start(argv, input: $stdin, output: $stdout)
          args = argv.dup
          operation = args.shift
          if [nil, "--help", "-h", "help"].include?(operation)
            output.puts("ace-hitl-hermes sync|serve|submit|receive|delivery|ingress reconcile|plugin install [--config FILE] [--route NAME]")
            return
          end
          if %w[--version version].include?(operation)
            output.puts(Ace::Hitl::Hermes::VERSION)
            return
          end
          operation = "reconcile" if operation == "ingress" && args.shift == "reconcile"
          operation = "install" if operation == "plugin" && args.shift == "install"
          options = {format: "json"}
          parser = OptionParser.new do |o|
            o.banner = "ace-hitl-hermes serve|submit|receive|delivery|ingress reconcile|plugin install [options]"
            %w[config request revision channel project through format path route].each do |key|
              o.on("--#{key} VALUE") { |value| options[key.to_sym] = value }
            end
            o.on("--once") { options[:once] = true }
            o.on("--help") { output.puts(o); return }
          end
          parser.parse!(args)
          raise ContractError, "unexpected arguments" unless args.empty?
          raise ContractError, "only --format json is supported" unless options[:format] == "json"
          if operation == "install"
            destination = options.fetch(:path)
            raise ContractError, "plugin installation requires an absolute path" unless File.absolute_path?(destination)
            raise ContractError, "plugin destination already exists" if File.exist?(destination)
            FileUtils.cp_r(File.expand_path("../../../../plugin", __dir__), destination)
            output.puts(JSON.generate({"installed" => true, "path" => destination}))
            return
          end
          if operation == "sync"
            # One source per project: the route comes straight from the
            # project's .ace/hitl/config.yml (hitl.adapters.routes). No
            # second native-route.json file, no compatibility layer. Route
            # selection errors are configuration errors: they carry their
            # actionable message (no frame content involved).
            begin
              route = sync_route(options)
            rescue ContractError => e
              raise Ace::Support::Cli::Error, e.message
            end
            result = Organisms::NativeSync.new(route).run
            output.puts(JSON.generate(result))
            raise ContractError, "native synchronization incomplete" unless result["errors"].empty?
            return
          end
          runtime = Runtime.new(options.fetch(:config))
          result = case operation
          when "serve" then runtime.serve(once: options[:once]); {"status" => "stopped"}
          when "submit"
            runtime.relay.submit(channel: options.fetch(:channel), project: options.fetch(:project),
              request: options.fetch(:request), revision: options.fetch(:revision))
          when "receive"
            bytes = input.read(16 * 1024 + 1)
            raise ContractError, "ingress frame too large" if bytes.bytesize > 16 * 1024
            runtime.relay.receive(JSON.parse(bytes))
          when "delivery"
            runtime.relay.delivery(channel: options.fetch(:channel), project: options.fetch(:project),
              request: options.fetch(:request))
          when "reconcile"
            runtime.relay.reconcile(channel: options.fetch(:channel), project: options.fetch(:project),
              request: options.fetch(:request), through: options.fetch(:through))
          else raise ContractError, "choose serve, submit, receive, delivery, ingress reconcile, or plugin install"
          end
          output.puts(JSON.generate(result))
        rescue ContractError, JSON::ParserError, KeyError, OptionParser::ParseError, SystemCallError, Psych::Exception
          # No exception detail: a malformed frame or HTTP error may contain a secret.
          raise Ace::Support::Cli::Error, "Hermes operation rejected; verify configuration and non-secret delivery status"
        end

        # Load the project's hitl config (shaped `hitl:` or flat documents both
        # work) and select the hermes_native route to reconcile: `--route NAME`
        # picks explicitly; a single native route is used unambiguous; several
        # native routes require the explicit name. `--config` points at a
        # non-default project config; the default is `.ace/hitl/config.yml` in
        # the enclosing project root.
        def self.sync_route(options)
          path = options[:config] || File.join(
            Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, ".ace", "hitl", "config.yml")
          raise ContractError, "sync config not found: #{path} (run inside the project or pass --config)" unless File.file?(path)
          document = YAML.safe_load_file(File.expand_path(path), aliases: true)
          raise ContractError, "sync config is not a mapping: #{path}" unless document.is_a?(Hash)

          namespace = document["hitl"].is_a?(Hash) ? document["hitl"].dup : {}
          document.reject { |key, _| key == "hitl" }.each { |key, value| namespace[key] = value }
          native = Array(namespace.dig("adapters", "routes")).select do |entry|
            entry.is_a?(Hash) && entry["adapter"] == "hermes_native"
          end
          raise ContractError, "no hermes_native route in #{path}" if native.empty?

          name = options[:route]
          if name
            native.find { |entry| entry["route"] == name } or
              raise ContractError, "no hermes_native route '#{name}' in #{path}; available: #{native.map { |entry| entry["route"] }.join(", ")}"
          elsif native.size == 1
            native.first
          else
            raise ContractError, "multiple hermes_native routes in #{path}; choose --route NAME among: #{native.map { |entry| entry["route"] }.join(", ")}"
          end
        end
      end
    end
  end
end
