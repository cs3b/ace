# frozen_string_literal: true

require_relative "../errors"
require "yaml"
require "date"
require "fileutils"

module Ace
  module Lab
    module Molecules
      # Installs the manifest's HITL adapter declarations as the runtime
      # route configuration the ace-hitl cascade actually reads
      # (PR #393 final audit, FINAL-LAB2): `hitl.adapters.routes` in the
      # project's `.ace/hitl/config.yml`. The trusted install manifest
      # stays the single declaration owner — this molecule only
      # PROJECTS that declaration into the existing HITL configuration
      # contract; ace-hitl remains its owner and reader. A `kind: hitl`
      # adapter becomes one route entry named after the adapter id
      # (config entries are carried verbatim; a `route` key renames the
      # route), so the runtime route loader finds a non-empty, valid
      # route set instead of failing with NoRoutesError.
      #
      # Validation mirrors Ace::Hitl::Molecules::HitlRouteLoader
      # (non-empty list of mappings, non-empty `adapter`, single-segment
      # route names — delivery retention persists route names as literal
      # dot-keys — and no duplicate names); the committed suite
      # cross-checks the written document against the real loader.
      #
      # Convergence rules (review 8xir47, findings 5-6): routes are
      # converged BY ROUTE NAME. On re-install the manifest-declared
      # keys win over the existing same-name route, but operator
      # extensions SURVIVE: extra keys the operator added to a
      # same-name route (e.g. `pane: p5` on `console`) are kept and
      # merged around the manifest keys, and operator-added routes
      # survive untouched. Verify applies the same rule — a route is
      # converged when a same-name entry carries every
      # manifest-declared key/value; operator extra keys never fail
      # verification. An unchanged route list is never rewritten, so
      # an idempotent no-op install leaves the file (including any
      # operator comments) byte-identical. When a write DOES happen
      # it goes through a YAML round-trip (atomic: exclusive temp
      # file + rename, the ProjectRegistry pattern), which normalizes
      # formatting and DROPS comments in the file — comments are not
      # preserved across a converging write.
      class HitlRoutes
        RELATIVE_CONFIG_PATH = %w[.ace hitl config.yml].freeze
        ROUTE_NAME_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/i.freeze

        # @param adapters [Array<Hash>] normalized manifest adapters
        # @return [Array<Hash>] route entries for the `kind: hitl`
        #   declarations (string keys, `adapter` => adapter id merged
        #   with the declaration's config)
        def self.expected_routes(adapters)
          adapters.filter_map do |adapter|
            next unless adapter["kind"] == "hitl"

            {"adapter" => adapter["id"]}.merge(adapter["config"] || {})
          end
        end

        # @param route [Hash] route entry
        # @return [String] the entry's route name (defaults to the
        #   adapter name, exactly like the runtime loader)
        def self.route_name(route)
          name = route["route"].to_s.strip
          name.empty? ? route["adapter"].to_s : name
        end

        # The runtime loader's validation contract; nil when the route
        # list is loadable, otherwise the concrete reason.
        # @param routes [Object] the routes value from the config
        # @return [String, nil]
        def self.validation_reason(routes)
          unless routes.is_a?(Array) && !routes.empty?
            return "hitl.adapters.routes must be a non-empty list"
          end

          names = []
          routes.each do |route|
            return "route entry must be a mapping" unless route.is_a?(Hash)

            if route["adapter"].to_s.strip.empty?
              return "route entry missing required 'adapter'"
            end

            name = route_name(route)
            unless name.match?(ROUTE_NAME_PATTERN)
              return "route name '#{name}' is invalid (must match #{ROUTE_NAME_PATTERN.source})"
            end
            names << name
          end
          duplicates = names.tally.select { |_, count| count > 1 }.keys
          return "duplicate route name(s) #{duplicates.sort.join(', ')}" unless duplicates.empty?

          nil
        end

        # Readiness probe (verify): the project's installed HITL
        # configuration must exist, parse, satisfy the loader contract,
        # and contain the expected route BY NAME with every
        # manifest-declared key matching (operator extra keys on the
        # same-name route are allowed — an extended route is converged,
        # not drift). nil when ready, otherwise the concrete reason.
        # @param root [String] project root
        # @param expected [Hash] expected route entry
        # @return [String, nil]
        def self.config_reason(root:, expected:)
          path = File.join(root, *RELATIVE_CONFIG_PATH)
          unless File.file?(path)
            return "no HITL adapter routes are configured: '#{path}' is missing " \
              "(the runtime cannot deliver HITL; rerun ace-lab install)"
          end

          begin
            document = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::Exception
            return "'#{path}' could not be parsed as YAML"
          end
          return "'#{path}' must contain a YAML mapping" unless document.is_a?(Hash)

          routes = document.dig("hitl", "adapters", "routes")
          reason = validation_reason(routes)
          return "hitl.adapters.routes in '#{path}' is invalid: #{reason}" if reason

          name = route_name(expected)
          route = routes.find { |candidate| route_name(candidate) == name }
          unless route && expected.all? { |key, value| route[key] == value }
            return "route '#{name}' is not configured in '#{path}' with the declared " \
              "settings (rerun ace-lab install)"
          end

          nil
        end

        # @param root [String] project root
        # @param adapters [Array<Hash>] normalized manifest adapters
        # @param dry_run [Boolean]
        # @return [Hash] {location:, status:, message:} — status is
        #   created / exists / would_create / skipped / failed
        def install(root:, adapters:, dry_run: false)
          path = File.join(root, *RELATIVE_CONFIG_PATH)
          base = {"location" => path}
          expected = self.class.expected_routes(adapters)
          return base.merge("status" => "skipped", "message" => nil) if expected.empty?

          document, reason = load_document(path)
          return base.merge("status" => "failed", "message" => reason) if reason

          routes = document.dig("hitl", "adapters", "routes")
          routes = routes.is_a?(Array) ? routes : []
          merged = merge_routes(routes, expected)
          if (invalid = self.class.validation_reason(merged))
            return base.merge("status" => "failed",
              "message" => "resulting hitl.adapters.routes is invalid: #{invalid}")
          end
          return base.merge("status" => "exists", "message" => nil) if routes == merged
          return base.merge("status" => "would_create", "message" => nil) if dry_run

          document["hitl"] ||= {}
          document["hitl"]["adapters"] ||= {}
          document["hitl"]["adapters"]["routes"] = merged
          begin
            dir = File.dirname(path)
            FileUtils.mkdir_p(dir)
            # Atomic write (review 8xir47, finding 5, the ProjectRegistry
            # pattern): a crash mid-write must never truncate the runtime
            # route configuration. The temp file is created EXCLUSIVELY
            # (O_CREAT|O_EXCL) under an unguessable name so a planted
            # symlink can never redirect the write.
            tmp = write_exclusive(dir, YAML.dump(document))
            File.rename(tmp, path)
          rescue SystemCallError, IOError => e
            File.delete(tmp) if defined?(tmp) && tmp && File.exist?(tmp)
            return base.merge("status" => "failed",
              "message" => "writing '#{path}' failed: #{e.class}: #{e.message}")
          end
          base.merge("status" => "created", "message" => nil)
        end

        private

        # An existing configuration document is preserved (root_dir and
        # operator-owned settings survive); only the lab-declared routes
        # are converged. Unparseable or foreign-shaped content is
        # refused instead of overwritten.
        def load_document(path)
          return [{}, nil] unless File.exist?(path)

          begin
            document = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::Exception
            return [nil, "'#{path}' exists but could not be parsed as YAML; resolve it " \
              "manually and rerun ace-lab install"]
          end
          return [nil, "'#{path}' must contain a YAML mapping"] unless document.is_a?(Hash)

          [document, nil]
        end

        # Converge the expected routes into the existing list by route
        # name: a declared route's keys are MERGED into the entry
        # carrying the same name (manifest-declared keys win, operator
        # extra keys like `pane: p5` survive), a route with no
        # same-name counterpart is appended; operator-added routes and
        # their order are untouched.
        def merge_routes(routes, expected)
          merged = routes.map(&:dup)
          expected.each do |route|
            name = self.class.route_name(route)
            index = merged.index { |existing| self.class.route_name(existing) == name }
            if index
              merged[index] = merged[index].merge(route)
            else
              merged << route.dup
            end
          end
          merged
        end

        # NOTE: merge_routes uses a shallow Hash#merge — manifest keys
        # win per-key, but a nested manifest value would replace an
        # operator's nested value wholesale. Current route shapes are
        # flat (adapter/pane/runtime/route), so shallow is correct.

        # Create the temp file exclusively (never following a symlink),
        # write the payload, close, and return the path — the
        # ProjectRegistry atomic-write discipline. Raises
        # SystemCallError/IOError on failure so the caller classifies.
        def write_exclusive(dir, payload)
          require "securerandom"
          100.times do
            candidate = File.join(dir, ".config.yml.tmp.#{Process.pid}.#{SecureRandom.hex(8)}")
            next if File.exist?(candidate) # includes symlinks (lstat)

            begin
              file = File.open(candidate, File::RDWR | File::CREAT | File::EXCL, 0o600)
            rescue Errno::EEXIST
              next
            end
            begin
              file.write(payload)
            rescue StandardError
              # A failed write must not leak the exclusive temp file:
              # close, remove, and re-raise verbatim so the caller
              # still classifies (encoding failures included).
              file.close unless file.closed?
              begin
                File.delete(candidate)
              rescue SystemCallError
                nil
              end
              raise
            ensure
              file.close unless file.closed?
            end
            return candidate
          end
          raise SystemCallError.new("could not create an exclusive temporary file in '#{dir}'", 0)
        end
      end
    end
  end
end
