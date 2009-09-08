module Kernel
  # simple (sequential) enumerated values
  # usage :
  # 
  # module Constants
  #   module Gradient
  #     enum :B, :A, :C
  #   end
  # end
  #
  # then :
  #
  # puts Constants::Gradient::B -> 0
  # puts Constants::Gradient::C -> 2
  # puts Constants::Gradient::MINVALUE -> 0
  # puts Constants::Gradient::MAXVALUE -> 2
  # puts Constants::Gradient::NAMES -> [:B, :A, :C]
  # puts Constants::Gradient[0] -> :B
  # puts Constants::Gradient[1] -> :A
  # puts Constants::Gradient[2] -> :C
  
  def enum(*syms)
    syms.each_index { |i| 
      const_set(syms[i], i) 
    }
    const_set(:NAMES, syms || []) 
    const_set(:MINVALUE, syms==nil ? nil : 0) 
    const_set(:MAXVALUE, syms==nil ? nil : syms.length-1) 
    const_set(:VALUECOUNT, syms==nil ? nil : syms.length) 
    const_set(:ALL, syms==nil ? [] : (0..syms.length-1).to_a) 
    const_set(:HUMAN_NAMES, syms.map{|n| n.to_s.humanize} || []) 

    # this returns the enum name given the value
    def self.[]( idx )
      (idx.is_a? Integer) ? const_get(:NAMES)[idx] : nil
    end

    def self.valid?(idx)
      (idx.is_a? Integer) && (idx >= 0) && (idx <= const_get(:MAXVALUE))
    end

    def self.parse(name,default=nil)
      return default if name.nil? || name.empty?
			return default if not name = name.to_sym
      result = const_get(:NAMES).index(name)
      return result==nil ? default : result
    end
  end
end

