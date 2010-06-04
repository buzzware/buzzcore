gem 'sanitize'; require 'sanitize'
gem 'nokogiri'; require 'nokogiri'

module HtmlUtils

	# Truncates HTML text. Breaks on word boundaries and closes tags.
	# valid values for aLevel are :NO_TAGS, :RESTRICTED, :BASIC and :RELAXED
	def self.word_safe_truncate(aHtmlText,aMaxLength,aSuffix='...',aLevel=:BASIC)
		result = StringUtils.word_safe_truncate(aHtmlText,aMaxLength)
		level = case aLevel
			when :NO_TAGS		
				nil
			when :RESTRICTED
				Sanitize::Config::RESTRICTED
			when :BASIC
				Sanitize::Config::BASIC
			when :RELAXED
				Sanitize::Config::RELAXED
			else
				Sanitize::Config::BASIC
		end
		result = level ? Sanitize.clean(result,level) : Sanitize.clean(result)
		result += ' '+aSuffix
		result
	end
	
end
	
