require 'json'
require 'pathname'
require 'thor'
require "zimt/cli"
require "zimt/pbxproj"
require "zimt/version"

module Zimt
  def self.xcodeproj
    @xcodeproj ||= find_xcodeproj
    raise "Could not locate .xcodeproj" unless @xcodeproj
    Pathname.new(@xcodeproj)
  end

  def self.pbxproj
    path = Pathname.new(File.join(self.xcodeproj, 'project.pbxproj'))
    @pbxproj ||= PBXProj.new(path)
  end

  def self.zimts_dir
    Pathname.new(File.expand_path(File.join(self.xcodeproj, '..', 'zimts')))
  end

  private

  def self.find_xcodeproj
    given = ENV['ZIMT_XCODEPROJ']
    return given if given && !given.empty?

    previous = nil
    current  = File.expand_path(Dir.pwd)

    until !File.directory?(current) || current == previous
      # otherwise return the Gemfile if it's there
      filenames = Dir.glob(File.join(current, '*.xcodeproj'))
      raise "More than one .xcodeproj found: #{filenames}" if filenames.length > 1
      filename = filenames.first
      return filename if File.directory?(filename) and File.file?(File.join(filename, 'project.pbxproj'))
      current, previous = File.expand_path("..", current), current
    end
  end

end

