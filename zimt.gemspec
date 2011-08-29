# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zimt/version"

Gem::Specification.new do |s|
  s.name        = "zimt"
  s.version     = Zimt::VERSION
  s.authors     = ["Martin Schürrer"]
  s.email       = ["martin@schuerrer.org"]
  s.homepage    = "https://github.com/zimt/zimt"
  s.summary     = "Zimt is a collection of Cocoa extensions with clever package management"
  s.description = "Zimt downloads and adds files to your .xcodeproj."

  s.rubyforge_project = "zimt"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'json', '~> 1.5.0'
  s.add_dependency 'thor', '~> 0.14.0'
  s.add_development_dependency 'bacon', '~> 1.1.0'
  s.add_development_dependency 'ruby-debug', '~> 0.10.0'
end
