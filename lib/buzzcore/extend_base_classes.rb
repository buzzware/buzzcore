String.class_eval do
	def pad_left(value)
		increase = value-self.length
		return self if increase==0
		if increase > 0
			return self + ' '*increase
		else
			return self[0,value]
		end
	end

	def pad_right(value)
		increase = value-self.length
		return self if increase==0
		if increase > 0
			return ' '*increase + self
		else
			return self[0,value]
		end
	end

	# Like chomp! but operates on the leading characters instead.
	# The aString parameter would not normally be used.
	def bite!(aValue=$/,aString=self)
		if aString[0,aValue.length] == aValue
			aString[0,aValue.length] = ''
			return aString
		else
			return aString
		end
	end

	def bite(aValue=$/)
		bite!(aValue,self.clone)
	end

	def begins_with?(aString)
		self[0,aString.length]==aString
	end

	def ends_with?(aString)
		self[-aString.length,aString.length]==aString
	end

# for future methods
#   def centre_bar(aChar = '-', indent = 6)
#     (' '*indent) + aChar*(@width-(indent*2)) + (' '*indent)
#   end
#   def replace_string(aString,aCol,aSubString)
#     return aString if aSubString==nil || aSubString==''
#
#     aSubString = aSubString.to_s
#     start_col = aCol < 0 ? 0 : aCol
#     end_col = aCol+aSubString.length-1
#     end_col = @width-1 if end_col >= @width
#     source_len = end_col-start_col+1
#     return aString if source_len <= 0 || end_col < 0 || start_col >= @width
#     aString += ' '*((end_col+1) - aString.length) if aString.length < end_col+1
#     aString[start_col,source_len] = aSubString[start_col-aCol,end_col-start_col+1]
#     return aString
#   end

	def to_integer(aDefault=nil)
		t = self.strip
		return aDefault if t.empty? || !t.index(/^-{0,1}[0-9]+$/)
		return t.to_i
	end

	def is_i?
		self.to_integer(false) and true
	end

	def to_float(aDefault=nil)
		t = self.strip
		return aDefault if !t =~ /(\+|-)?([0-9]+\.?[0-9]*|\.[0-9]+)([eE](\+|-)?[0-9]+)?/
		return t.to_f
	end

	def is_f?
		self.to_float(false) and true
	end

	# like scan but returns array of MatchData's.
	# doesn't yet support blocks
	def scan_md(aPattern)
		result = []
		self.scan(aPattern) {|s| result << $~ }
		result
	end

	def to_nil(aPattern=nil)
		return nil if self.empty?
		if aPattern
			return nil if (aPattern.is_a? Regexp) && (self =~ aPattern)
			return nil if aPattern.to_s == self
		end
		self
	end

	def to_b(aDefault=false)
		return true if ['1','yes','y','true','on'].include?(self.downcase)
		return false if ['0','no','n','false','off'].include?(self.downcase)
		aDefault
	end

	# "...Only alphanumerics [0-9a-zA-Z], the special characters "$-_.+!*'()," [not including the quotes - ed], and reserved characters used for their reserved purposes may be used unencoded within a URL."	

	URLIZE_SEPARATORS = /[ \\\(\)\[\]\.*,]/	# was /[ \\\(\)\[\]\.*,]/
	URLIZE_EXTENSIONS = %w(html htm jpg jpeg png gif bmp mov avi mp3 zip pdf css js doc xdoc)
	URLIZE_REMOVE = /[^a-z0-9\_\-+~\/]/ # was 'a-z0-9_-+~/'
	# aKeepExtensions may be an array of extensions to keep, or :none (will remove periods) or :all (any extension <= 4 chars)
	def urlize(aSlashChar='+',aRemove=nil,aKeepExtensions=nil)
		aKeepExtensions=URLIZE_EXTENSIONS if !aKeepExtensions
		aRemove=URLIZE_REMOVE if !aRemove
		return self if self.empty?
		result = self.downcase
		ext = nil
		if (aKeepExtensions!=:none) && last_dot = result.rindex('.')	
			if (ext_len = result.length-last_dot-1) <= 4	# preserve extension without dot if <= 4 chars long
				ext = result[last_dot+1..-1]
				ext = nil unless aKeepExtensions==:all || (aKeepExtensions.is_a?(Array) && aKeepExtensions.include?(ext))
				result = result[0,last_dot] if ext
			end
		end
		
		result = result.gsub(URLIZE_SEPARATORS,'-')
		result = result.gsub(aRemove,'').sub(/-+$/,'').sub(/^-+/,'')
		result.gsub!('/',aSlashChar) unless aSlashChar=='/'
		result.gsub!(/-{2,}/,'-')
		result += '.'+ext if ext
		result
	end

	private
	CRC_LOOKUP = [
		0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
		0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
		0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
		0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
		0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
		0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
		0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
		0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
		0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
		0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
		0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
		0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
		0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
		0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
		0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
		0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
		0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
		0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
		0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
		0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
		0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
		0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
		0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
		0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
		0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
		0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
		0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
		0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
		0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
		0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
		0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
		0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040
	]
	public

	def crc16
		crc = 0x00
		self.each_byte do |b|
			crc = ((crc >> 8) & 0xff) ^ CRC_LOOKUP[(crc ^ b) & 0xff]
		end
		crc
	end

	def has_tags?
		index(/<[a-zA-Z\-:0-9]+(\b|>)/) && (index('/>') || index('</'))		# contains an opening and closing tag
	end

