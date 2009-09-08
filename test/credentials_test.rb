require 'rubygems'
require 'buzzcore/misc_utils'
require 'buzzcore/config'
require 'buzzcore/shell_extras'
require 'test/unit'
gem 'Shoulda'; require 'shoulda'
require 'fileutils'

class CredentialsTest < Test::Unit::TestCase

	def setup
		@temp_dir = MiscUtils.make_temp_dir('CredentialsTest')
		@user_dir = File.join(@temp_dir,'home/fred')
		FileUtils.mkdir_p(@user_dir)
		@project_dir = File.join(@temp_dir,'projects/moon')
		@current_dir = File.join(@project_dir,'source')
		FileUtils.mkdir_p(@current_dir)
		::Credentials.const_set('HOME_PATH',@user_dir)
  end
	
	def cred_xml
		return XmlUtils.get_xml_root('<?xml version="1.0" encoding="UTF-8"?><Credentials></Credentials>')
	end
	
	def add_namespace_xml(aCredentialsXml,aNamespace,aItems=nil)
		result = XmlUtils.add_xml_from_string("<SimpleItems Namespace=\"#{aNamespace.to_s}\"></SimpleItems>",aCredentialsXml)
		return result unless aItems
		aItems.each do |n,v|
			XmlUtils.add_xml_from_string("<Item Name=\"#{n.to_s}\">#{v.to_s}</Item>",result)
		end
		return result
	end
	
	should "read SimpleItems" do
		xml = XmlUtils.get_xml_root('<?xml version="1.0"?><Credentials><SimpleItems Namespace="global"><Item Name="a">5</Item><Item Name="b">hello</Item></SimpleItems></Credentials>')
		si = REXML::XPath.first(xml,'/Credentials/SimpleItems')
		values = XmlUtils.read_simple_items(si)
		assert_equal values['a'],'5'
		assert_equal values['b'],'hello'
	end

	should "load local credentials file" do
		xml = cred_xml()
		add_namespace_xml(xml.root,:global,{:a=>5,'b'=>'hello'})
		MiscUtils.string_to_file(xml.document.to_s,File.join(@project_dir,Credentials::CRED_FILENAME))
		cred = Credentials.new(:moon,@current_dir)
		assert_equal cred[:a],'5'
		assert_equal cred[:b],'hello'
	end
	
	should "load user credentials file" do
		xml = cred_xml()
		add_namespace_xml(xml,:global,{:a=>7,'b'=>'apples'})
		MiscUtils.string_to_file(xml.document.to_s,File.join(@user_dir,Credentials::CRED_FILENAME))
		cred = Credentials.new(:moon,@current_dir)
		assert_equal cred[:a],'7'
		assert_equal cred[:b],'apples'
	end

	should "specified namespace values should override global, and other namespace doesn't interfere" do
		xml = cred_xml()
		add_namespace_xml(xml,:global,{:a=>1,'b'=>'green'})
		add_namespace_xml(xml,:moon,{'b'=>'red'})
		add_namespace_xml(xml,:blah,{'a'=>'yellow','b'=>20})
		MiscUtils.string_to_file(xml.document.to_s,File.join(@user_dir,Credentials::CRED_FILENAME))
		cred = Credentials.new(:moon,@current_dir)
		assert_equal cred[:a],'1'
		assert_equal cred[:b],'red'
	end
	
end
