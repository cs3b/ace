# frozen_string_literal: true

require "digest"

# Verification for the immutable, local Herdr build input. This is an
# artifact cache only; the manifest and provenance remain the authorities.
module LabVmNativeCache
  NAMES = {"herdr" => ["artifact_sha256", 256 * 1024 * 1024],
           "provenance.json" => ["provenance_sha256", 65_536]}.freeze

  def self.verify!(directory, herdr_manifest)
    stat = File.lstat(directory)
    raise ArgumentError, "unsafe native artifact directory" unless stat.directory? && !stat.symlink? &&
      stat.uid == Process.uid && (stat.mode & 0o077).zero?
    raise ArgumentError, "unexpected native artifact files" unless Dir.children(directory).sort == NAMES.keys.sort
    NAMES.each do |name, (field, limit)|
      expected = herdr_manifest.fetch(field)
      raise ArgumentError, "invalid native artifact digest" unless expected.is_a?(String) && expected.match?(/\A[0-9a-f]{64}\z/)
      path = File.join(directory, name)
      before = File.lstat(path)
      raise ArgumentError, "unsafe native artifact" unless before.file? && !before.symlink? && before.size.positive? && before.size <= limit
      digest = Digest::SHA256.new
      File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
        current = file.stat
        raise ArgumentError, "native artifact changed during open" unless [current.dev, current.ino] == [before.dev, before.ino]
        while (chunk = file.read(1024 * 1024))
          digest.update(chunk)
        end
        after = file.stat
        raise ArgumentError, "native artifact changed during read" unless [current.size, current.mtime, current.ctime] == [after.size, after.mtime, after.ctime]
      end
      raise ArgumentError, "native artifact digest mismatch: #{name}" unless digest.hexdigest == expected
    end
    true
  rescue SystemCallError => e
    raise ArgumentError, "native artifact unavailable: #{e.class}"
  end
end
