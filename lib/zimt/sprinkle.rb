module Zimt
  class Sprinkle
    attr_accessor :name, :url, :files, :spec

    LICENSES = {}
    LICENSES["MIT"] = <<EOF
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOF

    def self.get(name)
      if name.start_with?('http://') || name.start_with?('https://')
        url = name
      else
        url = "https://raw.github.com/zimt/sprinkles/stable/#{CGI.escape(name.downcase)}.sprinkle.yml"
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
      Zimt.pbxproj.ensure_zimt_group
      files.each do |url|
        file = Pathname.new(URI.parse(url).path).basename('.sprinkle.yml').to_s
        puts "Adding #{file}..."
        open(Pathname.new("Zimt").join(file), "w") do |io|
          io.write(open(url).read)
        end
        if file.end_with? ".m"
          Zimt.pbxproj.add_m_file(file)
        elsif file.end_with? ".h"
          Zimt.pbxproj.add_h_file(file)
        else
          Zimt.pbxproj.add_resource_file(file)
        end
      end

      if(spec["license"] || spec["copyright"])
        puts "Licensed under #{spec["license"]}"
        Zimt.pbxproj.ensure_license_file
        open(Pathname.new("Zimt").join("3rdPartyLicenses.txt"), "a") do |io|
          io.write "License for #{name}:\n\n"
          io.write spec["copyright"]
          io.write "\n\n"
          license = LICENSES[spec["license"]] || "#{spec["license"]}\n"
          io.write license
          io.write "\n----------\n\n"
        end
      end

      puts "All done"
    end
  end
end
