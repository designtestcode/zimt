module Zimt
  class CLI < Thor
    desc "add SPRINKLE", "Adds the sprinkle"
    def add(name)
      Zimt.pbxproj.add_zimt_group
      Zimt.pbxproj.save!
      # TODO
    end
  end
end
