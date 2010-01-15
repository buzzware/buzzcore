gem 'nokogiri'; require 'nokogiri'
require 'buzzcore/misc_utils'

module XmlUtils2

	BASIC_HEADER = '<?xml version="1.0"?>'

	# for yore, need to convert
	# XmlUtils.add_xml_from_string	: node
	# XmlUtils.get_file_root	: node
	# XmlUtils.read_simple_items	: hash
	# XmlUtils.single_node : node
	# XmlUtils.peek_node_value : String

	def self.clean_data(aXmlString)
		doc = Nokogiri::XML(aXmlString) {|c| c.options ||= Nokogiri::XML::ParseOptions.NOBLANKS}
		doc.traverse do |n| 
			case 
				when n.is_a?(Nokogiri::XML::Comment)
					n.remove
				when n.is_a?(Nokogiri::XML::Text)
					n.remove if (n.next || n.previous) && n.content.strip.empty?
			end
		end
		doc.to_xml(:indent => 0)
	end

end

