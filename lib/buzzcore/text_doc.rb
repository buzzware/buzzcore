# represents a mono-spaced text document with a given width and expandable height.
class TextDoc

  attr_reader :width, :height, :lines

  def logger
    RAILS_DEFAULT_LOGGER
  end

  def initialize(aWidth=80,aHeight=66)
    @width = aWidth
    @height = aHeight
  
    @lines = Array.new(@height)
    line_str = ' '*@width
    @lines.collect!{|line| line_str.clone }
  end

  def replace_string(aString,aCol,aSubString)
    return aString if aSubString==nil || aSubString==''

    aSubString = aSubString.to_s
    start_col = aCol < 0 ? 0 : aCol
    end_col = aCol+aSubString.length-1
    end_col = @width-1 if end_col >= @width
    source_len = end_col-start_col+1
    return aString if source_len <= 0 || end_col < 0 || start_col >= @width
    aString += ' '*((end_col+1) - aString.length) if aString.length < end_col+1
    aString[start_col,source_len] = aSubString[start_col-aCol,end_col-start_col+1]
    return aString
  end

  def replace(aCol,aLine,aString)
    return if (aLine < 0) || (aLine>=@lines.length)
    replace_string(@lines[aLine],aCol,aString)
  end

  def replace_block(aCol,aLine,aLines)
    aLines = aLines.split(/\n/) if aLines.is_a?(String)
    aLines = aLines.lines if aLines.is_a?(TextDoc)
  
    aLines.each_index do |iSource|
      replace(aCol,aLine+iSource,aLines[iSource])
    end
  end

  def add_block(aLines,aCol=0)
    aLines = aLines.split(/\n/) if aLines.is_a?(String)
    aLines = aLines.lines if aLines.is_a?(TextDoc)
    aLines.each_index do |iSource|
      @lines << ' '*@width
      replace(aCol,@lines.length-1,aLines[iSource])
    end
  end

  def add_line(aLine=nil,aCol=0)
    @lines << ' '*@width and return if !aLine
    @lines << ' '*@width
    replace(aCol,@lines.length-1,aLine)
  end

  def centre_bar(aChar = '-', indent = 6)
    (' '*indent) + aChar*(@width-(indent*2)) + (' '*indent)
  end

  def to_s
    return @lines.join("\n")
  end
end

