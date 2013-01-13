#require "buzzcore/version"

Dir.chdir(File.dirname(__FILE__)) { Dir['buzzcore/*.rb'] }.each {|f| require f }

