module Zimt
  class CLI < Thor
    desc "add SPRINKLE", "Adds the sprinkle"
    def add(name)
      sprinkle = Sprinkle.get(name)
      # TODO
    rescue OpenURI::HTTPError
      puts 'Sprinkle not found'
    end
  end
end
