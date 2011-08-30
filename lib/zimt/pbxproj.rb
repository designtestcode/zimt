module Zimt
  class PBXProj
    def self.plutil(file)
      `plutil -convert json -o - #{file}`
    end

    def randhex(length=1)
      @buffer = ""
      length.times do
        @buffer << rand(16).to_s(16).upcase
      end
      @buffer
    end


    FILE_FORMATS = { '.png' => 'image.png',
                     '.plist' => 'text.plist.xml' }

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
      @prefix ||= randhex(4)
      @suffix ||= Time.now.to_i.to_s(16).upcase + randhex(8)
      @count ||= rand(16**4)
      @count += 1
      if @count.to_s(16).length < 4
        @count = @count * 16
      end
      uuid = "#{@prefix}#{@count.to_s(16).upcase}#{@suffix}"
      if uuid.length != 24
        puts "uuid length wrong: #{uuid}"
        exit
      end
      uuid
    end

    attr_reader :content, :hash, :objects, :root
    attr_accessor :position

    def initialize(file)
      @filename = file
      @content = File.readlines(file)
      self.parse
    end

    def parse
      @hash = JSON.parse(PBXProj.plutil(@filename)).freeze
      @objects = @hash['objects']
      @root = PBXHash.new(self, @hash['rootObject'], @objects[@hash['rootObject']])
    end

    def save!
      File.open(@filename, "w") { |f|
        f.write(self.content.join(''))
      }
    end

    def zimt_group
      self.root.mainGroup.children.select{ |g| g.path == 'Zimt' }.first
    end

    def ensure_zimt_group
      zimt_group = self.zimt_group
      if zimt_group.nil?
        self.add_zimt_group
      end
    end

    #		C5FE9B6F13BA7537004CCA66 = {
    #			isa = PBXGroup;
    #			children = (
    #				C5FE9B8413BA7537004CCA66 /* Sources */,
    #				C7826AD313D9137D00661EEC /* Resources */,
    #				C5FE9B7D13BA7537004CCA66 /* Frameworks */,
    #				C5FE9B7B13BA7537004CCA66 /* Products */,
    #				C5E20A8613F4507D00C5DDF3 /* Zimt */,
    #			);
    #			sourceTree = "<group>";
    #		};
    def add_zimt_group
      # Add Zimt reference to mainGroup
      groupid = self.root.mainGroup.pbxid
      scan_to "\t\t#{groupid}"
      scan_to "\t\t\t);"
      newgroup = self.uuid
      self.content.insert(@position, "\t\t\t\t#{newgroup} /* Zimt */,\n")

      # Find position for Zimt reference in PBXGRoup section
      @position = 0
      scan_to "/* Begin PBXGroup section */"
      begin_position = @position
      scan_to "/* End PBXGroup section */"
      end_position = @position

      @position = begin_position
      while @position < end_position
        line = self.content[@position]
        if (line.end_with? " = {\n")
          groupname = line.split(' ')[0]
          if groupname > newgroup
            break
          end
        end
        @position += 1
      end

      # Add Zimt Group
      self.content.insert(@position,
                          "\t\t#{newgroup} /* Zimt */ = {\n",
                          "\t\t\tisa = PBXGroup;\n",
                          "\t\t\tchildren = (\n",
                          "\t\t\t);\n",
                          "\t\t\tpath = Zimt;\n",
                          "\t\t\tsourceTree = \"<group>\";\n",
                          "\t\t};\n")

      self.save!
      self.parse
    end

    #/* Begin PBXFileReference section */
    #		C5D0CB021406C3AA002E631F /* Hans.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = Hans.h; sourceTree = "<group>"; };
    #/* End PBXFileReference section */
    def add_file(file, file_type)
      @position = 0
      zimt_group_id = self.zimt_group.pbxid
      # Add file to Zimt group
      groupid = self.root.mainGroup.pbxid
      scan_to "\t\t#{zimt_group_id}"
      scan_to "\t\t\t);"
      newgroup = self.uuid
      self.content.insert(@position, "\t\t\t\t#{newgroup} /* #{file} */,\n")

      # Find position for Zimt reference in PBXGRoup section
      @position = 0
      scan_to "/* Begin PBXFileReference section */"
      begin_position = @position
      scan_to "/* End PBXFileReference section */"
      end_position = @position

      @position = begin_position
      while @position < end_position
        line = self.content[@position]
        groupname = line.split(' ')[0]
        if groupname > newgroup
          break
        end
        @position += 1
      end

      # Escape filename
      if not file.match /^[A-Za-z0-9.]+$/
        escaped_file = "\"#{file}\""
      else
        escaped_file = file
      end

      # Add Zimt Group
      self.content.insert(@position,
                          "\t\t#{newgroup} /* #{file} */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = #{file_type}; path = #{escaped_file}; sourceTree = \"<group>\"; };\n")

      self.save!
      self.parse
      return newgroup
    end

    def add_h_file(file)
      add_file(file, "sourcecode.c.h")
    end

    def add_m_file(file)
      fileref = self.add_file(file, "sourcecode.c.objc")
      buildfileref = self.add_buildfile(file, fileref, "Sources")
      add_buildfileref_to_build_phase(file, buildfileref, "Sources")
    end

    def add_resource_file(file)
      file_type = FILE_FORMATS[Pathname.new(file).extname.downcase] || 'text'
      fileref = self.add_file(file, file_type)
      buildfileref = self.add_buildfile(file, fileref, "Resources")
      add_buildfileref_to_build_phase(file, buildfileref, "Resources")
    end

