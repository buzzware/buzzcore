# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'rubygems'

require 'test/unit'
gem 'shoulda'; require 'shoulda'

require 'fileutils'

gem 'buzzcore'; require 'buzzcore'

class ExtendBaseClassesTest < Test::Unit::TestCase
	
	should "urlize generate correct url" do
		s = "Waiting for Grace (ii)"
		u = s.urlize
		assert_equal 'waiting-for-grace-ii',u
	end

end
