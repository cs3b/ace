# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Group parsed numstat entries by package/layer/root buckets.
      module FileGrouper
        DEFAULT_LAYERS = %w[lib test handbook].freeze

        class << self
          def group(entries, layers: DEFAULT_LAYERS, dotfile_groups: [])
            normalized_layers = Array(layers).map(&:to_s)
            groups = {}

            Array(entries).each do |entry|
              group_key, layer_key, display_path = classify(entry, normalized_layers)
              groups[group_key] ||= initialize_group(group_key)
              group = groups[group_key]
              group[:layers][layer_key] ||= initialize_layer(layer_key)

              normalized_entry = entry.merge(display_path: display_path)
              add_to_group(group, group[:layers][layer_key], normalized_entry)
            end

            ordered_groups = sort_groups(groups.values, dotfile_groups)
            ordered_groups.each { |group| group[:layers] = sort_layers(group[:layers], normalized_layers) }

            {
              groups: ordered_groups,
              total: {
                additions: ordered_groups.sum { |g| g[:additions] },
                deletions: ordered_groups.sum { |g| g[:deletions] },
                files: ordered_groups.sum { |g| g[:file_count] }
              },
              files: ordered_groups.flat_map { |g| g[:layers].flat_map { |l| l[:files].map { |f| f[:path] } } }
            }
          end

          private

          def initialize_group(name)
            {
              name: name,
              additions: 0,
              deletions: 0,
              file_count: 0,
              layers: {}
            }
          end

          def initialize_layer(name)
            {
              name: name,
              additions: 0,
              deletions: 0,
              file_count: 0,
              files: []
            }
          end

          def add_to_group(group, layer, entry)
            adds = entry[:additions] || 0
            dels = entry[:deletions] || 0

            group[:additions] += adds
            group[:deletions] += dels
            group[:file_count] += 1

            layer[:additions] += adds
            layer[:deletions] += dels
            layer[:file_count] += 1
            layer[:files] << entry
          end

          def classify(entry, layers)
            path = entry[:path].to_s
            segments = path.split("/")
            top = segments.first

            if top&.start_with?("ace-") || (top&.start_with?(".") && segments.length > 1)
              group_name = "#{top}/"
              layer = resolve_layer(segments[1], layers)
              prefix = (layer == "other/" || layer == "root/") ? top : [top, layer.delete_suffix("/")].join("/")
              [group_name, layer, relativize_entry(entry, prefix)]
            else
              ["./", "root/", entry[:display_path]]
            end
          end

          def relativize_entry(entry, prefix)
            return entry[:display_path] if prefix.nil? || prefix.empty?

            if entry[:rename_from] && entry[:rename_to]
              from = trim_prefix(entry[:rename_from], prefix)
              to = trim_prefix(entry[:rename_to], prefix)
              return "#{from} -> #{to}"
            end

            trim_prefix(entry[:display_path], prefix)
          end

          def trim_prefix(path, prefix)
            return path if path.nil? || prefix.nil? || prefix.empty?

            path.start_with?("#{prefix}/") ? path.delete_prefix("#{prefix}/") : path
          end

          def resolve_layer(segment, layers)
            return "root/" if segment.nil? || segment.empty?

            layers.include?(segment) ? "#{segment}/" : "other/"
          end

          def sort_groups(groups, dotfile_groups)
            configured_dot = Array(dotfile_groups).map { |name| name.to_s.end_with?("/") ? name.to_s : "#{name}/" }
            dot_index = configured_dot.each_with_index.to_h

            groups.sort_by do |group|
              name = group[:name]
              if name == "./"
                [2, 0, name]
              elsif name.start_with?("ace-")
                [0, 0, name]
              elsif name.start_with?(".")
                [1, dot_index.fetch(name, 9_999), name]
              else
                [1, 9_999, name]
              end
            end
          end

          def sort_layers(layers_hash, configured_layers)
            layer_order = configured_layers.each_with_index.map { |layer, idx| ["#{layer}/", idx] }.to_h
            ordered = layers_hash.values.sort_by do |layer|
              key = layer[:name]
              if key == "root/"
                [0, 0, key]
              elsif key == "other/"
                [2, 0, key]
              else
                [1, layer_order.fetch(key, 9_999), key]
              end
            end

            ordered.each { |layer| layer[:files].sort_by! { |file| file[:display_path] } }
            ordered
          end
        end
      end
    end
  end
end
