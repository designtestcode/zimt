module Zimt
  class PBXProj
    def self.plutil(file)
      `plutil -convert json -o - #{file}`
    end


    # Documentation on PBXObjectId by @tjw
    # http://lists.apple.com/archives/projectbuilder-users/2003/Jan/msg00263.html
    #
    # ObjectId gets generated in the following format:
    # +----------------------------------------------------------------------+
    # | RANDOM    | SEQ       |  TIME                | PID       | IP (2)    |
    # | byte byte | byte byte | byte byte  byte byte | byte byte | byte byte |
    # +----------------------------------------------------------------------+
    # RANDOM = 2 bytes of random number for distribution
    # SEQ    = Unsigned short sequence counter that starts randomly.
    # TIME = Seconds since epoch (1/1/1970)
    # PID  = Process ID
    #        This is only two bytes even though most pids are longs.
    #        Here you would take the lower 2 bytes.
    # IP   = IP Address of the machine (subnet.hostId)
    def self.uuid
      # TODO
      rand(16**24).to_s(16).upcase
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
