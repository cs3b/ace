# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  # ProjectLocations (task 8xs.t.pu0.a): canonical project locations
  # from the raw topology cascade at the lab root — read by explicit
  # path (no global cwd mutation), nil/blank path encodings returned as
  # nil (the project's own start reports the concrete error).
  class ProjectLocationsTest < Minitest::Test
    def write_config(lab_root, projects)
      FileUtils.mkdir_p(File.join(lab_root, ".ace/lab"))
      File.write(File.join(lab_root, ".ace/lab/config.yml"),
        {"topology" => {"projects" => projects}}.to_yaml)
    end

    def test_reads_locations_by_explicit_path_without_changing_the_cwd
      Dir.mktmpdir do |lab_root|
        Dir.mktmpdir do |elsewhere|
          write_config(lab_root, [{"id" => "atlas", "path" => "/srv/atlas"}])
          before = Dir.pwd

          Dir.chdir(elsewhere) do
            locations = Ace::Lab::Molecules::ProjectLocations.read(lab_root)
            assert_equal [{"id" => "atlas", "path" => "/srv/atlas"}], locations
          end
          assert_equal before, Dir.pwd
        end
      end
    end

    def test_nil_or_blank_path_encodings_return_nil_instead_of_raising
      Dir.mktmpdir do |lab_root|
        write_config(lab_root, [
          {"id" => "blank", "path" => ""},
          {"id" => "nil-path", "path" => nil},
          {"id" => "non-string", "path" => 42},
          {"id" => "fine", "path" => "/srv/fine"}
        ])

        locations = Ace::Lab::Molecules::ProjectLocations.read(lab_root)
        assert_equal [
          {"id" => "blank", "path" => nil},
          {"id" => "fine", "path" => "/srv/fine"},
          {"id" => "nil-path", "path" => nil},
          {"id" => "non-string", "path" => nil}
        ], locations
      end
    end

    def test_missing_or_malformed_configuration_is_a_classified_error
      Dir.mktmpdir do |lab_root|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          Ace::Lab::Molecules::ProjectLocations.read(lab_root)
        end
        assert_match(/no lab configuration at #{lab_root}\/.ace\/lab\/config.yml/, error.message)

        write_config(lab_root, "not-a-list")
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          Ace::Lab::Molecules::ProjectLocations.read(lab_root)
        end
        assert_match(/topology.projects must be a list/, error.message)
      end
    end
  end
end
