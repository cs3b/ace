# frozen_string_literal: true

require "json"
require "digest"
require "time"

module Ace
  module Herdr
    module Molecules
      # The accepted native producer source shipped by this exact package.
      # Provenance verifies bytes; deployment authorization stays with its owner.
      class NativeSource
        class Error < StandardError; end
        class ClosedObject < Hash
          def []=(key, value)
            raise FrozenError, "frozen native source object" if frozen?
            raise Error, "duplicate native provenance field" if key?(key)
            super
          end
        end

        ASSETS = File.expand_path("../native_source", __dir__).freeze
        SOURCE_KEYS = %w[schema repository baseline_commit source_commit source_tree patch_file patch_sha256
          cargo_lock_sha256 rust_toolchain_sha256 rust_version zig_version native_version protocol committer targets].freeze
        BUILD_KEYS = %w[target profile rust_version zig_version tools_sha256].freeze
        RECEIPT_KEYS = %w[schema selection_sha256 source build artifact].freeze
        TARGETS = %w[x86_64-unknown-linux-musl aarch64-unknown-linux-musl].freeze
        SHA256 = /\A[0-9a-f]{64}\z/
        GIT_SHA = /\A[0-9a-f]{40}\z/
        VERSION = /\A\d+\.\d+\.\d+\z/
        MAX_ARTIFACT_BYTES = 256 * 1024 * 1024

        attr_reader :selection, :selection_sha256, :selection_path, :patch_path

        def initialize(assets: ASSETS)
          @selection_path = File.join(File.expand_path(assets), "selection.json")
          bytes = read_regular(@selection_path, 65_536)
          @selection = parse(bytes)
          validate_selection!
          @patch_path = File.join(File.dirname(@selection_path), @selection.fetch("patch_file"))
          patch = read_regular(@patch_path, 1_048_576)
          raise Error, "native source patch digest mismatch" unless digest(patch) == @selection.fetch("patch_sha256")
          @selection_sha256 = digest(bytes).freeze
          freeze_data(@selection)
        end

        def description
          {"selection_path" => @selection_path, "selection_sha256" => @selection_sha256, "source" => @selection}
        end

        def verify_artifact(directory:)
          directory = File.expand_path(directory)
          info = File.lstat(directory)
          raise Error, "native artifact directory must be regular" unless info.directory? && !info.symlink?
          raise Error, "unexpected native artifact files" unless Dir.children(directory).sort == %w[herdr provenance.json]
          receipt_bytes = read_regular(File.join(directory, "provenance.json"), 65_536)
          receipt = parse(receipt_bytes)
          validate_receipt!(receipt)
          artifact = read_regular(File.join(directory, "herdr"), MAX_ARTIFACT_BYTES)
          validate_elf!(artifact, receipt.fetch("build").fetch("target"))
          expected = receipt.fetch("artifact")
          unless artifact.bytesize == expected.fetch("size") && digest(artifact) == expected.fetch("sha256")
            raise Error, "native artifact bytes do not match provenance"
          end
          freeze_data(receipt)
          {"provenance_sha256" => digest(receipt_bytes), "selection_sha256" => @selection_sha256,
           "source" => @selection, "build" => receipt.fetch("build"), "artifact" => expected}
        rescue JSON::ParserError, SystemCallError, IOError => error
          raise Error, "native artifact unavailable: #{error.class}"
        end

        def artifact_record(bytes:, target:)
          validate_elf!(bytes, target)
          {"file" => "herdr", "size" => bytes.bytesize, "sha256" => digest(bytes)}
        end

        def receipt(build:, artifact:)
          data = {"schema" => "ace.herdr.native-build/v1", "selection_sha256" => @selection_sha256,
                  "source" => @selection, "build" => build, "artifact" => artifact}
          validate_receipt!(data)
          data
        end

        def read_regular(path, limit)
          before = File.lstat(path)
          raise Error, "native source input must be a regular file" unless before.file? && !before.symlink?
          File.open(path, File::RDONLY | File::NOFOLLOW) do |input|
            opened = input.stat
            unless opened.file? && [opened.dev, opened.ino] == [before.dev, before.ino]
              raise Error, "native source input changed while opening"
            end
            bytes = input.read(limit + 1)
            raise Error, "native source input exceeds bound" if bytes.bytesize > limit
            after = input.stat
            unless [opened.size, opened.mtime, opened.ctime] == [after.size, after.mtime, after.ctime]
              raise Error, "native source input changed while reading"
            end
            bytes
          end
        rescue SystemCallError, IOError => error
          raise Error, "native source input unavailable: #{error.class}"
        end

        def digest(bytes)
          Digest::SHA256.hexdigest(bytes)
        end

        private

        def parse(bytes)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          raise Error, "invalid native source UTF-8" unless text.valid_encoding?
          JSON.parse(text, object_class: ClosedObject, create_additions: false,
            max_nesting: 16, allow_comments: false, allow_duplicate_key: false)
        rescue JSON::ParserError, EncodingError
          raise Error, "invalid native source JSON"
        end

        def fields!(data, expected)
          unless data.is_a?(Hash) && data.keys.sort == expected.sort
            raise Error, "invalid native source fields"
          end
        end

        def string!(value, pattern)
          raise Error, "invalid native source value" unless value.is_a?(String) && pattern.match?(value)
        end

        def validate_selection!(selection = @selection)
          fields!(selection, SOURCE_KEYS)
          raise Error, "unsupported native source schema" unless selection["schema"] == "ace.herdr.native-source/v1"
          unless selection["repository"] == "https://github.com/herdrdev/herdr.git" && selection["patch_file"] == "guarded-prompt.patch"
            raise Error, "unsupported native source selection"
          end
          %w[baseline_commit source_commit source_tree].each { |key| string!(selection[key], GIT_SHA) }
          %w[patch_sha256 cargo_lock_sha256 rust_toolchain_sha256].each { |key| string!(selection[key], SHA256) }
          %w[rust_version zig_version native_version].each { |key| string!(selection[key], VERSION) }
          unless selection["protocol"].is_a?(Integer) && selection["protocol"].positive? && selection["targets"] == TARGETS
            raise Error, "unsupported native target/protocol"
          end
          committer = selection["committer"]
          fields!(committer, %w[name email date])
          %w[name email].each { |key| string!(committer[key], /\A[^\x00-\x1f\x7f]{1,255}\z/) }
          string!(committer["date"], /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d\z/)
          Time.iso8601(committer["date"])
        rescue ArgumentError
          raise Error, "invalid native source committer date"
        end

        def validate_elf!(bytes, target)
          raise Error, "unsupported native artifact target" unless TARGETS.include?(target)
          machine = target.start_with?("x86_64-") ? 62 : 183
          unless bytes.bytesize >= 64 && bytes.byteslice(0, 7) == "\x7fELF\x02\x01\x01".b &&
              [2, 3].include?(bytes.byteslice(16, 2).unpack1("v")) && bytes.byteslice(18, 2).unpack1("v") == machine
            raise Error, "native artifact is not the selected Linux executable architecture"
          end
        end

        def validate_receipt!(data)
          fields!(data, RECEIPT_KEYS)
          validate_selection!(data["source"])
          unless data["schema"] == "ace.herdr.native-build/v1" && data["selection_sha256"] == @selection_sha256 && data["source"] == @selection
            raise Error, "native build source selection mismatch"
          end
          build = data["build"]
          fields!(build, BUILD_KEYS)
          unless @selection["targets"].include?(build["target"]) && build["profile"] == "release" &&
              build["rust_version"] == @selection["rust_version"] && build["zig_version"] == @selection["zig_version"]
            raise Error, "native build toolchain/target mismatch"
          end
          fields!(build["tools_sha256"], %w[cargo rustc zig linker])
          build["tools_sha256"].each_value { |value| string!(value, SHA256) }
          artifact = data["artifact"]
          fields!(artifact, %w[file size sha256])
          unless artifact["file"] == "herdr" && artifact["size"].is_a?(Integer) && artifact["size"].positive? && artifact["size"] <= MAX_ARTIFACT_BYTES
            raise Error, "invalid native build artifact"
          end
          string!(artifact["sha256"], SHA256)
        end

        def freeze_data(value)
          value.each { |key, item| freeze_data(key); freeze_data(item) } if value.is_a?(Hash)
          value.each { |item| freeze_data(item) } if value.is_a?(Array)
          value.freeze
        end
      end
    end
  end
end
