require 'buzzcore/xml_utils'
require 'buzzcore/extend_base_classes'

class ConfigClass < Hash

	attr_reader :default_values

	def initialize(aDefaultValues,aNewValues=nil,&aBlock)
		@default_values = aDefaultValues.clone
		reset()
		if aNewValues
			block_given? ? read(aNewValues,&aBlock) : read(aNewValues) 
		end
	end

	# aBlock allows values to be filtered based on key,default and new values
	def read(aSource,&aBlock)
		default_values.each do |k,v|
			done = false
			if block_given? && ((newv = yield(k,v,aSource && aSource[k])) != nil)
				self[k] = newv
				done = true
			end
			copy_item(aSource,k) if !done && aSource && !aSource[k].nil?
		end
		self
	end
	
	# reset values back to defaults
	def reset
		self.clear
		me = self
		@default_values.each {|n,v| me[n] = v.is_a?(Class) ? nil : v}
	end

	def set_int(aKey,aValue)
		case aValue
			when String then    self[aKey] = aValue.to_integer(self[aKey]);
			when Fixnum then    self[aKey] = aValue;
			when Float then     self[aKey] = aValue.to_i;
		end
	end

	def set_float(aKey,aValue)
		case aValue
			when String then    self[aKey] = aValue.to_float(self[aKey]);
			when Fixnum then    self[aKey] = aValue.to_f;
			when Float then     self[aKey] = aValue;
		end
	end

	def set_boolean(aKey,aValue)
		case aValue
			when TrueClass,FalseClass then   self[aKey] = aValue;
			when String then    self[aKey] = (['1','yes','y','true','on'].include?(aValue.downcase))
		else
			set_boolean(aKey,aValue.to_s)
		end
	end
	
	def set_symbol(aKey,aValue)
		case aValue
			when String then    self[aKey] = (aValue.to_sym rescue nil);
			when Symbol then    self[aKey] = aValue;
		end
	end

	def copy_item(aHash,aKey)
		d = default_values[aKey]
		d_class = (d.is_a?(Class) ? d : d.class)
		cname = d_class.name.to_sym
		case cname
			when :NilClass then ;
			when :String then self[aKey] = aHash[aKey].to_s unless aHash[aKey].nil?
			when :Float then set_float(aKey,aHash[aKey]);
			when :Fixnum then set_int(aKey,aHash[aKey]);
			when :TrueClass, :FalseClass then set_boolean(aKey,aHash[aKey]);
			when :Symbol then self[aKey] = (aHash[aKey].to_sym rescue nil)
			else
				raise StandardError.new('unsupported type')
		end
	end

	def copy_strings(aHash,*aKeys)
		aKeys.each do |k|
			self[k] = aHash[k].to_s unless aHash[k].nil?
		end
	end

	def copy_ints(*aDb)
		aHash = aDb.shift
		aKeys = aDb
		aKeys.each do |k|
			set_int(k,aHash[k])
		end
	end

	def copy_floats(aHash,*aKeys)
		aKeys.each do |k|
			set_float(k,aHash[k])
		end
	end

	def copy_booleans(aHash,*aKeys)
		aKeys.each do |k|
			set_boolean(k,aHash[k])
		end
	end

	def to_hash
		{}.merge(self)
	end

end

class ConfigXmlClass < ConfigClass
	attr_accessor :xmlRoot
	def initialize(aDefaultValues,aConfig)
		return super(aDefaultValues,aConfig) unless aConfig.is_a?(REXML::Element)
		@xmlRoot = aConfig.deep_clone
		super(aDefaultValues,XmlUtils.read_simple_items(@xmlRoot,'/Yore/SimpleItems'))
	end
	
	def self.from_file(aDefaultValues,aFile)
		require 'ruby-debug'; debugger
		xml = XmlUtils.get_file_root(aFile)
		return ConfigXmlClass.new(aDefaultValues,xml)
	end
end

# credentials files look like :
#<?xml version="1.0" encoding="UTF-8"?>
#<Credentials>
#	<SimpleItems namespace="global">
#		<Item name=""></Item>
#		<Item name=""></Item>
#		<Item name=""></Item>
#	</SimpleItems>
#	<SimpleItems namespace="yore_test">
#		<Item name=""></Item>
#		<Item name=""></Item>
#		<Item name=""></Item>
#	</SimpleItems>
#</Credentials>
#
# global .credentials.xml file  
# local .credentials.xml file
# cred = Credentials.new()	# optionally specify filename or path or hash. if nil then use Dir.pwd
#
# def initialize(aSource)
#		# load global namespace from ~/.credentials.xml
#		# load global namespace from local .credentials.xml
#		# load given namespace from ~/.credentials.xml
#		# load given namespace from local .credentials.xml
#		# merge all top to bottom
class Credentials < Hash

	CRED_FILENAME = ".credentials.xml"

	def find_file_upwards(aFilename,aStartPath=nil)
		aStartPath ||= Dir.pwd
		return nil if aFilename.nil? || aFilename.empty?
		arrPath = aStartPath.split(File::SEPARATOR)
		while arrPath.length > 0
			path = File.join(arrPath.join(File::SEPARATOR),aFilename)
			return path if File.exists?(path)
			arrPath.pop
		end
		return nil
	end
	
	def get_all_credentials(aXmlRoot)
		return nil unless aXmlRoot
		result = {}
		REXML::XPath.each(aXmlRoot, '/Credentials/SimpleItems') do |si|
			ns = si.attributes['Namespace']
			values = XmlUtils.read_simple_items(si)
			result[ns.to_sym] = values.symbolize_keys if ns && values
		end
		return result
	end

	#XmlUtils.read_simple_items(@xmlRoot,'/Yore/SimpleItems')
	def get_user_credentials
		return get_all_credentials(XmlUtils.get_file_root(File.join(HOME_PATH,CRED_FILENAME)))
	end

	def get_local_credentials(aSource=nil)
		aSource ||= Dir.pwd
		# assume source is a directory path, but other types could be supported later
		return nil unless file=find_file_upwards(CRED_FILENAME,aSource)
		return get_all_credentials(XmlUtils.get_file_root(file))
	end

	def initialize(aNamespace=nil,aSource=nil)
		#HOME_PATH can be preset by tests eg. ::Credentials.const_set('HOME_PATH',@user_dir)
		Credentials.const_set("HOME_PATH", ENV['HOME']) unless Credentials.const_defined? "HOME_PATH"
		arrCredentials = []
		user_credentials = get_user_credentials()
		local_credentials = get_local_credentials(aSource)
		arrCredentials << user_credentials[:global] if user_credentials
		arrCredentials << local_credentials[:global] if local_credentials
		arrCredentials << user_credentials[aNamespace.to_sym] if aNamespace && user_credentials
		arrCredentials << local_credentials[aNamespace.to_sym] if aNamespace && local_credentials
		arrCredentials.compact!
		arrCredentials.each do |c|
			self.merge!(c)
		end
	end
end

