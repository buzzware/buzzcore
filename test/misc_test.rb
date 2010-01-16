# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'rubygems'

require 'test/unit'
gem 'Shoulda'; require 'shoulda'

require 'fileutils'

gem 'buzzcore'; require 'buzzcore'

class MiscTest < Test::Unit::TestCase

	context "expand_magic_path" do
		
		setup do
			@temp_path = MiscUtils.canonize_path(MiscUtils.make_temp_dir('expand_magic_path'))
			FileUtils.mkdir_p(@c = File.join(@temp_path,'a/b/c'))
			FileUtils.mkdir_p(@aaa = File.join(@temp_path,'aaa'))
			@xxx = MiscUtils.make_temp_file('xxx',@aaa)
    end

		should "expand leading .../ and find existing path" do
			assert_equal @aaa,MiscUtils.expand_magic_path('.../aaa',@c)
			assert_equal @xxx,MiscUtils.expand_magic_path('.../aaa/xxx',@c)
			Dir.chdir(@c) do
				assert_equal @aaa,MiscUtils.expand_magic_path('.../aaa')
				assert_equal @xxx,MiscUtils.expand_magic_path('.../aaa/xxx')
			end
		end

		should "return nil when expand leading .../ fails" do
			assert_equal nil,MiscUtils.expand_magic_path('.../aaa/xyz',@c)
		end
		
	end
	

end
