require 'open-uri'

module Zimt
  class Sprinkle
    attr_accessor :name, :url, :files

    def self.get(name)
      if name.start_with?('http://') || name.start_with?('https://')
        url = name
      else
        url = "https://raw.github.com/zimt/sprinkles/stable/#{name.downcase}.sprinkle.yml"
      end
      spec = open(url) { |f| YAML::load(f) }
      self.new(spec)
    end

    def initialize(spec)
      @spec = spec
      @name = spec["name"]
      @url = spec["url"]
      @files = spec["files"]
    end
  end
end
