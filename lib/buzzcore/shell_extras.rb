gem 'POpen4'; require 'popen4'

module POpen4

	class ExecuteError < StandardError

		attr_reader :result #,:stderr,:stdout,:exitcode,:pid

    def initialize(aArg)
      if aArg.is_a? Hash
				msg = ([aArg[:stderr],aArg[:stdout],"Error #{aArg[:exitcode].to_s}"].find {|i| i && !i.empty?})
        super(msg)
        @result = aArg
      else
        super(aArg)
      end
    end
		
		def inspect
			"#{self.class.to_s}: #{@result.inspect}"
		end

	end
	
	def self.pump_thread(aIn,aOut)
		Thread.new do
			loop { aOut.puts aIn.gets }
		end
	end

	# Usage :
	# result = POpen4::shell('somebinary') do |r|   # block gives opportunity to adjust result, and avoid exception raised from non-zero exit codes
	# 	if r[:exitcode]==254		# eg. say this binary returns 254 to mean something special but not an error
	#     r[:stdout] = 'some correct output'
	#     r[:stderr] = ''
	#     r[:exitcode] = 0
	#   end
	# end
  #
  # OR
  #
  # result = POpen4::shell('somebinary');
  # puts result[:stdout]
	#
	# Giving aStdOut,aStdErr causes the command output to be connected to the given stream, and that stream to not be given in the result hash
	def self.shell(aCommand,aWorkingDir=nil,aTimeout=nil,aStdOut=nil,aStdErr=nil)
		raise ExecuteError.new('aWorkingDir doesnt exist') unless !aWorkingDir || File.exists?(aWorkingDir)
		orig_wd = Dir.getwd
		result = {:command => aCommand, :dir => (aWorkingDir || orig_wd)}
    status = nil
		begin
			Dir.chdir(aWorkingDir) if aWorkingDir
			Timeout.timeout(aTimeout,ExecuteError) do	# nil aTimeout will not time out
				status = POpen4::popen4(aCommand) do |stdout, stderr, stdin, pid|
					thrOut = aStdOut ? Thread.new { aStdOut.puts stdout.read } : nil
					thrErr = aStdErr ? Thread.new { aStdErr.puts stderr.read } : nil
					thrOut.join if thrOut
					thrErr.join if thrErr

					result[:stdout] = stdout.read unless aStdOut
					result[:stderr] = stderr.read unless aStdErr
					result[:pid] = pid
				end
			end
		ensure
			Dir.chdir(orig_wd)
		end
		result[:exitcode] = (status && status.exitstatus) || 1
		yield(result) if block_given?
		raise ExecuteError.new(result) if result[:exitcode] != 0
		return result
	end
	
	def self.shell_out(aCommand,aWorkingDir=nil,aTimeout=nil,&block)
		block_given? ? POpen4::shell(aCommand,aWorkingDir,aTimeout,STDOUT,STDERR,&block) : POpen4::shell(aCommand,aWorkingDir,aTimeout,STDOUT,STDERR)
	end

end

