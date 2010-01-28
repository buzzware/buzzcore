require 'tmpdir'
require 'logger'
require 'pathname'

require 'buzzcore/logging'

module MiscUtils

	def self.logger
		@logger || @logger = Logger.new(STDERR)
	end

	# applies the given block to key/value pairs included/excluded by the given parameters
	# aSource must be a hash, and may contain hashes which will be recursively processed.
	# aInclude/aExclude may be nil, an array of selected keys, or a hash containing arrays of keys for inner hashes of aSource
	# When aInclude/aExclude are a hash, non-hash source values may be selected by passing a value of true. Hash source values 
	# will be selected as a whole (all keys) when true is passed.
	# input = { 'a' => 1, 'b' => {'x' => 9, 'y' => 8}, 'c' => 3 }
	# filter_multilevel_hash(input,['a','b'],{'b'=>['y']}) {|h,k,v| h[k] = true}
	# input now = { 'a' => true, 'b' => {'x' => true, 'y' => 8}, 'c' => 3 }
	def self.filter_multilevel_hash(aSource,aInclude=nil,aExclude=nil,&block)
		aSource.each do |key,value|
			next if aInclude.is_a?(Array) and !aInclude.include?(key)		# skip if not in aInclude array
			next if aExclude.is_a?(Array) and aExclude.include?(key)		# skip if in aExclude array
			next if aExclude.is_a?(Hash) and aExclude[key]==true				# skip if in aExclude hash with value=true
			next if aInclude.is_a?(Hash) and !aInclude.include?(key)		# skip if not in aInclude hash at all
			if value.is_a?(Hash)																				# value is hash so recursively apply filter 
				filter_multilevel_hash(
					value,
					aInclude.is_a?(Hash) && (f = aInclude[key]) ? f : nil,	# pass include array if provided for key
					aExclude.is_a?(Hash) && (f = aExclude[key]) ? f : nil,	# pass exclude array if provided for key
					&block
				)
			else
				yield(aSource,key,value)
			end
		end
	end

	# returns output string if succesful, or integer return code if not, or nil
	def self.execute(aCommand,aWorkingDir=nil,aTimeout=nil,aTimeoutClass=nil)
		return nil unless !aWorkingDir || File.exists?(aWorkingDir)
		begin
			orig_wd = Dir.getwd
			pipe = nil
			result = nil
			Dir.chdir(aWorkingDir) if aWorkingDir
			Timeout.timeout(aTimeout,aTimeoutClass || Timeout::Error) do	# nil aTimeout will not time out
				pipe = IO.popen(aCommand)
				logger.debug "command PID:"+pipe.pid.to_s
				result = pipe.read
			end
		ensure
			pipe.close if pipe
			Dir.chdir(orig_wd)
		end
		return result
	end

	def self.execute_string(aCmdString,aWorkingDir=nil)
		result = nil
		begin
			orig_dir = Dir.pwd
			Dir.chdir(aWorkingDir) if aWorkingDir
			result = `#{aCmdString}`
		ensure
			Dir.chdir(orig_dir) if aWorkingDir
		end 
		return result
	end

	def self.temp_file(aExt=nil,aDir=nil)
		aExt ||= '.tmp'
		File.expand_path(("%08X" % rand(0x3FFFFFFF)) + aExt, aDir||Dir.tmpdir)
	end
	
	def self.make_temp_file(aName=nil,aDir=nil,aContent=nil)
		filename = aName ? File.expand_path(aName,aDir || Dir.tmpdir) : temp_file(nil,aDir)
    FileUtils.mkdir_p(File.dirname(filename))
		aContent ||= "content of "+filename
		string_to_file(aContent,filename)
    filename
	end

	def self.make_temp_dir(aPrefix='')
		new_dir = nil
    begin
			new_dir = File.join(Dir.tmpdir,aPrefix+("%08X" % rand(0x3FFFFFFF)))
		end until new_dir && !File.exists?(new_dir)
		Dir.mkdir new_dir
		return new_dir
	end
	
	def self.mkdir?(aPath,aPermissions)
		if File.exists?(aPath)
			File.chmod(aPermissions, aPath)
		else
			Dir.mkdir(aPath, aPermissions)
    end
  end

	def self.set_permissions_cmd(aFilepath,aUser=nil,aGroup=nil,aMode=nil,aSetGroupId=false,aSudo=true)
		cmd = []
		if aGroup
			cmd << (aUser ? "#{aSudo ? sudo : ''} chown #{aUser}:#{aGroup}" : "#{aSudo ? sudo : ''} chgrp #{aGroup}") + " #{aFilepath}"
		else	
			cmd << "#{aSudo ? sudo : ''} chown #{aUser} #{aFilepath}" if aUser
		end
		cmd << "#{aSudo ? sudo : ''} chmod #{aMode.to_s} #{aFilepath}" if aMode
		cmd << "#{aSudo ? sudo : ''} chmod g+s #{aFilepath}" if aSetGroupId
		cmd.join(' && ')
	end

	def self.string_to_file(aString,aFilename)
		File.open(aFilename,'wb') {|file| file.write aString }
	end

	def self.string_from_file(aFilename)
		result = nil
		File.open(aFilename, "rb") { |f| result = f.read }
		# return result && result[0..-2]  # quick hack to stop returning false \n at end UPDATE: this is causing problems now
	end

	def self.sniff_seperator(aPath)
		result = 0.upto(aPath.length-1) do |i|
			char = aPath[i,1]
			break char if char=='\\' || char=='/'
		end
		result = File::SEPARATOR if result==0
		return result
	end

	def self.append_slash(aPath,aSep=nil)
		aSep = sniff_seperator(aPath) unless aSep
		last_char = aPath[-1,1]
		aPath += aSep unless last_char=='\\' || last_char=='/'
		return aPath
	end

	def self.remove_slash(aPath)
		last_char = aPath[-1,1]
		aPath = aPath[0..-2] if last_char=='\\' || last_char=='/'
		return aPath
	end

	# Remove base dir from given path. Result will be relative to base dir and not have a leading or trailing slash
	#'/a/b/c','/a' = 'b/c'
	#'/a/b/c','/' = 'a/b/c'
	#'/','/' = ''
	def self.path_debase(aPath,aBase)
		aBase = MiscUtils::append_slash(aBase)
		aPath = MiscUtils::remove_slash(aPath) unless aPath=='/'
		aPath[0,aBase.length]==aBase ? aPath[aBase.length,aPath.length-aBase.length] : aPath
	end
	
	def self.path_rebase(aPath,aOldBase,aNewBase)
		rel_path = path_debase(aPath,aOldBase)
		append_slash(aNewBase)+rel_path
	end
	
	def self.path_combine(aBasePath,aPath)
		return aBasePath if !aPath
		return aPath if !aBasePath
		return path_relative?(aPath) ? File.join(aBasePath,aPath) : aPath	
	end
	
	# make path real according to file system
	def self.real_path(aPath)
		(path = Pathname.new(File.expand_path(aPath))) && path.realpath.to_s
	end

	# takes a path and combines it with a root path (which defaults to Dir.pwd) unless it is absolute
	# the final result is then expanded
	def self.canonize_path(aPath,aRootPath=nil)
		path = path_combine(aRootPath,aPath)
		path = real_path(path) if path
		path
	end
	
	def self.find_upwards(aStartPath,aPath)
		curr_path = File.expand_path(aStartPath)
		while curr_path && !(test_path_exists = File.exists?(test_path = File.join(curr_path,aPath))) do
			curr_path = MiscUtils.path_parent(curr_path)
		end
		curr_path && test_path_exists ? test_path : nil
	end


	# allows special symbols in path
	# currently only ... supported, which looks upward in the filesystem for the following relative path from the basepath
	def self.expand_magic_path(aPath,aBasePath=nil)
		aBasePath ||= Dir.pwd
		path = aPath
		if path.begins_with?('...')
			rel_part = StringUtils.split3(path,/\.\.\.[\/\\]/)[2]
			path = find_upwards(aBasePath,rel_part)
		end
	end

	def self.path_parent(aPath)
		return nil if is_root_path?(aPath)
		MiscUtils.append_slash(File.dirname(MiscUtils.remove_slash(File.expand_path(aPath))))
	end

	def self.simple_dir_name(aPath)
		File.basename(remove_slash(aPath))
	end

	def self.simple_file_name(aPath)
		f = File.basename(aPath)
		dot = f.index('.')
		return dot ? f[0,dot] : f
	end

	def self.path_parts(aPath)
		sep = sniff_seperator(aPath)
		aPath.split(sep)
	end

	def self.file_extension(aFile,aExtended=true)
		f = File.basename(aFile)
		dot = aExtended ? f.index('.') : f.rindex('.')
		return dot ? f[dot+1..-1] : f
	end

	def self.file_no_extension(aFile,aExtended=true)
		ext = file_extension(aFile,aExtended)
		return aFile.chomp('.'+ext)
	end

	def self.file_change_ext(aFile,aExt,aExtend=false)
		file_no_extension(aFile,false)+(aExtend ? '.'+aExt+'.'+file_extension(aFile,false) : '.'+aExt)
	end

	def self.platform
		RUBY_PLATFORM.scan(/-(.+)$/).flatten.first
	end

	def self.windows_path(aPath)
		aPath.gsub('/','\\')
	end

	def self.ruby_path(aPath)
		aPath.gsub('\\','/')
	end

	def self.is_uri?(aString)
		/^[a-zA-Z0-9+_]+\:\/\// =~ aString ? true : false
	end

	def self.is_root_path?(aPath)
		if is_windows?
			(aPath =~ /^[a-zA-Z]\:[\\\/]$/)==0
		else
			aPath == '/'
		end
	end

	def self.native_path(aPath)
		is_windows? ? windows_path(aPath) : ruby_path(aPath)
	end

	def self.path_relative?(aPath)
		return false if aPath[0,1]=='/'
		return false if aPath =~ /^[a-zA-Z]:/
		return true
	end

	def self.path_absolute?(aPath)
		!path_relative(aPath)
	end

	def self.is_windows?
		platform=='mswin32'
	end
	
	def self.get_files(aArray,aPath,aFullPath=true,aRootPath=nil,&block)
		#puts "get_files: aPath='#{aPath}'"
		if aRootPath
			abssrcpath = path_combine(aRootPath,aPath)
		else
			abssrcpath = aRootPath = aPath
			aPath = nil
		end
		return aArray if !File.exists?(abssrcpath)
		#abssrcpath is real path to query
		#aRootPath is highest level path
		#aPath is current path relative to aRootPath
		Dir.new(abssrcpath).to_a.each do |file|
			next if ['.','..'].include? file
			fullpath = File.join(abssrcpath,file)
			resultpath = aFullPath ? fullpath : path_combine(aPath,file)
			if !block_given? || yield(resultpath)
				if FileTest.directory?(fullpath)
					block_given? ? get_files(aArray,path_combine(aPath,file),aFullPath,aRootPath,&block) : get_files(aArray,path_combine(aPath,file),aFullPath,aRootPath)
				else
					aArray << resultpath
				end
			end
		end
		return aArray
	end

	def self.recursive_file_list(aPath,aFullPath=true,&block)
		block_given? ? get_files([],aPath,aFullPath,nil,&block) : get_files([],aPath,aFullPath)
  end
	
	# returns true if aPath1 and aPath2 are the same path (doesn't query file system)
	# both must be absolute or both relative
	def self.path_same(aPath1,aPath2)
		return nil unless path_relative?(aPath1) == path_relative?(aPath2)
		remove_slash(aPath1) == remove_slash(aPath2)
	end
	
	# returns true if aPath is under aPathParent
	# both must be absolute or both relative
	def self.path_ancestor(aPathParent,aPath)
		return nil unless path_relative?(aPathParent) == path_relative?(aPath)
		aPath.index(append_slash(aPathParent))==0
	end

	# returns the lowest path containing all files (assumes aFiles contains only absolute paths)
	def self.file_list_ancestor(aFiles)
    files = aFiles.is_a?(Hash) ? aFiles.keys : aFiles
		result = File.dirname(files.first)
		files.each do |fp|
			filedir = File.dirname(fp)
			while path_same(result,filedir)==false && path_ancestor(result,filedir)==false
				result = path_parent(result)
			end
		end		
		result
	end

	def self.path_match(aPath,aPatterns)
		aPatterns = [aPatterns] unless aPatterns.is_a? Array
		aPatterns.any? do |pat|
			case pat
				when String then aPath[0,pat.length] == pat
				when Regexp then aPath =~ pat
				else false
			end
		end
	end
	
	# for capistrano deployed paths
	# makes "/var/www/logikal.stage/releases/20090911073620/cms/config.xml" into "/var/www/logikal.stage/current/cms/config.xml"
	def self.neaten_cap_path(aPath)
		aPath.sub(/(\/releases\/[0-9]+\/)/,'/current/')
	end

	# takes a hash and returns a single closed tag containing the hash pairs as attributes, correctly encoded
	def self.hash_to_xml_tag(aName,aHash)
		atts = ''
		aHash.each do |k,v| 
			atts += ' ' + k.to_s + "=\"#{v.to_s.to_xs}\""
		end
		"<#{aName}#{atts}/>"		
	end

	def self.filelist_from_patterns(aPatterns,aBasePath)
		return [] unless aPatterns
		aPatterns = [aPatterns] unless aPatterns.is_a? Array

		aPatterns.map do |fp|
			fp = File.expand_path(fp,aBasePath)		# relative to rails root
			fp = FileList[fp] if fp['*'] || fp['?']
			fp
		end.flatten
	end

