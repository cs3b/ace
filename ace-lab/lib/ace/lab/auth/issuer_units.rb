# frozen_string_literal: true

module Ace
  module Lab
    module Auth
      # Fixed systemd graph for the installed issuer. The installer must
      # separately verify root ownership and converge these exact contents.
      class IssuerUnits
        MARKER = "# Managed by ace-lab auth issuer\n"

        def self.render(ruby:, gem_home:, gem_root:)
          [ruby, gem_home, gem_root].each do |path|
            unless path.is_a?(String) && path.match?(%r{\A/[A-Za-z0-9_./-]+\z}) && File.expand_path(path) == path
              raise ArgumentError, "issuer runtime paths must be canonical absolute paths"
            end
          end
          unless gem_root.start_with?("#{gem_home}/gems/ace-lab-") && File.dirname(gem_root) == "#{gem_home}/gems"
            raise ArgumentError, "issuer package must belong to the selected gem home"
          end
          environment = <<~UNIT
            Environment=ACE_TOOLCHAIN=installed
            Environment=GEM_HOME=#{gem_home}
            Environment=GEM_PATH=#{gem_home}
            Environment=PATH=#{File.dirname(ruby)}:/usr/bin:/bin
            Environment=HOME=/var/empty
            UnsetEnvironment=RUBYOPT RUBYLIB RUBYGEMS_GEMDEPS GEM_SPEC_CACHE BUNDLE_GEMFILE BUNDLE_PATH BUNDLE_BIN_PATH LD_PRELOAD LD_LIBRARY_PATH LD_AUDIT
          UNIT
          units = {
            "ace-lab-auth-recovery.service" => <<~UNIT,
              [Unit]
              Description=Recover ACE issuer leases before accepting requests
              After=network-online.target
              Before=ace-lab-auth.socket

              [Service]
              Type=oneshot
              User=root
              UMask=0077
              RemainAfterExit=yes
              #{environment}ExecStart=#{ruby} -I#{gem_root}/lib #{gem_root}/libexec/issuer-recover
            UNIT
            "ace-lab-auth.socket" => <<~UNIT,
              [Unit]
              Requires=ace-lab-auth-recovery.service
              After=ace-lab-auth-recovery.service

              [Socket]
              ListenStream=/run/lab/ace-lab-auth.sock
              DirectoryMode=0755
              SocketMode=0666
              Accept=no
              RemoveOnStop=yes

              [Install]
              WantedBy=sockets.target
            UNIT
            "ace-lab-auth.service" => <<~UNIT
              [Unit]
              Requires=ace-lab-auth-recovery.service
              After=ace-lab-auth-recovery.service

              [Service]
              Type=simple
              User=root
              UMask=0077
              StandardInput=null
              StandardOutput=journal
              StandardError=journal
              TimeoutStopSec=60s
              #{environment}ExecStartPre=#{ruby} -I#{gem_root}/lib #{gem_root}/libexec/issuer-recover
              ExecStart=#{ruby} -I#{gem_root}/lib #{gem_root}/libexec/issuer-request
              ExecStopPost=#{ruby} -I#{gem_root}/lib #{gem_root}/libexec/issuer-cleanup
            UNIT
          }
          units.transform_values { |contents| MARKER + contents }
        end
      end
    end
  end
end
