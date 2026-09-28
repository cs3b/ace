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
          "operator" => { "projects" => %w[atlas borealis] }
        }
      },
      "topology" => {
        "projects" => [
          { "id" => "atlas", "label" => "Atlas platform" },
          { "id" => "borealis" }
        ],
        "agents" => [
          {
            "id" => "atlas-planner", "project" => "atlas", "role" => "planner",
            "capabilities" => ["planning"],
            "binding" => { "kind" => "runtime", "state" => "active",
                           "instance_id" => "inst-planner-1", "attested_instance_id" => "inst-planner-1" }
          },
          {
            "id" => "atlas-coder", "project" => "atlas", "role" => "coder",
            "capabilities" => %w[coding planning],
            "binding" => { "kind" => "runtime", "state" => "active",
                           "instance_id" => "inst-coder-1", "attested_instance_id" => "inst-coder-9" }
          }
        ],
        "services" => [
          {
            "id" => "atlas-search", "project" => "atlas",
            "capabilities" => ["search"], "default_for" => ["search"],
            "endpoint" => { "kind" => "http", "url" => "https://search.example.internal:8443/q?token=secret#frag" },
            "binding" => { "kind" => "service", "state" => "active",
                           "instance_id" => "inst-search-1", "attested_instance_id" => "inst-search-1" }
          },
          {
            "id" => "atlas-index", "project" => "atlas",
            "capabilities" => ["search", "index"],
            "endpoint" => { "kind" => "http", "url" => "https://index.example.internal/q?token=secret2" },
            "binding" => { "kind" => "service", "state" => "active",
                           "instance_id" => "inst-index-1", "attested_instance_id" => "inst-index-1" }
          },
          {
            "id" => "borealis-search", "project" => "borealis",
            "capabilities" => ["search"],
            "endpoint" => { "kind" => "http", "url" => "https://b-search.example.internal" },
            "binding" => { "kind" => "service", "state" => "active",
                           "instance_id" => "inst-bsearch-1", "attested_instance_id" => "inst-bsearch-1" }
          }
        ]
      }
    }
  end
end

class Minitest::Test
  include LabTestHelper
end
