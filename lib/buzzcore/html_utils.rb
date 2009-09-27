require 'net/http'
require 'buzzcore/misc_utils'
require 'buzzcore/xml_utils'

module HtmlUtils

	#browser-safe inline block
	INLINE_BLOCK_SAFE_STYLE = "display: -moz-inline-box; display: inline-block; zoom: 1; *display:inline"

	# see fixed_frame_image
	RIGID_CRR_BLOCK_STYLE = "margin: 0; padding: 0; position: relative; top: 0pt; left: 0pt; display: table-cell; vertical-align: middle; overflow: hidden"
	IMAGE_CRD_STYLE = "display: block; margin: auto; vertical-align: middle;"
	
	def self.fixed_frame_image(aImgTag,aFrameW,aFrameH,aImgW=nil,aImgH=nil)
		style = RIGID_CRR_BLOCK_STYLE+";width: #{aFrameW}px; height: #{aFrameH}px"
		result = "<div style=\"#{INLINE_BLOCK_SAFE_STYLE}\"><div style=\"#{style}\">"
		aImgTag = XmlUtils.quick_remove_att(aImgTag,'width') if aImgW
		aImgTag = XmlUtils.quick_remove_att(aImgTag,'height') if aImgH
		style = XmlUtils.quick_att_from_tag(aImgTag,'style').to_s
		style += IMAGE_CRD_STYLE
		style += ";width: #{aImgW}px; height: #{aImgH}px"
		aImgTag = XmlUtils.quick_set_att(aImgTag,'style',style)
		result << aImgTag
		result << "</div></div>"
		result
	end

end

