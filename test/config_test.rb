require 'rubygems'
require 'buzzcore/misc_utils'
require 'buzzcore/config'
require 'buzzcore/shell_extras'
require 'test/unit'
gem 'shoulda'; require 'shoulda'
require 'fileutils'

class ConfigTest < Test::Unit::TestCase

	#def setup
	#	@temp_dir = MiscUtils.make_temp_dir('CredentialsTest')
	#	@user_dir = File.join(@temp_dir,'home/fred')
	#	FileUtils.mkdir_p(@user_dir)
	#	@project_dir = File.join(@temp_dir,'projects/moon')
	#	@current_dir = File.join(@project_dir,'source')
	#	FileUtils.mkdir_p(@current_dir)
	#	::Credentials.const_set('HOME_PATH',@user_dir)
  #end
	
	def config_xml
		return XmlUtils.get_xml_root('<?xml version="1.0" encoding="UTF-8"?><Config></Config>')
	end
	
	should "read values of same type as default value classes" do 
		xml = config_xml
		# values given of native type
		defaults = {
			:a => String,
			:b => Fixnum,
			:c => Float,
			:d => TrueClass,
			:e => FalseClass,
		}
		values = {
			:a => '1',
			:b => 3,
			:c => 2.3,
			:d => true,
			:e => false,
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		puts config.inspect
		assert_equal config[:a],'1'
		assert_equal config[:b],3
		assert_equal config[:c],2.3
		assert_equal config[:d],true
		assert_equal config[:e],false
	end
	
	should "read values of different type as default value classes" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => String,
			:b => Fixnum,
			:c => Float,
			:d => TrueClass,
			:e => FalseClass,
		}
		values = {
			:a => 1,
			:b => 3.2,
			:c => 2,
			:d => 'false',
			:e => 0,
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'1'
		assert_equal config[:b],3
		assert_equal config[:c],2.0
		assert_equal config[:d],false
		assert_equal config[:e],false
	end

	should "read values when defaults are actual values, and values of correct type" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => 'X',
			:b => 6,
			:c => 7.8,
			:d => true,
			:e => false,
		}
		values = {
			:a => 'why',
			:b => 3,
			:c => 2.9,
			:d => false,
			:e => true,
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'why'
		assert_equal config[:b],3
		assert_equal config[:c],2.9
		assert_equal config[:d],false
		assert_equal config[:e],true
	end

	should "read values when defaults are actual values, and values of other type" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => 'X',
			:b => 6,
			:c => 7.8,
			:d => true,
			:e => false,
		}
		values = {
			:a => 123.4,
			:b => '7',
			:c => '9',
			:d => 0,
			:e => 'yes',
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'123.4'
		assert_equal config[:b],7
		assert_equal config[:c],9.0
		assert_equal config[:d],false
		assert_equal config[:e],true
	end
		
	should "let value defaults through, exclude values not in defaults" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => 'X',
			:b => 6,
			:c => 7.8,
			:d => true,
			:e => false,
		}
		values = {
			:x => 89
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'X'
		assert_equal config[:b],6
		assert_equal config[:c],7.8
		assert_equal config[:d],true
		assert_equal config[:e],false
		assert_equal config[:x],nil
	end
	
	should "let value defaults through, exclude values not in defaults" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => 'X',
			:b => 6,
			:c => 7.8,
			:d => true,
			:e => false,
		}
		values = {
			:x => 89
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'X'
		assert_equal config[:b],6
		assert_equal config[:c],7.8
		assert_equal config[:d],true
		assert_equal config[:e],false
		assert_equal config[:x],nil
	end
	
	should "let Class defaults through, exclude values not in defaults" do
		xml = config_xml
		# values given of native type
		defaults = {
			:a => String,
			:b => Fixnum,
			:c => Float,
			:d => TrueClass,
			:e => FalseClass,
		}
		values = {
			'x' => 89,
			:a => 89
		}
		config = ConfigClass.new(defaults)
		config.read(values)
		assert_equal config[:a],'89'
		assert_equal config[:b],nil
		assert_equal config[:c],nil
		assert_equal config[:d],nil
		assert_equal config[:e],nil
		assert_equal config[:x],nil
	end
	
	
end
