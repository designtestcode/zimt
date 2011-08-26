module Zimt
  class CLI < Thor
    desc "add SPRINKLE", "Adds the sprinkle"
    def add(name)
      Zimt.pbxproj.ensure_zimt_group
      Zimt.pbxproj.add_h_file("Hans.h")
      Zimt.pbxproj.add_m_file("Hans.m")
      # TODO
    end
  end
end
