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

	def to_sql
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

if defined? ActiveRecord
	ActiveRecord::Base.class_eval do
	
		def self.find_any_id(aId)
			with_exclusive_scope { find(:first, {:conditions => {:id => aId}}) }
		end
	
		def self.find_any_all(aOptions={})
			with_exclusive_scope { find(:all, aOptions) }
		end
	
		def self.find_ids(aIds)
			find(:all, {:conditions=> ["id in (?)",aIds.join(',')]})
		end
	
		def self.find_any_ids(aIds)
			with_exclusive_scope { find(:all, {:conditions=> ["id in (?)",aIds.join(',')]}) }
		end
	
	end
end
