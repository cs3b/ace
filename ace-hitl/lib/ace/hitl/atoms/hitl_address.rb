# frozen_string_literal: true

module Ace
  module Hitl
    module Atoms
      # Pure recipient/reply address validation and formatting. No IO.
      #
      # Two forms (program contract 8xg.t.sbz.1.1):
      # - folder: machine + events folder + case id (id stamped at create)
      # - panel:  machine + panel
      # Display strings align with the hermes <machine>/<name>/<id> shape.
      class HitlAddress
        TOKEN_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/i.freeze

        class InvalidAddress < StandardError; end

        # @param hash [Hash] symbol or string keys: machine, folder/panel, id
        # @return [Hash] validated string-keyed address
        # @raise [InvalidAddress] with an actionable message
        def self.validate!(hash)
          raise InvalidAddress, "address must be a mapping" unless hash.is_a?(Hash)

          machine = hash[:machine] || hash["machine"]
          folder = hash[:folder] || hash["folder"]
          panel = hash[:panel] || hash["panel"]
          id = hash[:id] || hash["id"]

          unless machine.to_s.match?(TOKEN_PATTERN)
            raise InvalidAddress, "address machine '#{machine}' is not a valid token"
          end

          if folder.to_s.strip.empty? && panel.to_s.strip.empty?
            raise InvalidAddress, "address needs exactly one of folder or panel"
          end
          unless folder.to_s.strip.empty? || panel.to_s.strip.empty?
            raise InvalidAddress, "address cannot have both folder and panel"
          end

          address = {"machine" => machine.to_s}
          unless folder.to_s.strip.empty?
            folder = folder.to_s
            if folder.split(File::SEPARATOR).include?("..")
              raise InvalidAddress, "address folder '#{folder}' must not traverse outside its root"
            end

            address["folder"] = folder
            if id && !id.to_s.empty?
              address["id"] = id.to_s
            end
          else
            unless panel.to_s.match?(TOKEN_PATTERN)
              raise InvalidAddress, "address panel '#{panel}' is not a valid token"
            end

            address["panel"] = panel.to_s
          end

          address
        end

        # @return [Boolean] true when the address carries an events folder
        def self.folder_form?(address)
          address.is_a?(Hash) && !address["folder"].to_s.empty?
        end

        # @return [Boolean] true when the address carries a panel
        def self.panel_form?(address)
          address.is_a?(Hash) && !address["panel"].to_s.empty?
        end

        # @return [String] canonical display form
        def self.to_s(address)
          return "" unless address.is_a?(Hash)

          if folder_form?(address)
            parts = [address["machine"], address["folder"]]
            parts << address["id"] unless address["id"].to_s.empty?
            parts.join("/")
          elsif panel_form?(address)
            "#{address["machine"]}/panel/#{address["panel"]}"
          else
            address["machine"].to_s
          end
        end
      end
    end
  end
end
