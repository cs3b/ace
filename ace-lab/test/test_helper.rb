# frozen_string_literal: true

# Resolve monorepo dependencies from workspace sources, not installed gems
# (installed ace-support-* may lag the in-repo versions).
%w[ace-support-cli ace-support-config ace-support-core].each do |pkg|
  lib = File.expand_path("../../#{pkg}/lib", __dir__)
  $LOAD_PATH.unshift(lib) if Dir.exist?(lib)
end

require "ace/lab"
require "ace/support/cli"

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"
require "json"

module LabTestHelper
  # Shared passwd-entry stub for account_lookup seams (uid/gid/dir as
  # needed by the provisioners and verifiers; shell for the readiness
  # verifier's login-class check — nil means "unknown", which passes).
  FakeEntry = Struct.new(:name, :uid, :gid, :dir, :shell, keyword_init: true)

  # Builds a real gem and installs it --local into a real GEM_HOME under
  # dir (dir/runtime), offline, so gem-set tests parse REAL rubygems
  # output. The install strips the invoking process's bundler context
  # (nil unsets in spawn env) so the gem lands in the tmpdir runtime,
  # never the bundle. Returns the gem_home path; skips when the gem
  # toolchain is unavailable.
  def build_and_install_gem(dir, name, version)
    gemspec = File.join(dir, "#{name}.gemspec")
    File.write(gemspec, <<~SPEC)
      Gem::Specification.new do |s|
        s.name = #{name.inspect}
        s.version = #{version.inspect}
        s.summary = "lab test fixture"
        s.authors = ["ace-lab tests"]
        s.files = []
      end
    SPEC
    built = system("gem", "build", gemspec, chdir: dir, out: File::NULL, err: File::NULL)
    gem_file = File.join(dir, "#{name}-#{version}.gem")
    skip "gem build unavailable" unless built && File.file?(gem_file)

    gem_home = File.join(dir, "runtime")
    FileUtils.mkdir_p(gem_home)
    installed = system({"GEM_HOME" => gem_home, "GEM_PATH" => gem_home,
      "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_SETUP" => nil,
      "BUNDLE_BIN_PATH" => nil, "BUNDLE_GEMFILE" => nil,
      "BUNDLER_VERSION" => nil, "BUNDLE_BUNDLER_VERSION" => nil},
      "gem", "install", "--local", gem_file, "--no-document",
      out: File::NULL, err: File::NULL)
    skip "gem install unavailable" unless installed

    gem_home
  end

  # Rekey authorization principals to the verified local process identity so
  # services built through TopologyService.from_config authorize this process
  def authorized_for_local(config, projects = nil)
    projects ||= config["topology"]["projects"].map { |p| p["id"] }
    config["authorization"]["principals"] = {
      Ace::Lab::Molecules::CallerAuthorizer.local_identity.first => {"projects" => projects}
    }
    config
  end

  # Valid multi-project topology used as a base by query-level tests. Tests
  # deep-modify a dup of this hash; never mutate it in place.
  def topology_config
    {
      "schema_version" => 1,
      "authorization" => {
        "principals" => {
          "operator" => {"projects" => %w[atlas borealis]}
        }
      },
      "topology" => {
        "projects" => [
          {"id" => "atlas", "label" => "Atlas platform"},
          {"id" => "borealis"}
        ],
        "agents" => [
          {
            "id" => "atlas-planner", "project" => "atlas", "role" => "planner",
            "capabilities" => ["planning"],
            "binding" => {"kind" => "runtime", "state" => "active",
                          "instance_id" => "inst-planner-1", "attested_instance_id" => "inst-planner-1"}
          },
          {
            "id" => "atlas-coder", "project" => "atlas", "role" => "coder",
            "capabilities" => %w[coding planning],
            "binding" => {"kind" => "runtime", "state" => "active",
                          "instance_id" => "inst-coder-1", "attested_instance_id" => "inst-coder-9"}
          }
        ],
        "services" => [
          {
            "id" => "atlas-search", "project" => "atlas",
            "capabilities" => ["search"], "default_for" => ["search"],
            "endpoint" => {"kind" => "http", "url" => "https://search.example.internal:8443/q?token=secret#frag"},
            "binding" => {"kind" => "service", "state" => "active",
                          "instance_id" => "inst-search-1", "attested_instance_id" => "inst-search-1"}
          },
          {
            "id" => "atlas-index", "project" => "atlas",
            "capabilities" => ["search", "index"],
            "endpoint" => {"kind" => "http", "url" => "https://index.example.internal/q?token=secret2"},
            "binding" => {"kind" => "service", "state" => "active",
                          "instance_id" => "inst-index-1", "attested_instance_id" => "inst-index-1"}
          },
          {
            "id" => "borealis-search", "project" => "borealis",
            "capabilities" => ["search"],
            "endpoint" => {"kind" => "http", "url" => "https://b-search.example.internal"},
            "binding" => {"kind" => "service", "state" => "active",
                          "instance_id" => "inst-bsearch-1", "attested_instance_id" => "inst-bsearch-1"}
          }
        ]
      }
    }
  end
end

class Minitest::Test
  include LabTestHelper
end
