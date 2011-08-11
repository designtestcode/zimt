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
    def uuid
      # TODO
      @prefix ||= rand(16**4).to_s(16).upcase
      @suffix ||= (Time.now.to_i.to_s(16) + rand(16**8).to_s(16)).upcase
      @count ||= rand(16**4)
      @count += 1
      "#{@prefix}#{@count.to_s(16).upcase}#{@suffix}"
    end

    attr_reader :hash, :objects, :root

    def initialize(file)
      @hash = JSON.parse(PBXProj.plutil(file)).freeze
      @objects = @hash['objects']
      @root = PBXHash.new(self, @hash['rootObject'], @objects[@hash['rootObject']])
    end

    def zimt_group
      Zimt.pbxproj.root.mainGroup.children.select{ |g| g.name == 'Zimt' }.first
    end
  end

  class PBXHash
    attr_reader :pbxid

    def initialize(pbxproj, pbxid, node)
      @pbxproj = pbxproj
      @pbxid = pbxid
      @node = node
    end

    def keys
      @node.keys
    end

    def inspect
      "<PBX: #{keys.join(', ')}>"
    end

    private
    def wrap(raw, recurse=true, id=nil)
      if raw.is_a? Array
        raw.map { |i| wrap(i, recurse) }
      elsif raw.is_a? Hash
        new_hash = raw.inject({}) { |h,(k,v)| h[k] = wrap(v, recurse) ; h }
        PBXHash.new(@pbxproj, id, new_hash)
      else
        if recurse and @pbxproj.objects.include? raw
          wrap(@pbxproj.objects[raw], false, raw)
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
