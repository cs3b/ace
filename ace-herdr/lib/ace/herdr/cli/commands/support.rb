# frozen_string_literal: true

require "ace/hitl/contract"

require "json"
require "ace/support/cli"
require "ace/core"

module Ace
  module Herdr
    module CLI
      module Commands
        # Shared collaborator construction for ace-herdr commands. The
        # executor is injectable so tests can substitute a fake; commands
        # registered in the CLI use the real herdr binary.
        module Runtime
          def executor
            @executor ||= Ace::Herdr::Molecules::HerdrExecutor.new
          end

          def config
            @config ||= Ace::Herdr.config
          end

          def deliveries_dir
            File.expand_path(config["deliveries_dir"] || ".ace-local/herdr/deliveries", Dir.pwd)
          end

          # Reverse address from flags or the caller's herdr environment,
          # fail closed (spec 8wm.t.vrz §3)
          def resolve_ref(session, pane)
            Ace::Hitl::Providers::Ref.new(
              session: Ace::Hitl::Providers::Ref.validate!(
                session || ENV["HERDR_SESSION"], "HERDR_SESSION"
              ),
              pane: Ace::Hitl::Providers::Ref.validate!(
                pane || ENV["HERDR_PANE"], "HERDR_PANE"
              )
            )
          end

          # Answer/prompt content from a file or stdin
          def read_content(path, what:)
            return $stdin.read if path.nil? || path.empty?

            File.read(path)
          rescue Errno::ENOENT
            raise Ace::Support::Cli::Error, "#{what} file not found: #{path}"
          end

          def cli_error(message)
            raise Ace::Support::Cli::Error, message
          end

          # Contract and executor failures become CLI errors (ADR-023)
          def translate_errors
            yield
          rescue Ace::Hitl::Providers::InvalidRefError,
            Ace::Hitl::Providers::ProviderUnavailableError,
            Ace::Herdr::ValidationError,
            Ace::Herdr::TargetResolutionError,
            Ace::Herdr::WaitTimeoutError,
            Ace::Herdr::TabMaterializationError,
            Ace::Herdr::ExecutorError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
