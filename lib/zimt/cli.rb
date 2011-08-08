module Zimt
  class CLI < Thor
    desc "add SPRINKLE", "Adds the sprinkle"
    def add(name)
      puts Zimt.pbxproj.root.targets.first.dependencies
      require 'ruby-debug' ; debugger
      # TODO
    end
  end
end
