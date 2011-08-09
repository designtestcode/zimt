module Zimt
  class PBXProj
    def self.plutil(file)
      `plutil -convert json -o - #{file}`
    end

    attr_reader :hash, :objects, :root

    def initialize(file)
      @hash = JSON.parse(PBXProj.plutil(file)).freeze
      @objects = @hash['objects']
      @root = PBXHash.new(self, @objects[@hash['rootObject']])
    end
  end

  class PBXHash
    def initialize(pbxproj, node)
      @pbxproj = pbxproj
      @node = node
    end

    def keys
      @node.keys
    end

    def inspect
      "<PBX: #{keys.join(', ')}>"
    end

    private
    def wrap(raw, recurse=true)
      if raw.is_a? Array
        raw.map { |i| wrap(i, recurse) }
      elsif raw.is_a? Hash
        new_hash = raw.inject({}) { |h,(k,v)| h[k] = wrap(v, recurse) ; h }
        PBXHash.new(@pbxproj, new_hash)
      else
        if recurse and @pbxproj.objects.include? raw
          wrap(@pbxproj.objects[raw], false)
        else
          raw
        end
      end
    end

    def method_missing(sym)
      wrap(@node[sym.to_s])
    end

  end
end
