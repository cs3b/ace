# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_units"

module Ace
  module Lab
    module Auth
      class IssuerUnitsTest < Minitest::Test
        def test_socket_is_ordered_after_recovery_and_each_issuer_has_cleanup
          units = IssuerUnits.render(ruby: "/opt/ace/ruby/bin/ruby", gem_home: "/opt/ace/gems",
            gem_root: "/opt/ace/gems/gems/ace-lab-0.14.2")
          assert_equal %w[ace-lab-auth-recovery.service ace-lab-auth.socket ace-lab-auth@.service], units.keys.sort
          assert_includes units.fetch("ace-lab-auth.socket"), "Requires=ace-lab-auth-recovery.service"
          assert_includes units.fetch("ace-lab-auth.socket"), "After=ace-lab-auth-recovery.service"
          assert_includes units.fetch("ace-lab-auth.socket"), "Accept=yes"
          assert_includes units.fetch("ace-lab-auth.socket"), "RemoveOnStop=yes"
          refute_match(/^Service=/, units.fetch("ace-lab-auth.socket"))
          assert_includes units.fetch("ace-lab-auth@.service"), "ExecStopPost=/opt/ace/ruby/bin/ruby -I/opt/ace/gems/gems/ace-lab-0.14.2/lib /opt/ace/gems/gems/ace-lab-0.14.2/libexec/issuer-cleanup"
          assert_includes units.fetch("ace-lab-auth@.service"), "ACE_TOOLCHAIN=installed"
          assert_includes units.fetch("ace-lab-auth@.service"), "RUBYGEMS_GEMDEPS"
          assert_includes units.fetch("ace-lab-auth-recovery.service"), "LD_AUDIT"
          assert_includes units.fetch("ace-lab-auth-recovery.service"), "libexec/issuer-recover"
        end

        def test_rejects_paths_that_could_change_systemd_directives
          ["/opt/ace/with space", "/opt/ace/%i", "/opt/ace/../other", "relative"].each do |path|
            assert_raises(ArgumentError) do
              IssuerUnits.render(ruby: path, gem_home: "/opt/ace/gems", gem_root: "/opt/ace/gems/gems/ace-lab")
            end
          end
        end

        def test_selected_package_load_path_precedes_another_available_version
          Dir.mktmpdir do |dir|
            selected = File.join(dir, "selected")
            other = File.join(dir, "other")
            [selected, other].each { |path| FileUtils.mkdir_p(File.join(path, "ace", "lab")) }
            File.write(File.join(selected, "ace", "lab", "version_probe.rb"), "puts 'selected'\n")
            File.write(File.join(other, "ace", "lab", "version_probe.rb"), "puts 'other'\n")
            output, status = Open3.capture2({"RUBYLIB" => other}, RbConfig.ruby, "-I#{selected}", "-race/lab/version_probe", "-e", "")
            assert status.success?
            assert_equal "selected\n", output
          end
        end
      end
    end
  end
end
