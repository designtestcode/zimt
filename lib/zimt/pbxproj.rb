module Zimt
  class PBXProj
    def self.plutil(file)
      `plutil -convert json -o - #{file}`
    end

    def initialize(file)
      @json = JSON.parse(PBXProj.plutil(file)).freeze
    end

    def hash
      @json
    end
  end
end