#:host
#:port
#:helodomain
#:user
#:password
#:from
#:from_alias
#:to
#:to_alias
#:subject
#:message
#:auth : 'plain', 'login', 'cram_md5'

	# send an email via an SMTP server
  def self.send_email(aArgs)
    msg = <<END_OF_MESSAGE
From: #{aArgs[:from_alias]} <#{aArgs[:from]}>
To: #{aArgs[:to_alias]} <#{aArgs[:to]}>
Subject: #{aArgs[:subject]}

#{aArgs[:message]}
END_OF_MESSAGE

    Net::SMTP.start(
			aArgs[:host],
			aArgs[:port],
			aArgs[:helodomain],
			aArgs[:user],
			aArgs[:password],
			aArgs[:auth]
		) do |smtp|
      smtp.send_message msg, aArgs[:from], aArgs[:to]
    end
  end

end

# include this at the top of a class to protect it from baddies.
# eg. 
# + nearly all ancestor public_instance_methods will be hidden
# + inspect will only return the class name
# + methods will return public methods
module SecureThisClass
	def self.hack(aClass,aOptions={})
		include_actions = (aOptions[:include] || aClass.public_instance_methods.clone)
		exclude_actions = ['class','public_methods'] | (aOptions[:exclude] || [])
		actions_to_hide = include_actions-exclude_actions
		aClass.class_eval do
			actions_to_hide.each { |m| protected m.to_sym }

			def inspect
				return self.class.name
			end

			def methods
				public_methods
			end
		end
	end
end


module ::Kernel
	def secure_class(aOptions={})
		SecureThisClass::hack(self,aOptions)
	end
end