end


Time.class_eval do

	if !respond_to?(:change)  # no activesupport loaded
		def change(options)
			::Time.send(
				self.utc? ? :utc : :local,
				options[:year]  || self.year,
				options[:month] || self.month,
				options[:day]   || self.day,
				options[:hour]  || self.hour,
				options[:min]   || (options[:hour] ? 0 : self.min),
				options[:sec]   || ((options[:hour] || options[:min]) ? 0 : self.sec),
				options[:usec]  || ((options[:hour] || options[:min] || options[:sec]) ? 0 : self.usec)
			)
		end

		def seconds_since_midnight
			self.to_i - self.change(:hour => 0).to_i + (self.usec/1.0e+6)
		end

		def beginning_of_day
			(self - self.seconds_since_midnight).change(:usec => 0)
		end

		alias :midnight :beginning_of_day
		alias :at_midnight :beginning_of_day
		alias :at_beginning_of_day :beginning_of_day

	end

	# offset of local machine from UTC, in seconds eg +9.hours
	def self.local_offset
		local(2000).utc_offset
	end

	def date
		self.at_beginning_of_day
	end

	# index number of this day, from Time.at(0) + utc_offset
	def day_number
		(self.to_i+self.utc_offset) / 86400
	end

	# index number of this utc day
	def day_number_utc
		self.to_i / 86400
	end

	# the last microsecond of the day
	def day_end
		self.at_beginning_of_day + 86399.999999
	end

	def date_numeric
		self.strftime('%Y%m%d')
	end

	def to_universal
		self.strftime("%d %b %Y")
	end

	# create a new Time from eg. "20081231"
	def self.from_date_numeric(aString)
		return nil unless aString
		local(aString[0,4].to_i,aString[4,2].to_i,aString[6,2].to_i)
	end

	def time_numeric
		self.strftime('%H%M%S')
	end

	def datetime_numeric
		self.strftime('%Y%m%d-%H%M%S')
	end

	def to_sql_format # was to_sql, but clashed with Rails 3
		self.strftime('%Y-%m-%d %H:%M:%S')
	end

	def to_w3c
		utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
	end
end

