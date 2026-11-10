# frozen_string_literal: true

# Validate dependencies before mutating the disposable forge.
module LabVmForgejoFixture
  def self.validate_issues!(value)
    raise ArgumentError, "issues must be a nonempty list" unless value.is_a?(Array) && !value.empty?
    seen = []
    value.each do |issue|
      raise ArgumentError, "issue must be a mapping" unless issue.is_a?(Hash)
      key = issue["key"]
      raise ArgumentError, "invalid or duplicate issue key" unless key.is_a?(String) && key.match?(/\A[a-z][a-z0-9_-]*\z/) && !seen.include?(key)
      raise ArgumentError, "issue title and body are required" unless %w[title body].all? { |name| issue[name].is_a?(String) && !issue[name].strip.empty? }
      depends = issue.fetch("depends_on", [])
      raise ArgumentError, "invalid dependencies for #{key}" unless depends.is_a?(Array) && depends.uniq == depends && (depends - seen).empty?
      references = issue["body"].scan(/\{\{issue:([a-z][a-z0-9_-]*)\}\}/).flatten.uniq
      raise ArgumentError, "issue references do not match dependencies for #{key}" unless references.sort == depends.sort
      raise ArgumentError, "external URLs are not allowed in fixture issues" if issue["body"].match?(%r{https?://}i)
      seen << key
    end
    value
  end
end
