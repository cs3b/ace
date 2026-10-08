# frozen_string_literal: true
require "delegate"

module Ace
  module Assign
    # Only observed namespace/ownership/kernel facts are controlled. Source
    # lifecycle owners still use real temporary files, flock, fsync and rename.
    module ProtectedWorkspaceFixture
  class StatView < SimpleDelegator
    def initialize(stat, owner)
      super(stat)
      @owner = owner
    end
    def uid = @owner.first
    def gid = @owner.last
  end

  class Handle < SimpleDelegator
    def initialize(file, owner)
      super(file)
      @owner = owner
    end
    def stat = @owner ? StatView.new(__getobj__.stat, @owner) : __getobj__.stat
  end

  # Only namespace pathname/ownership observation is injected. Admission uses
  # maintained protection plus real temporary descriptors and kernel flock.
  class Files
    attr_accessor :marker_owner
    attr_reader :opened
    def initialize(root, view)
      @root, @view, @opened = root, view, []
    end
    def actual(path)
      path.start_with?(@view + "/") ? File.join(@root, path.delete_prefix(@view + "/")) : @root
    end
    def open(path, flags)
      raise "reader attempted creation or write" unless (flags & (File::CREAT | File::WRONLY | File::RDWR)).zero?
      @opened << Handle.new(File.open(actual(path), flags), path.end_with?(".state.json") ? marker_owner : nil)
      @opened.last
    end
    def lstat(path)
      stat = File.lstat(actual(path))
      path.end_with?(".state.json") && marker_owner ? StatView.new(stat, marker_owner) : stat
    end
  end

  class WriterFiles < Files
    def initialize(root, view, host)
      super(root, view)
      @host = host
    end
    def actual(path)
      [@view, @host].each do |prefix|
        return File.join(@root, path.delete_prefix(prefix + "/")) if path.start_with?(prefix + "/")
      end
      @root
    end
    def open(path, flags, mode = nil)
      raw = mode ? File.open(actual(path), flags, mode) : File.open(actual(path), flags)
      owner = path.end_with?(".fence") ? [0, 0] : path.end_with?(".state.json") ? marker_owner : nil
      handle = Handle.new(raw, owner)
      @opened << handle
      return handle unless block_given?
      begin
        yield handle
      ensure
        handle.close
      end
    end
    def rename(source, target)
      File.rename(actual(source), actual(target))
      self.marker_owner = [0, 0]
    end
    def exist?(path) = File.exist?(actual(path))
    def unlink(path) = File.unlink(actual(path))
  end

  class ProvisionFiles
    attr_reader :opened
    def initialize(root, state)
      @root, @state, @opened = root, state, []
    end
    def actual(path)
      path.start_with?(@state + "/") ? File.join(@root, path.delete_prefix(@state + "/")) : @root
    end
    def open(path, flags, mode = nil)
      handle = mode ? File.open(actual(path), flags, mode) : File.open(actual(path), flags)
      @opened << handle
      handle
    end
    def lstat(path) = File.lstat(actual(path))
  end

  class Mounts
    attr_accessor :flags
    def initialize(view, host)
      @view, @host, @flags = view, host, "ro"
    end
    def mount_identity(_handle)
      {"mount_id" => 10, "filesystem_type" => "ext4", "root" => @host, "mountpoint" => @view}
    end
    def read(path, limit:)
      raise "unexpected kernel file" unless path == "/proc/self/mountinfo"
      "10 0 8:1 #{@host} #{@view} #{flags} - ext4 fixture #{flags}\n"
    end
  end

  class ACL
    attr_accessor :default
    attr_reader :attributes
    def initialize
      @attributes = []
    end
    def entries(_path, attribute: "system.posix_acl_access")
      @attributes << attribute
      attribute == "system.posix_acl_default" ? default : nil
    end
  end

    end
  end
end
