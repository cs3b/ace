# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "rubygems/package"
require "zlib"
require "tmpdir"

class GemPackagingTest < AceOverseerTestCase
  PAYLOAD_FILES = [
    "handbook/workflow-instructions/overseer.wf.md",
    ".ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml"
  ].freeze

  def test_built_gem_ships_workflow_and_wfi_source_payload
    built_files = build_gem_and_list_contents

    PAYLOAD_FILES.each do |path|
      assert_includes built_files, path,
        "built gem must ship #{path} so wfi://overseer resolves for gem consumers"
    end
  end

  def test_gemspec_file_globs_include_payload_files
    spec = load_gemspec

    PAYLOAD_FILES.each do |path|
      assert_includes spec.files, path,
        "gemspec file globs must include #{path}"
    end
  end

  private

  def package_root
    File.expand_path("../../..", __dir__)
  end

  def load_gemspec
    Dir.chdir(package_root) do
      Gem::Specification.load("ace-overseer.gemspec")
    end
  end

  def build_gem_and_list_contents
    Dir.mktmpdir("ace-overseer-packaging") do |dir|
      artifact = Dir.chdir(package_root) do
        spec = Gem::Specification.load("ace-overseer.gemspec")
        Gem::Package.build(spec, true)
      end
      gem_path = File.join(dir, artifact)
      FileUtils.mv(File.join(package_root, artifact), gem_path)
      gem_data_files(gem_path)
    end
  end

  def gem_data_files(gem_path)
    files = []
    File.open(gem_path, "rb") do |io|
      Gem::Package::TarReader.new(io) do |tar|
        tar.seek("data.tar.gz") do |entry|
          Zlib::GzipReader.wrap(entry) do |gz|
            Gem::Package::TarReader.new(gz) do |data_tar|
              data_tar.each_entry { |e| files << e.full_name }
            end
          end
        end
      end
    end
    files
  end
end
