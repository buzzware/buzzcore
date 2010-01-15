module StringUtils
	def self.crop(aString,aLength,aEllipsis=true,aConvertNil=true)
		return aConvertNil ? ' '*aLength : nil if !aString

    increase = aLength-aString.length
    return aString+' '*increase if increase>=0
		return aEllipsis ? aString[0,aLength-3]+'...' : aString[0,aLength]
  end

	# aTemplate is a string containing tokens like ${SOME_TOKEN}
	# aValues is a hash of token names eg. 'SOME_TOKEN' and their values to substitute
	def self.render_template(aTemplate,aValues)
		# get positions of tokens
		result = aTemplate.gsub(/\$\{(.*?)\}/) do |s| 
			key = s[2..-2]
			rep = (aValues[key] || s)
			#puts "replacing #{s} with #{rep}"
			rep
    end
		#puts "rendered :\n#{result}"
		return result
	end
	
	def self.clean_number(aString)
		aString.gsub(/[^0-9.-]/,'')
	end

	# supply a block with 2 parameters, and it will get called for each char as an integer
	def self.each_unicode_char(aString)
		len = 1
		index = 0
		char = 0
		aString.each_byte do |b|
			if index==0
				len = 1
				len = 2 if b & 0b11000000 != 0
				len = 3 if b & 0b11100000 != 0
				len = 4 if b & 0b11110000 != 0
				char = 0
			end
		
			char |= b << index*8
		
			yield(char,len) if index==len-1 # last byte; char is complete
		
			index += 1
			index = 0 if index >= len
		end
	end

	# given ('abcdefg','c.*?e') returns ['ab','cde','fg'] so you can manipulate the head, match and tail seperately, and potentially rejoin
	def self.split3(aString,aPattern,aOccurence=0)
		matches = aString.scan_md(aPattern)
		match = matches[aOccurence]
		parts = match ? [match.pre_match,match.to_s,match.post_match] : [aString,nil,'']

		if !block_given?	# return head,match,tail
			parts
		else						# return string
			parts[1] = yield *parts if match
			parts.join
		end
	end

	# truncates a string to the given length by looking for the previous space.
	def self.word_safe_truncate(aString,aMaxLength)
		return nil if !aString
		return aString if aString.length <= aMaxLength
		posLastSpace = aString.rindex(/[ \t]/,aMaxLength)
		return aString[0,aMaxLength] if !posLastSpace
		aString[0,posLastSpace]
	end
	
	# replaces all tabs with spaces, and reduces multiple spaces to a single space	
	def self.reduce_whitespace(aText)
		aText = aText.gsub("\t"," ")	# replace tabs with spaces
		aText.strip!
		aText.squeeze!(' ')
		aText
	end

end

