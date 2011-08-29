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

    def install
      puts "Installing #{name}"
      FileUtils.mkdir "Zimt" if not File.exists? "Zimt"
      Zimt.pbxproj.ensure_zimt_group
      files.each do |url|
        file = Pathname.new(URI.parse(url).path).basename('.sprinkle.yml').to_s
        puts "Adding #{file}..."
        open(Pathname.new("Zimt").join(file), "w") do |io|
          io.write(open(url).read)
        end
        if file.end_with? ".m"
          Zimt.pbxproj.add_m_file(file)
        else
          Zimt.pbxproj.add_h_file(file)
        end
      end
      puts "All done"
    end
  end
end
