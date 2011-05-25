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
	
	def self.html_to_plain(aHtml)
		return '' if !aHtml
		aHtml = StringUtils.simplify_whitespace(aHtml)
		aHtml = Sanitize.clean(aHtml)
		StringUtils.simplify_whitespace(aHtml)
	end
	
	def self.plain_words(aHtmlText,aWords)
		result = CGI.unescapeHTML(Sanitize.clean(aHtmlText))
		StringUtils.crop_to_word_count(result,aWords)
	end

	def self.plain_chars(aHtmlText,aMaxLength)
		result = CGI.unescapeHTML(Sanitize.clean(aHtmlText))
		result = StringUtils.simplify_whitespace(result)
		StringUtils.word_safe_truncate(result,aMaxLength)
	end

end
	
