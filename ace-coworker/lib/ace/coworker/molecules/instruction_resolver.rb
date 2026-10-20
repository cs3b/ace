# frozen_string_literal: true

require "ace/support/cli/toolchain"

require "open3"

module Ace
  module Coworker
    module Molecules
      # Resolves the role instruction source: a file path relative to the
      # project root, or a protocol URI (wfi://, prompt:// tmpl://) resolved
      # through ace-nav.
      class InstructionResolver
        DEFAULT_NAV_RUNNER = ->(argv, cwd) { Open3.capture3(Ace::Support::Cli::Toolchain.child_environment, *argv, chdir: cwd) }

        # The ace-nav CLI itself is missing (ENOENT on exec): the resolver
        # never ran, so no verdict exists. Prepare treats this distinctly
        # from a resolver that RUNS and fails — the former is a
        # non-blocking unknown, the latter a never-ready gap.
        class NavUnavailableError < Error; end

        def initialize(project_root:, nav_runner: DEFAULT_NAV_RUNNER)
          @project_root = project_root
          @nav_runner = nav_runner
        end

        # @return [String] resolved absolute path of the instruction source
        # @raise [Error] when the source cannot be resolved
        def resolve!(instructions)
          value = instructions.to_s.strip
          if Atoms::ConfigSchema.protocol?(value)
            resolve_protocol(value)
          else
            resolve_file(value)
          end
        end

        private

        def resolve_protocol(uri)
          begin
            out, err, status = @nav_runner.call([nav_binary, "resolve", uri], @project_root)
          rescue Errno::ENOENT
            raise NavUnavailableError,
              "protocol instructions require the ace-nav CLI ('#{nav_binary}' not found)"
          end
          unless status.success?
            message = err.to_s.strip.empty? ? out.to_s.strip : err.to_s.strip
            raise Error, "cannot resolve instruction source '#{uri}': #{message}"
          end

          path = out.to_s.lines.map(&:strip).reject(&:empty?).first.to_s
          raise Error, "cannot resolve instruction source '#{uri}': ace-nav returned no path" if path.empty?
          raise Error, "instruction source '#{uri}' resolved to missing file '#{path}'" unless File.file?(path)

          path
        end

        def resolve_file(relative)
          candidate = File.expand_path(relative, @project_root)
          # Containment first: an outside-root path must never depend on
          # whether the outside file exists to pick its error message.
          unless candidate.start_with?("#{@project_root}/")
            raise Error, "instruction file '#{relative}' escapes the project root"
          end
          unless File.file?(candidate)
            raise Error, "instruction file '#{relative}' not found in this worktree"
          end

          candidate
        end

        # Same binary choice as start; a privileged (root) run never
        # executes the repository-controlled binstub — PATH only
        # (trust-posture parity with ace-lab Verify#nav_binary).
        def nav_binary
          return Ace::Support::Cli::Toolchain.executable("ace-nav") if Ace::Support::Cli::Toolchain.installed?

          binstub = File.join(@project_root, "bin", "ace-nav")
          use_binstub = !Process.uid.zero? && File.executable?(binstub)
          use_binstub ? binstub : "ace-nav"
        end
      end
    end
  end
end
