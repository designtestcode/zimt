module Zimt
  class CLI < Thor
    desc "add SPRINKLE", "Adds the sprinkle"
    def add(name)
      Zimt.pbxproj.ensure_zimt_group
      Zimt.pbxproj.add_file("Hans.h")
      # TODO
    end
  end
end
