# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require_relative "../molecules/native_source"
require_relative "../molecules/bounded_process"

module Ace
  module Herdr
    module Organisms
      # Explicit source build, outside the installed protected deployment.
      # No server contact, product execution, global tool selection or publication.
      class NativeSourceBuilder
        def initialize(selection: Molecules::NativeSource.new, runner: nil)
          @selection = selection
          @runner = runner || lambda do |argv, environment:, chdir:, timeout_s:|
            Molecules::BoundedProcess.call(argv, environment: environment, chdir: chdir,
              timeout_s: timeout_s, output_limit: 1_048_576)
          end
        end

        def build(source:, output:, target:)
          raise Molecules::NativeSource::Error, "native source builds must run as a nonroot build owner" if Process.euid.zero?
          selected = @selection.selection
          unless selected.fetch("targets").include?(target)
            raise Molecules::NativeSource::Error, "unsupported native source build target"
          end
          validate_native_host!(target)
          source = File.expand_path(source)
          output = File.expand_path(output)
          raise Molecules::NativeSource::Error, "native output must be new" if File.exist?(output) || File.symlink?(output)
          raise Molecules::NativeSource::Error, "native source directory is unavailable" unless File.directory?(source) && !File.symlink?(source)
          @environment = build_environment
          @git = executable("git")
          unless git(source, "status", "--porcelain", "--untracked-files=all").empty?
            raise Molecules::NativeSource::Error, "native source checkout must be clean"
          end
          git(source, "cat-file", "-e", "#{selected.fetch("baseline_commit")}^{commit}")
          tools = selected_tools
          tool_digests = tool_digests(tools)
          # Exclusive persistent output claim: failures never overwrite an older
          # build or return an incomplete artifact as successful.
          Dir.mkdir(output, 0o700)
          staging = File.join(output, ".source-build")
          Dir.mkdir(staging, 0o700)
          checkout = File.join(staging, "source")
          run([@git, "-c", "core.hooksPath=/dev/null", "clone", "--no-local", "--no-hardlinks", "--no-checkout", "--", source, checkout])
          git(checkout, "checkout", "--detach", selected.fetch("baseline_commit"))
          git(checkout, "am", "--committer-date-is-author-date", @selection.patch_path)
          unless git(checkout, "rev-parse", "HEAD").strip == selected.fetch("source_commit") &&
              git(checkout, "rev-parse", "HEAD^{tree}").strip == selected.fetch("source_tree")
            raise Molecules::NativeSource::Error, "native patched source revision mismatch"
          end
          verify_source_files(checkout)
          reject_ancestor_cargo_configuration(checkout)
          cargo_home = File.join(staging, "cargo-home")
          Dir.mkdir(cargo_home, 0o700)
          compile_environment = @environment.merge("CARGO_HOME" => cargo_home,
            "CARGO_TARGET_DIR" => File.join(staging, "target"), "RUSTC" => tools.fetch("rustc"),
            "RUSTUP_TOOLCHAIN" => selected.fetch("rust_version"), "ZIG" => tools.fetch("zig"),
            "CARGO_TARGET_#{target.upcase.tr("-", "_")}_LINKER" => tools.fetch("linker"))
          run([tools.fetch("cargo"), "build", "--release", "--locked", "--target", target],
            chdir: checkout, environment: compile_environment, timeout_s: 1800)
          verify_source_files(checkout)
          unless tool_digests(tools) == tool_digests
            raise Molecules::NativeSource::Error, "native build tools changed during compilation"
          end
          artifact = @selection.read_regular(File.join(staging, "target", target, "release", "herdr"),
            Molecules::NativeSource::MAX_ARTIFACT_BYTES)
          receipt = @selection.receipt(build: {"target" => target, "profile" => "release",
            "rust_version" => selected.fetch("rust_version"), "zig_version" => selected.fetch("zig_version"),
            "tools_sha256" => tool_digests},
            artifact: @selection.artifact_record(bytes: artifact, target: target))
          write_new(File.join(output, "herdr"), artifact, 0o755)
          FileUtils.remove_entry(staging)
          write_new(File.join(output, "provenance.json"), JSON.pretty_generate(receipt) + "\n", 0o644)
          @selection.verify_artifact(directory: output)
        rescue SystemCallError, IOError, Timeout::Error, Molecules::BoundedProcess::PostLaunchError => error
          raise Molecules::NativeSource::Error, "native source build failed: #{error.class}"
        end

        private

        def validate_native_host!(target)
          architecture = {"x86_64-unknown-linux-musl" => /\A(?:x86_64|amd64)\z/,
            "aarch64-unknown-linux-musl" => /\A(?:aarch64|arm64)\z/}.fetch(target)
          unless RbConfig::CONFIG.fetch("host_os").include?("linux") &&
              architecture.match?(RbConfig::CONFIG.fetch("host_cpu"))
            raise Molecules::NativeSource::Error, "native source builds require a matching Linux host; cross builds are unsupported"
          end
        end

        def build_environment
          selected = @selection.selection
          committer = selected.fetch("committer")
          environment = {"PATH" => ENV.fetch("PATH", "/usr/bin:/bin"), "HOME" => Dir.home,
            "GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_TERMINAL_PROMPT" => "0",
            "GIT_COMMITTER_NAME" => committer.fetch("name"), "GIT_COMMITTER_EMAIL" => committer.fetch("email"),
            "GIT_COMMITTER_DATE" => committer.fetch("date")}
          environment["RUSTUP_HOME"] = ENV["RUSTUP_HOME"] if ENV["RUSTUP_HOME"] && !ENV["RUSTUP_HOME"].empty?
          environment
        end

        def executable(name)
          path = @environment.fetch("PATH").split(File::PATH_SEPARATOR).map { |directory| File.join(directory, name) }
            .find { |candidate| File.file?(candidate) && File.executable?(candidate) }
          raise Molecules::NativeSource::Error, "required native build tool is missing: #{name}" unless path
          File.realpath(path)
        end

        def tool_digests(tools)
          tools.transform_values do |path|
            @selection.digest(@selection.read_regular(path, Molecules::NativeSource::MAX_ARTIFACT_BYTES))
          end
        end

        def reject_ancestor_cargo_configuration(checkout)
          current = File.dirname(checkout)
          loop do
            if %w[config config.toml].any? { |file| File.exist?(File.join(current, ".cargo", file)) || File.symlink?(File.join(current, ".cargo", file)) }
              raise Molecules::NativeSource::Error, "native build has undeclared ancestor Cargo configuration"
            end
            parent = File.dirname(current)
            break if parent == current
            current = parent
          end
        end

        def selected_tools
          rustup = executable("rustup")
          version = @selection.selection.fetch("rust_version")
          tools = %w[cargo rustc].to_h do |name|
            path = run([rustup, "which", "--toolchain", version, name]).strip
            unless path.start_with?("/") && File.file?(path) && File.executable?(path)
              raise Molecules::NativeSource::Error, "selected Rust tool is unavailable"
            end
            [name, File.realpath(path)]
          end
          tools["zig"] = executable("zig")
          tools["linker"] = executable("musl-gcc")
          unless run([tools.fetch("rustc"), "--version"]).start_with?("rustc #{version} ") &&
              run([tools.fetch("cargo"), "--version"]).start_with?("cargo #{version} ") &&
              run([tools.fetch("zig"), "version"]).strip == @selection.selection.fetch("zig_version")
            raise Molecules::NativeSource::Error, "selected native build tool versions mismatch"
          end
          tools
        end

        def git(checkout, *arguments)
          run([@git, "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-C", checkout, *arguments])
        end

        def verify_source_files(checkout)
          %w[Cargo.lock rust-toolchain.toml].zip(%w[cargo_lock_sha256 rust_toolchain_sha256]).each do |file, key|
            unless @selection.digest(@selection.read_regular(File.join(checkout, file), 1_048_576)) == @selection.selection.fetch(key)
              raise Molecules::NativeSource::Error, "native source lock/toolchain bytes mismatch"
            end
          end
          unless git(checkout, "status", "--porcelain", "--untracked-files=all").empty?
            raise Molecules::NativeSource::Error, "native source changed during build"
          end
        end

        def run(argv, chdir: nil, environment: @environment, timeout_s: 60)
          result = @runner.call(argv, environment: environment, chdir: chdir, timeout_s: timeout_s)
          unless result.status.success? && !result.oversized
            raise Molecules::NativeSource::Error, "native build command failed or exceeded output bound"
          end
          result.stdout
        end

        def write_new(path, bytes, mode)
          File.open(path, File::WRONLY | File::CREAT | File::EXCL, mode) do |file|
            file.write(bytes)
            file.flush
            file.fsync
            file.chmod(mode)
          end
        end
      end
    end
  end
end