module HashUtils
	def filter_include!(aKeys,aHash=nil)
		aHash ||= self

		if aKeys.is_a? Regexp
			return aHash.delete_if {|k,v| not k =~ aKeys }
		else
			aKeys = [aKeys] unless aKeys.is_a? Array
			return aHash.clear if aKeys.empty?
			return aHash.delete_if {|key, value| !((aKeys.include?(key)) || (key.is_a?(Symbol) and aKeys.include?(key.to_s)) || (key.is_a?(String) and aKeys.include?(key.to_sym)))}
			return aHash	# last resort
		end
	end

	def filter_include(aKeys,aHash=nil)
		aHash ||= self
		filter_include!(aKeys,aHash.clone)
	end

	def filter_exclude!(aKeys,aHash=nil)
		aHash ||= self

		if aKeys.is_a? Regexp
			return aHash.delete_if {|k,v| k =~ aKeys }
		else
			aKeys = [aKeys] unless aKeys.is_a? Array
			return aHash if aKeys.empty?
			return aHash.delete_if {|key, value| ((aKeys.include?(key)) || (key.is_a?(Symbol) and aKeys.include?(key.to_s)) || (key.is_a?(String) and aKeys.include?(key.to_sym)))}
		end
	end

	def filter_exclude(aKeys,aHash=nil)
		aHash ||= self
		filter_exclude!(aKeys,aHash.clone)
	end

	def has_values_for?(aKeys,aHash=nil)
		aHash ||= self
		# check all keys exist in aHash and their values are not nil
		aKeys.all? { |k,v| aHash[k] }
	end

	# give a block to execute without the given key in this hash
	# It will be replaced after the block (guaranteed by ensure)
	# eg.
	# hash.without_key(:blah) do |aHash|
	#		puts aHash.inspect
	# end
	def without_key(aKey)
		temp = nil
		h = self
		begin
			if h.include?(aKey)
				temp = [aKey,h.delete(aKey)]
			end
			result = yield(h)
		ensure
			h[temp[0]] = temp[1] if temp
		end
		return result
	end

	def symbolize_keys
		result = {}
		self.each { |k,v| k.is_a?(String) ? result[k.to_sym] = v : result[k] = v  }
		return result
	end

	def to_nil
		self.empty? ? nil : self
	end

end

Hash.class_eval do
	include HashUtils
end

if defined? HashWithIndifferentAccess
	HashWithIndifferentAccess.class_eval do
		include HashUtils
	end
end

module ArrayUtils
	def filter_include!(aValues,aArray=nil)
		aArray ||= self
		if aValues.is_a? Array
			return aArray if aValues.empty?
			return aArray.delete_if {|v| not aValues.include? v }
		elsif aValues.is_a? Regexp
			return aArray.delete_if {|v| not v =~ aValues }
		else
			return filter_include!([aValues],aArray)
		end
	end

	def filter_include(aValues,aArray=nil)
		aArray ||= self
		filter_include!(aValues,aArray.clone)
	end

	def filter_exclude!(aValues,aArray=nil)
		aArray ||= self
		if aValues.is_a? Array
			return aArray if aValues.empty?
			return aArray.delete_if {|v| aValues.include? v }
		elsif aValues.is_a? Regexp
			return aArray.delete_if {|v| v =~ aValues }
		else
			return filter_exclude!([aValues],aArray)
		end
	end

	def filter_exclude(aValues,aArray=nil)
		aArray ||= self
		filter_exclude!(aValues,aArray.clone)
	end

	def to_nil
		self.empty? ? nil : self
	end

end

Array.class_eval do
	include ArrayUtils

	# fixes a memory leak in shift in Ruby 1.8 - should be fixed in 1.9
	# see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/216055
	def shift()
		delete_at(0)
	end

end

Kernel.class_eval do
	def is_windows?
		RUBY_PLATFORM =~ /(win|w)32$/ ? true : false
	end
end

#if defined? ActiveRecord
#	ActiveRecord::Base.class_eval do
#
#		def self.find_any_id(aId)
#			with_exclusive_scope { find(:first, {:conditions => {:id => aId}}) }
#		end
#
#		def self.find_any_all(aOptions={})
#			with_exclusive_scope { find(:all, aOptions) }
#		end
#
#		def self.find_ids(aIds)
#			find(:all, {:conditions=> ["id in (?)",aIds.join(',')]})
#		end
#
#		def self.find_any_ids(aIds)
#			with_exclusive_scope { find(:all, {:conditions=> ["id in (?)",aIds.join(',')]}) }
#		end
#
#	end
#end

Fixnum.class_eval do

	def to_nil
		self==0 ? nil : self
	end

	def to_b(aDefault=false)
		self==0 ? false : true
	end

end

Bignum.class_eval do

	def to_nil
		self==0 ? nil : self
	end

	def to_b(aDefault=false)
		self==0 ? false : true
	end

end

NilClass.class_eval do

	def to_nil
		nil
	end

	def to_b(aDefault=false)
		false
	end

end

TrueClass.class_eval do

	def to_nil
		self
	end

	def to_b(aDefault=false)
		self
	end

end

FalseClass.class_eval do

	def to_nil
		nil
	end

	def to_b(aDefault=false)
		self
	end

end


Math.module_eval do
	def self.max(a, b)
		a > b ? a : b
	end

	def self.min(a, b)
		a < b ? a : b
	end
end

