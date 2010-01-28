require 'net/http'
require 'rexml/document'
require 'rexml/xpath'
require 'buzzcore/misc_utils'

module XmlUtils

	BASIC_HEADER = '<?xml version="1.0"?>'

  def self.get_url_root(url)
    xml = Net::HTTP.get(URI(url))
    return nil if !xml
    xdoc = REXML::Document.new(xml)
    return nil if !xdoc
    root = xdoc.root
  end

  def self.get_xml_root(xml)
    xdoc = REXML::Document.new(xml)
    return nil if !xdoc
    root = xdoc.root
  end
	
	def self.get_file_root(aFilename)
		return nil unless File.exists?(aFilename)
		get_xml_root(MiscUtils.string_from_file(aFilename))
  end

  def self.single_node(node,xpath,default=nil)
    return default if node.nil? || xpath.nil? || xpath==''
    val = REXML::XPath.first(node,xpath)
    return val.nil? ? default : val
  end

  def self.peek_node(node,xpath,default=nil)
    return default if node.nil? || xpath.nil? || xpath==''
    val = REXML::XPath.first(node,xpath)
    return val.nil? ? default : val.to_s
  end

  def self.peek_node_value(aNode,aXPath,aDefault=nil)
		node = single_node(aNode,aXPath)
		return node.to_s if node.is_a?(REXML::Attribute)
		return node.nil? ? aDefault : node.text()
	end

	# convert <root><a>one</a><b>two</b></root> to {'a' => 'one', 'b' => 'two'}
	def self.hash_from_elements(aXMLRoot)
		result = {}
		aXMLRoot.elements.each{|e| result[e.name] = e.text}
		return result
	end

	# given '<tag a="1" b="2">textblah</tag>' returns {:name=>"tag", :text=>"textblah", "a"=>"1", "b"=>"2"}
	def self.hash_from_tag(aTagString)
		result = {}
		tag = get_xml_root(aTagString)
		return nil if !tag
		tag.attributes.each_attribute {|attr| result[attr.expanded_name]  = attr.value }
		result[:name] = tag.name
		result[:text] = tag.text if tag.text
		return result
	end

	# given {:name=>"tag", :text=>"textblah", "a"=>"1", "b"=>"2"} returns '<tag a="1" b="2">textblah</tag>'
	def self.tag_from_hash(aHash,aName=nil,aText=nil)
		aName ||= aHash[:name]
		aText ||= aHash[:text]
		result = "<#{aName}"
		aHash.each {|k,v| result += " #{k}=\"#{encode(v.to_s)}\"" if k.is_a? String}
		result += aText ? " >#{aText}</#{aName}>" : " />"
	end

	# returns first node added
	def self.add_xml_from_string(aString,aNode)
		return nil unless xdoc = REXML::Document.new('<?xml version="1.0" encoding="UTF-8"?><root>'+aString+'</root>')
		result = nil
		r = xdoc.root
		while r.has_elements? do
			e = r.delete_element(1)
			result = e unless result 
			e.parent = nil
			aNode.add_element(e)
		end
		return result
	end

	def self.hash_to_xml(aHash,aRootName,aDocHeader=true)
    xdoc = REXML::Document.new(BASIC_HEADER)
		root = xdoc.add_element(aRootName)
		aHash.each do |n,v| 
			root.add_element(n).add_text(v)
		end
		return xdoc
	end

	def self.read_simple_items(aRoot,aParentXPath=nil)
		result = {}
		xp = aParentXPath ? File.join(aParentXPath,'Item') : 'Item'
		REXML::XPath.each(aRoot, xp) do |item|
			result[item.attribute('Name').to_s] = item.text
    end
		return result
	end

	def self.quick_write_simple_items(aHash,aParent)
		return "<#{aParent} />\n" if !aHash || aHash.empty?
		result = "<#{aParent}>\n"
		aHash.each {|key,value| result += "\t<Item Name=\"#{key.to_s}\">#{value.to_s}</Item>\n" }
		result += "<#{aParent}/>\n"
		return result
	end

	# reads the simple items format given either a filename or xml node
	def self.read_config_values(aXmlConfig)
		xmlRoot = aXmlConfig.is_a?(REXML::Element) ? aXmlConfig : get_file_root(aXmlConfig)
		return read_simple_items(xmlRoot,'SimpleItems')
  end

	# Takes a node or xml string and writes it out formatted nicely.
	# aOutput may be given eg. a stream or nil can be given to get a returned string
	def self.format_nicely(aXml,aOutput=nil)
		aXml = REXML::Document.new(aXml) unless aXml.is_a?(REXML::Element)
		f = REXML::Formatters::Pretty.new(2,true)
		f.compact = true
		f.width = 120
		aOutput ||= ''
		f.write(aXml,aOutput)
		return aOutput
	end

	def self.encode(aString)
		result = aString.clone;
		result.gsub!('&','&amp;')
		result.gsub!('<','&lt;')
		result.gsub!('>','&gt;')
		result.gsub!('"','&quot;')
		result.gsub!("'",'&apos;')
		result.gsub!(/[\x80-\xFF]/) {|c| "&#x#{'%X' % c[0]};"}
		return result
	end
	
	def self.hash_to_deflist(aHash,aBuilder=nil)
		aBuilder ||= Builder::XmlMarkup.new(:indent => 2)
		aBuilder.dl do
			aHash.each do |k,v|
				aBuilder.dt(k.to_s)
				aBuilder.dd(v.to_s)
			end
		end		
	end
	
	def self.data_to_table(aRowHashes,aCaption=nil,aColNames=nil,aBuilder=nil)
		aBuilder ||= Builder::XmlMarkup.new(:indent => 2)
		aBuilder.table do
			if aCaption.is_a? String
				aBuilder.caption(aCaption)
			elsif aCaption.is_a? Hash
				aBuilder.caption do
					XmlUtils.hash_to_deflist(aCaption,aBuilder)
				end
			end
			aColNames ||= aRowHashes.first.keys
			aBuilder.thead do
				aBuilder.tr do
					aColNames.each do |name|
						aBuilder.td(name.to_s)
					end
				end
			end
			aBuilder.tbody do
				aRowHashes.each do |row|
					aBuilder.tr do
						aColNames.each do |name|
							aBuilder.td(row[name].to_s)
						end
					end
				end
			end
		end
	end
	
	# given a tag string, extracts the contents of an attribute using only a regex
	def self.quick_att_from_tag(aTagStr,aAtt)
		aTagStr.scan(/#{aAtt}=['"](.*?)['"]/).flatten.pop
	end
	
	def self.quick_remove_att(aTagStr,aAtt)
		aTagStr.sub(/#{aAtt}=['"](.*?)['"]/,'')
	end

	def self.quick_append_att(aTagStr,aAtt,aValue)
		existing_content = quick_att_from_tag(aTagStr,aAtt).to_s
		quick_set_att(aTagStr,aAtt,existing_content+aValue)
	end
	
	def self.quick_join_att(aTagStr,aAtt,aValue,aSep=';')
		existing_content = quick_att_from_tag(aTagStr,aAtt).to_s.split(aSep)
		existing_content += aValue.to_s.split(aSep)
		quick_set_att(aTagStr,aAtt,existing_content.join(aSep))
	end	
	
	def self.quick_add_att(aTagStr,aAtt,aValue)
		# replace first > or /> with att + ending
		aTagStr.sub(/(>|\/>)/," #{aAtt}=\"#{aValue}\""+' \1')
	end	
	
	def self.quick_set_att(aTagStr,aAtt,aValue)
		result = quick_remove_att(aTagStr,aAtt)
		quick_add_att(result,aAtt,aValue)
	end

end

