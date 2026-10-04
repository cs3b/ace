# frozen_string_literal: true

require "ace/support/cli"
require "optparse"
require "fileutils"
require_relative "runtime"

module Ace
  module Hitl
    module Hermes
      module CLI
        def self.start(argv, input: $stdin, output: $stdout)
          args = argv.dup
          operation = args.shift
          if [nil, "--help", "-h", "help"].include?(operation)
            output.puts("ace-hitl-hermes serve|submit|receive|delivery|ingress reconcile|plugin install --config FILE")
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
            %w[config request revision channel through format path].each do |key|
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
          runtime = Runtime.new(options.fetch(:config))
          result = case operation
          when "serve" then runtime.serve(once: options[:once]); {"status" => "stopped"}
          when "submit"
            runtime.relay.submit(channel: options.fetch(:channel), request: options.fetch(:request),
              revision: options.fetch(:revision))
          when "receive"
            bytes = input.read(16 * 1024 + 1)
            raise ContractError, "ingress frame too large" if bytes.bytesize > 16 * 1024
            runtime.relay.receive(JSON.parse(bytes))
          when "delivery" then runtime.relay.delivery(options.fetch(:request))
          when "reconcile"
            runtime.relay.reconcile(request: options.fetch(:request), through: options.fetch(:through))
          else raise ContractError, "choose serve, submit, receive, delivery, ingress reconcile, or plugin install"
          end
          output.puts(JSON.generate(result))
        rescue ContractError, JSON::ParserError, KeyError, OptionParser::ParseError, SystemCallError
          # No exception detail: a malformed frame or HTTP error may contain a secret.
          raise Ace::Support::Cli::Error, "Hermes operation rejected; verify configuration and non-secret delivery status"
        end
      end
    end
  end
end
