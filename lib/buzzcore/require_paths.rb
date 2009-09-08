# This sorts out the issues of require'ing files in Ruby
#	1) on one line, you specify all the paths you need
# 2) Relative paths will be relative to the file you are in, absolute paths also supported
# 3) Paths will be expanded
# 4) Paths will only be added if they don't already exist
# 
module ::Kernel
	def require_paths(*aArgs)
	  caller_dir = File.dirname(File.expand_path(caller.first.sub(/:[0-9]+.*/,'')))
		aArgs.each do |aPath|
			aPath = File.expand_path(aPath,caller_dir)
			$LOAD_PATH << aPath unless $LOAD_PATH.include?(aPath)
		end
	end
end