#/* Begin PBXBuildFile section */
#		C53D93B21406F98300F4CDDE /* Hans.m in Sources */ = {isa = PBXBuildFile; fileRef = C53D93B11406F98300F4CDDE /* Hans.m */; };
#/* End PBXBuildFile section */
    def add_buildfile(file, fileref, filetype)
      newgroup = self.uuid
      # Find position for Zimt reference in PBXGRoup section
      @position = 0
      scan_to "/* Begin PBXBuildFile section */"
      begin_position = @position
      scan_to "/* End PBXBuildFile section */"
      end_position = @position

      @position = begin_position
      while @position < end_position
        line = self.content[@position]
        groupname = line.split(' ')[0]
        if groupname > newgroup
          break
        end
        @position += 1
      end

      # Add Zimt Group
      self.content.insert(@position,
                          "\t\t#{newgroup} /* #{file} in #{filetype} */ = {isa = PBXBuildFile; fileRef = #{fileref} /* #{file} */; };\n")

      self.save!
      self.parse
      return newgroup
    end

    #/* Begin PBXSourcesBuildPhase section */
    #		8D11072C0486CEB800E47090 /* Sources */ = {
    #			files = (
    #				C53D93B21406F98300F4CDDE /* Hans.m in Sources */,
    #			);
    #		C56D96C81385E71800070608 /* Sources */ = {
    #/* End PBXSourcesBuildPhase section */
    def add_buildfileref_to_build_phase(file, buildfileref, phase_name)
      @position = 0
      scan_to "/* Begin PBX#{phase_name}BuildPhase section */"
      begin_position = @position
      scan_to "/* End PBX#{phase_name}BuildPhase section */"
      end_position = @position

      @position = begin_position
      while @position < end_position
        line = self.content[@position]
        if (line.end_with? " = {\n")
          old_position = @position
          scan_to("			);\n")
          self.content.insert(@position,
                              "				#{buildfileref} /* #{file} in #{phase_name} */,\n")
          @position = old_position + 1 # offset for added line
          break
        end
        @position += 1
      end

      self.save!
      self.parse
    end

    def scan_to(what)
      @position ||= 0
      while true
        line = self.content[@position]
        if line.nil?
          raise "#{what} not found"
        end
        if line.start_with? what
          return
        end
        @position += 1
      end
    end

    def current_line
      @position ||= 0
      self.content[@position]
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
