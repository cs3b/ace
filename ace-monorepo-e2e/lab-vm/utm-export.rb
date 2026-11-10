# frozen_string_literal: true

module LabVm
  # UTM copies its own registered package into a private host directory.
  # Validate the copy before using it as a base fingerprint or deletion proof.
  def self.export_fingerprint(package, record)
    raise "export is not a regular VM package" unless File.directory?(package) && !File.symlink?(package)
    config_path = File.join(package, "config.plist")
    raise "export configuration is not a regular file" unless File.file?(config_path) && !File.symlink?(config_path)
    config = JSON.parse(checked_command("/usr/bin/plutil", "-convert", "json", "-o", "-", config_path))
    identity = config.fetch("Information")
    unless identity.fetch("UUID").casecmp?(record.fetch("uuid")) && identity.fetch("Name") == record.fetch("name")
      raise "UTM export identity differs from the registered VM"
    end
    unless config.fetch("Backend") == "QEMU" && config.dig("System", "Architecture") == "aarch64"
      raise "UTM export is not the pinned ARM64 QEMU fixture"
    end

    data = File.join(package, "Data")
    raise "export data is not a regular directory" unless File.directory?(data) && !File.symlink?(data)
    images = config.fetch("Drive").map do |drive|
      name = drive.fetch("ImageName")
      unless drive.fetch("ImageType") == "Disk" && name.match?(/\A[A-Za-z0-9_-]+\.qcow2\z/)
        raise "UTM export contains a drive outside the fixture format"
      end
      path = File.join(data, name)
      raise "UTM export drive is missing or unsafe" unless File.file?(path) && !File.symlink?(path)
      info = JSON.parse(checked_command("qemu-img", "info", "-f", "qcow2", "--output=json", path))
      if info.key?("backing-filename") || info.dig("format-specific", "data", "data-file")
        raise "UTM export drive depends on an external file"
      end
      name
    end
    raise "UTM export has an incomplete drive set" unless images.size == 2 && images.uniq.size == images.size
    package_fingerprint(package)
  rescue KeyError, JSON::ParserError, TypeError, NoMethodError
    raise "UTM export configuration or disk metadata is invalid"
  end

  def self.with_utm_export(role, record)
    uuid = record.fetch("uuid")
    assert_stopped_registration!(role, record)
    Dir.mktmpdir("utm-export-", evidence_dir) do |staging|
      package = File.join(staging, "#{uuid}.utm")
      script = <<~APPLESCRIPT
        on run argv
          set vmId to item 1 of argv
          set outputPath to POSIX file (item 2 of argv)
          tell application "UTM" to export virtual machine id vmId to outputPath
        end run
      APPLESCRIPT
      out, err, result = capture_with_timeout(600, "osascript", "-e", script, "--", uuid, package)
      raise "UTM export failed: #{err.strip} #{out.strip}" unless result.success?
      digest = export_fingerprint(package, record)
      assert_stopped_registration!(role, record)
      yield package, digest
    end
  end

  def self.assert_stopped_registration!(role, record)
    actual = registered_vm(role, record, parse_inventory(utm_call("list")))
    raise "#{role} VM is not registered and stopped" unless actual && actual["status"] == "stopped"
  end
end
