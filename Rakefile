require 'bundler/gem_tasks'

task :default => :spec
task :spec do
  require 'bacon'
  Bacon.summary_on_exit
  Dir.glob(File.join(File.dirname(__FILE__),'spec','*_spec.rb')).each {|f| load(f) }
end
