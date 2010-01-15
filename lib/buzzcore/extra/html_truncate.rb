gem 'sanitize'; require 'sanitize'
gem 'nokogiri'; require 'nokogiri'

module HtmlUtils

	# Truncates HTML text. Breaks on word boundaries and closes tags. 
	# aSuffix will be encoded with entities
	def self.word_safe_truncate(aHtmlText,aMaxLength,aSuffix='...')
		result = StringUtils.word_safe_truncate(aHtmlText,aMaxLength)+' '+aSuffix
		Sanitize.clean(result,Sanitize::Config::BASIC)
	end
	
  #
  #
	## from http://gist.github.com/101410
	#def self.html_truncate(input, num_words = 15, truncate_string = "...")
	#	doc = Nokogiri::HTML(input)
  #
	#	current = doc.children.first
	#	count = 0
  #
	#	while true
	#		# we found a text node
	#		if current.is_a?(Nokogiri::XML::Text)
	#			count += current.text.split.length
	#			# we reached our limit, let's get outta here!
	#			break if count > num_words
	#			previous = current
	#		end
  #
	#		if current.children.length > 0
	#			# this node has children, can't be a text node,
	#			# lets descend and look for text nodes
	#			current = current.children.first
	#		elsif !current.next.nil?
	#			#this has no children, but has a sibling, let's check it out
	#			current = current.next
	#		else
	#			# we are the last child, we need to ascend until we are
	#			# either done or find a sibling to continue on to
	#			n = current
	#			while !n.is_a?(Nokogiri::HTML::Document) and n.parent.next.nil?
	#				n = n.parent
	#			end
  #
	#			# we've reached the top and found no more text nodes, break
	#			if n.is_a?(Nokogiri::HTML::Document)
	#				break;
	#			else
	#				current = n.parent.next
	#			end
	#		end
	#	end
  #
	#	if count >= num_words
	#		unless count == num_words
	#			new_content = current.text.split
  #
	#			# If we're here, the last text node we counted eclipsed the number of words
	#			# that we want, so we need to cut down on words.  The easiest way to think about
	#			# this is that without this node we'd have fewer words than the limit, so all
	#			# the previous words plus a limited number of words from this node are needed.
	#			# We simply need to figure out how many words are needed and grab that many.
	#			# Then we need to -subtract- an index, because the first word would be index zero.
  #
	#			# For example, given:
	#			# <p>Testing this HTML truncater.</p><p>To see if its working.</p>
	#			# Let's say I want 6 words.  The correct returned string would be:
	#			# <p>Testing this HTML truncater.</p><p>To see...</p>
	#			# All the words in both paragraphs = 9
	#			# The last paragraph is the one that breaks the limit.  How many words would we
	#			# have without it? 4.  But we want up to 6, so we might as well get that many.
	#			# 6 - 4 = 2, so we get 2 words from this node, but words #1-2 are indices #0-1, so
	#			# we subtract 1.  If this gives us -1, we want nothing from this node. So go back to
	#			# the previous node instead.
	#			index = num_words-(count-new_content.length)-1
	#			if index >= 0
	#				new_content = new_content[0..index]
	#				current.inner_html = new_content.join(' ') + truncate_string
	#				#require 'ruby-debug'; debugger
	#				#current = current.parent.add_child(Nokogiri::XML::Node.new(truncate_string,current.document))
	#				#current.content.inner_html = current.content.inner_html + truncate_string
	#			else
	#				current = previous
	#				#current.content = current.content + truncate_string
	#				current.inner_html = current.content + truncate_string
	#				#current = current.parent.add_child(Nokogiri::XML::Node.new(truncate_string,current.document))
	#				#current.inner_html = current.content.inner_html + truncate_string
	#			end
	#		end
  #
	#		# remove everything else
	#		while !current.is_a?(Nokogiri::HTML::Document)
	#			while !current.next.nil?
	#				current.next.remove
	#			end
	#			current = current.parent
	#		end
	#	end
  #
	#	# now we grab the html and not the text.
	#	# we do first because nokogiri adds html and body tags
	#	# which we don't want
	#	doc.root.children.first.inner_html
	#end

	# from http://blog.leshill.org/blog/2009/06/03/truncating-html.html

  # Like the Rails _truncate_ helper but doesn't break HTML tags or entities.
  #def truncate_html(text, max_length = 30, ellipsis = "...")
  #  return if text.nil?
  #  doc = Hpricot(text.to_s)
  #  doc.inner_text.chars.length > max_length ? doc.truncate(max_length, ellipsis).inner_html : text.to_s
  #end
  #
  #def self.truncate_at_space(text, max_length, ellipsis = '...')
  #  l = [max_length - ellipsis.length, 0].max
  #  stop = text.rindex(' ', l) || 0
  #  (text.length > max_length ? text[0...stop] + ellipsis : text).to_s
  #end

end

#module HpricotTruncator
#  module NodeWithChildren
#    def truncate(max_length, ellipsis)
#      return self if inner_text.chars.length <= max_length
#      truncated_node = dup
#      truncated_node.name = name
#      truncated_node.raw_attributes = raw_attributes
#      truncated_node.children = []
#      each_child do |node|
#        break if max_length <= 0
#        node_length = node.inner_text.chars.length
#        truncated_node.children << node.truncate(max_length, ellipsis)
#        max_length = max_length - node_length
#      end
#      truncated_node
#    end
#  end
#
#  module TextNode
#    def truncate(max_length, ellipsis)
#      self.content = TextHelper.truncate_at_space(content, max_length, ellipsis)
#      self
#    end
#  end
#
#  module IgnoredTag
#    def truncate(max_length, ellipsis)
#      self
#    end
#  end
#end
#
#Hpricot::Doc.send(:include,       HpricotTruncator::NodeWithChildren)
#Hpricot::Elem.send(:include,      HpricotTruncator::NodeWithChildren)
#Hpricot::Text.send(:include,      HpricotTruncator::TextNode)
#Hpricot::BogusETag.send(:include, HpricotTruncator::IgnoredTag)
#Hpricot::Comment.send(:include,   HpricotTruncator::IgnoredTag)

