require 'logger'
require 'ihl_ruby/misc_utils'

class Logger
  attr_reader :logdev
end

module LogUtils

	# eg.
	# {
	# 	'destination' => 'STDERR|STDOUT|FILE',
	# 	'filename' => '/path/to/file.ext',
	# 	'level' => 'DEBUG|INFO|...',
	#
	# 	'age' = 'daily|weekly|monthly',
	# 	OR
	# 	'max_files' => 3,
	# 	'max_bytes' => 1024000
	# }
	def self.create_logger_from_config(aConfigHash)
		if not aConfigHash
			result = Logger.new(STDERR)
			result.level = Logger::INFO
			return result
		end
	
		result = nil
		case aConfigHash['destination']
			when 'STDERR' then
				result = Logger.new(STDERR)
			when 'STDOUT' then
				result = Logger.new(STDOUT)
			when 'FILE' then
        result = aConfigHash['age'] ?
          Logger.new(aConfigHash['filename'],aConfigHash['age']) :
          Logger.new(
            aConfigHash['filename'],
						(aConfigHash['max_files'] || 3).to_i,
						(aConfigHash['max_bytes'] || 1024000).to_i
					)
			else
				result = Logger.new(STDERR)
		end
    puts valstr = "Logger::#{(aConfigHash['level'] || 'INFO').upcase}"
		result.level = eval(valstr)
		return result
	end

	# use this to trunc a log file to 0 bytes
	def self.trunc(aFilename)
		f = File.open(aFilename, "w")
		f.close
	end

  class ReportFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
     "|%s %1s %s\n" % [(time.strftime('%H%M%S.')<<"%03d" % (time.usec/1000)),severity[0..0],msg2str(msg)]
    end
  end

  class Reporter < Logger
    def initialize(logdev)
      super(logdev)
    end

  end

  def self.create_reporter(aFilename=nil)
    aFilename ||= MiscUtils::temp_file()
    result = Logger.new(aFilename)
    result.formatter = ReportFormatter.new
    result
  end
end



class MultiLogger < Logger

  attr_reader :loggers

  def initialize(aLoggers)
    @loggers = aLoggers.is_a?(Array) ? aLoggers : [aLoggers]
  end

  def add(severity, message = nil, progname = nil, &block)
		return true if !@loggers
		severity ||= UNKNOWN
    @loggers.each do |lr|
      block_given? ? lr.add(severity,message,progname,&block) : lr.add(severity,message,progname)
    end
    true
  end
  alias log add

  def <<(msg)
    @loggers.each do |lr|
      lr << msg
    end
  end

  def close
    @loggers.each do |lr|
      lr.close
    end
  end

end

#DEBUG D
#INFO
#WARN ?
#ERROR !
#FATAL F
#UNKNOWN U

# Logger that mostly works like a STDOUT logger, except that warnings and above get sent to STDERR instead
class ConsoleLogger < Logger

  class ReportFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
     msg2str(msg)+"\n"
    end
  end

  def initialize(aErrLevel = Severity::WARN)
		super(STDOUT)
    self.formatter = ReportFormatter.new
		self.level = Severity::INFO
		self << "\n"
		@err_logger = Logger.new(STDERR)
		@err_level = aErrLevel
		@err_logger.formatter = ReportFormatter.new
  end

	alias_method :orig_add, :add
  def add(severity, message = nil, progname = nil, &block)	
		if severity >= @err_level
			block_given? ? @err_logger.add(severity,message,progname,&block) : @err_logger.add(severity,message,progname)
		else
			block_given? ? orig_add(severity,message,progname,&block) : orig_add(severity,message,progname)
		end
  end
  alias log add

  #
  # Close the logging device.
  #
  def close
		begin
			@logdev.close if @logdev
		ensure
			@err_logger.close
		end
  end
	
end

