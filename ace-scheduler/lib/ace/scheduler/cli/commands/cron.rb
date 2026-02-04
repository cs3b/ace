# frozen_string_literal: true

require "dry/cli"

module Ace
  module Scheduler
    module CLI
      module Commands
        class Cron < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Manage scheduler crontab entries"

          argument :action, required: true, values: %w[install uninstall status]
          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(action:, **options)
            config = Molecules::ConfigLoader.new.load(options[:config])
            installer = Molecules::CronInstaller.new(config)

            case action
            when "install"
              installer.install
              puts "Cron jobs installed" unless options[:quiet]
            when "uninstall"
              installer.uninstall
              puts "Cron jobs removed" unless options[:quiet]
            when "status"
              entries = installer.status
              puts entries.join("\n")
            end
          end
        end
      end
    end
  end
end
