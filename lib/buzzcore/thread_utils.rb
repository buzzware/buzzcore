#require 'monitor'
require 'timeout'
require 'tmpdir'
require 'fileutils'
require 'thread'
require 'fastthread'

# 	# This class provides an object value that can be passed between threads without
# 	# fear of collisions. As WaitOne is used, multiple consumers could wait on one producer,
# 	# and only one consumer would get each produced value.
# 	# Reading it will block until it is written to. Writing will block until the last
# 	# written value is read. Therefore, it acts like a blocking queue with a fixed
# 	# maximum length of one. It currently doesn't support timeouts.
# 	# Reading or writing may raise a UnblockException when the thread is aborted
# 	# externally.
# 	class MultiThreadVariable {
#
# 		AutoResetEvent areWrite = new AutoResetEvent(true);
# 		AutoResetEvent areRead = new AutoResetEvent(false);
#
# 		def initialize
# 			@unblock = false
# 			@val = nil
# 			@mutex = Mutex.new
# 		end
#
# 		def value
# 			if (@unblock || !areRead.WaitOne())
# 				raise new UnblockException();
# 			@mutex.synchronize do
# 				object result = val;
# 				areWrite.Set();
# 				return result;
# 			end
# 		def value=
# 			if (@unblock || !areWrite.WaitOne())
# 				raise new UnblockException();
# 			@mutex.synchronize do
# 				val = value;
# 				areRead.Set();
# 			end
# 		end
#
#     #Call this when shutting down to break any existing block and prevent any future blocks
# 		def unblock()
# 			@unblock = true;
# 			areWrite.Set();
# 			areRead.Set();
# 		end
# 	end


# class MultiThreadVariableMonitor
#
# 	include MonitorMixin
#
# 	class UnblockError < StandardError; end
# 	class TimeoutError < StandardError; end
# 	class LockFailedError < StandardError; end
#
# 	def initialize(aTimeout=nil)
# 		mon_initialize()
# 		@value = nil
# 		@unblock = false
# 		@timeout = aTimeout
# 		@readable = new_cond
# 		@writable = new_cond
# 		@is_first_write = true
# 	end
#
# 	def value
# 		raise UnblockError.new if @unblock
# 		mon_synchronize do
# 			raise TimeoutError.new if not @readable.wait(@timeout)
# 			result = @value
# 			@writable.signal
# 		end
# 		return result
# 	end
#
# 	def value=(v)
# 		raise UnblockError.new if @unblock
# 		mon_synchronize do
# 			if @is_first_write
# 				@is_first_write = false
# 			else
# 				raise TimeoutError.new if not @writable.wait(@timeout)
# 			end
# 			@value = v
# 			@readable.signal
# 		end
# 		return v
# 	end
#
# 	def unblock()
# 		@unblock = true;
# 		@readable.broadcast
# 		@writable.broadcast
# 		while @readable.count_waiters()>0 or @writable.count_waiters()>0 do
# 			sleep(1)
# 		end
# 	end
# end

class UnblockError < StandardError; end

SizedQueue.class_eval do
  def unblock
		@unblock = true
		Thread.exclusive do 
			if @queue_wait
				while t = @queue_wait.shift do
					t.raise(UnblockError.new) unless t == Thread.current
				end
			end
			if @waiting
				while t = @waiting.shift do
					t.raise(UnblockError.new) unless t == Thread.current
				end
			end
		end
  end

	alias original_push push
	def push(obj)
		raise UnblockError.new if @unblock
		original_push(obj)
	end
	
	alias original_pop pop
  def pop(*args)
		raise UnblockError.new if @unblock
		original_pop(*args)
	end
	
end

# BEGIN
# $Id: semaphore.rb,v 1.2 2003/03/15 20:10:10 fukumoto Exp $
class CountingSemaphore

  def initialize(initvalue = 0)
    @counter = initvalue
    @waiting_list = []
  end

  def wait
    Thread.critical = true
    if (@counter -= 1) < 0
      @waiting_list.push(Thread.current)
      Thread.stop
    end
    self
  ensure
    Thread.critical = false
  end

  def signal
    Thread.critical = true
    begin
      if (@counter += 1) <= 0
	t = @waiting_list.shift
	t.wakeup if t
      end
    rescue ThreadError
      retry
    end
    self
  ensure
    Thread.critical = false
  end

  alias down wait
  alias up signal
  alias P wait
  alias V signal

  def exclusive
    wait
    yield
  ensure
    signal
  end

  alias synchronize exclusive

end

Semaphore = CountingSemaphore
# END


class MultiThreadVariable

	attr_accessor :read_timeout, :write_timeout

	def initialize(aReadTimeout=nil,aWriteTimeout=nil)
		@q = SizedQueue.new(1)
		@read_timeout = aReadTimeout
		@write_timeout = aWriteTimeout
	end

	def clear
		@q.clear
	end

	def empty?
		@q.empty?
	end

	def value
		if @read_timeout
			Timeout.timeout(@read_timeout) do
				@q.pop
			end
		else
			@q.pop
		end
	end

	def inner_value_set(aValue)
		Thread.exclusive do
			if @reject_next
				clear
			else
				@q.push(aValue)
			end
		end
	end

	def value=(aValue)
		if @write_timeout
			Timeout.timeout(@write_timeout) { inner_value_set(aValue) }
		else
			inner_value_set(aValue)
		end
		aValue
	end

	def unblock()
		@q.unblock()
	end

	def reject_value
		Thread.exclusive do
			if !empty?
				clear
			else
				@reject_next = true
			end
		end
	end


end

class MonitorVariable

	def initialize(aMonitor)
		@monitor = aMonitor
		@cvRead = @monitor.new_cond
		@cvWrite = @monitor.new_cond
		@empty = true
	end

	def value
		@monitor.synchronize do
			while empty?
				@cvRead.wait(@timeout)
			end
			result = @value
			@value = nil
			@empty = true
			@cvWrite.signal
			result
		end
	end

	def value=(aValue)
		@monitor.synchronize do 
			until empty?
				@cvWrite.wait(@timeout)
			end
			if @reject_next
				clear
			else
				@value = aValue
				@empty = false
				@cvRead.signal
			end
			aValue
		end
	end

	def empty?
		@empty
	end

	def clear
		@monitor.synchronize do 
			@value = nil
			@empty = true
			@cvWrite.signal
		end
	end

	def reject_value
		@monitor.synchronize do 
			if !empty?
				clear
			else
				@reject_next = true
			end
		end
	end
end


# This module decouples multiple master threads from multiple slave (worker) threads
# It provides two main methods :
# + master_attempt_command to be called by multiple clients with a command, returning a result or rasing an exception
# + slave_do_command to be called by worker threads with a block which processes the command.
# 
# see ProviderWorker in pay_server/app/pay_server.rb
module MasterSlaveSynchroniserMixin

  def logger
    @logger || (@logger = Logger.new(STDERR))
  end

	def ms_synchronizer_initialize(aTimeout=nil,aLogger=nil)
		@logger = aLogger
		@semaphore = CountingSemaphore.new(1)
		timeout = aTimeout && aTimeout/2.0
		@mvCommand = MultiThreadVariable.new(nil,timeout)
		@mvResponse = MultiThreadVariable.new(timeout,nil)
	end

	def master_attempt_command(aCommand)
		@semaphore.exclusive do
			command_sent = false
			begin
				before = Time.now
				logger.debug { "master sending aCommand:"+aCommand.inspect }
				@mvCommand.value = aCommand
				command_sent = true
				logger.debug { "master waiting for result" }
				result = @mvResponse.value
				logger.debug { "master received result:"+result.inspect }
			rescue Exception => e
				# exception causes thread critical status to be lost
				logger.debug { "master exception:"+e.inspect }
				if command_sent
					logger.debug { "rejecting" }
					@mvResponse.reject_value		#!!! this doesn't seem to return
				end
				raise e
			ensure
				logger.debug { "master_attempt_command: command_sent=#{command_sent.to_s} elapsed:"+(Time.now-before).to_s }
			end
			result
		end
	end

	def slave_do_command(&block)
		Thread.exclusive do
			logger.debug { "slave waiting for command" }
			command = @mvCommand.value
			logger.debug { "slave received command:"+command.inspect }
			result = yield(command)
			logger.debug { "slave sending result:"+result.inspect }
			@mvResponse.value = result
			logger.debug { "slave finished" }
			result
		end
	end

	def shutdown
		@mvCommand.unblock()
		@mvResponse.unblock()
	end
end

class MasterSlaveSynchroniser
	include MasterSlaveSynchroniserMixin

  def initialize(aTimeout=nil,aLogger=nil)
    ms_synchronizer_initialize(aTimeout,aLogger)
  end
end



module Worker

	module PidFile
		def self.store(aFilename, aPID)
			File.open(aFilename, 'w') {|f| f << aPID}
		end
    
		def self.recall(aFilename)
			IO.read(aFilename).to_i rescue nil
		end
	end

	class Base
		TempDirectory = Dir.tmpdir

		def self.pid_filename
			File.join(TempDirectory, "#{name}.pid")
		end

		def logger
			if not @logger
				@logger = Logger.new(STDERR)
				@logger.level = Logger::DEBUG
			end
			@logger
		end

		def main_proc
			begin
				@is_stopped = false
				@is_started = false
				self.starting()
				@is_started = true
				@is_stopping = false
				while !@is_stopping do
					running();
					logger.debug { "ServiceThread running loop: @is_stopping="+@is_stopping.to_s }
				end
			rescue SystemExit => e  # smother and do nothing
			rescue Exception => e
				logger.warn { "Thread #{@name} #{e.inspect} exception in Starting() or Running()" }
				logger.warn { e.backtrace       }
			ensure
				@is_stopping = true
			end
	
			begin
				stopping()
			rescue Exception => e
				logger.warn { "Thread #{@name} #{e.inspect} exception in stopping()" }
				logger.warn { e.backtrace       }
			end
			logger.info { "Thread #{@name} dropped out"  }
			@is_stopped = true
		end

		def wait_for_started(aTimeout)
			before = Time.now
			while !@is_started and (Time.now-before) < aTimeout
				sleep(aTimeout / 10)
			end
			raise Timeout::Error.new("failed to start within timeout (#{aTimeout.to_s})") if !@is_started
		end

		def wait_for_stopped(aTimeout)
			before = Time.now
			while !@is_stopped and (Time.now-before) < aTimeout
				sleep(aTimeout / 10)
			end
			raise Timeout::Error.new("failed to stop within timeout (#{aTimeout.to_s})") if !@is_stopped
		end

		def stop
			@is_stopping = true
		end

		def starting
		end
	
		def running
		end
	
		def stopping
		end
	end


	class Threader

		attr_reader :worker,:thread

		def self.start_new(aWorkerClass,aTimeout=0.1,&aCreateBlock)
			threader = Threader.new(aWorkerClass,&aCreateBlock)
			threader.start(aTimeout)
			return threader
		end

		def initialize(aWorkerClass,&aCreateBlock)
			@create_proc = aCreateBlock
			@worker_class = aWorkerClass
			if @create_proc
				@worker = @create_proc.call(@worker_class)
			else
				@worker = @worker_class.new
			end
		end

		def start(aTimeout=0.1)
			@thread = Thread.new(@worker) { |aWorker| aWorker.main_proc }
			@worker.wait_for_started(aTimeout)
		end

		def stop(aTimeout=0.1)
			@worker.stop
			@worker.wait_for_stopped(aTimeout)
			@thread.exit unless !@thread or (@thread.join(0) and not @thread.alive?)
			#@thread.join()
			@worker = nil
			@thread = nil
		end
	end

	module Daemonizer

		# Assists in making a daemon script from a Worker. If a block is given, it is assumed to create the worker and return it.
		# Otherwise the Worker is created with no arguments from aWorkerClass
		# Either way, the worker is only created when starting
		def self.daemonize(aWorkerClass,aConfig={})
			case !ARGV.empty? && ARGV[0]
			when 'start'
				worker = block_given? ? yield(aWorkerClass) : aWorkerClass.new
				if aConfig['no_fork']
					start_no_fork(worker)	
				else
					start(worker)
				end
			when 'stop'
				stop(aWorkerClass)
			when 'restart'
				stop(aWorkerClass)
				worker = block_given? ? yield(aWorkerClass) : aWorkerClass.new
				start(worker)
			else
				puts "Invalid command. Please specify start, stop or restart."
				exit
			end
		end

		def self.start_no_fork(aWorker)
			PidFile.store(aWorker.class.pid_filename, Process.pid)
			Dir.chdir(aWorker.class::TempDirectory)
			trap('TERM') do 
				begin
					puts "Daemonizer::start_no_fork TERM"
					#puts aWorker.inspect
					aWorker.stop
					puts "after worker stop"
					aWorker.wait_for_stopped()
					puts "after worker stop wait"
				rescue Exception => e
					puts "Exception: "+e.inspect
				end
				exit
			end
			trap('HUP','IGNORE') unless is_windows?	# ignore SIGHUP - required for Capistrano
			aWorker.main_proc
		end

		def self.start(aWorker)
			fork do
				Process.setsid
				if child_pid = fork
					Process.detach(child_pid)
				else
					PidFile.store(aWorker.class.pid_filename, Process.pid)
					Dir.chdir(aWorker.class::TempDirectory)
					File.umask 0000
					STDIN.reopen "/dev/null"
					STDOUT.reopen "/dev/null", "a" # problems here
					STDERR.reopen STDOUT
					trap('TERM') do 
						puts "Daemonizer::start TERM"
						aWorker.stop
						aWorker.wait_for_stopped()
						exit
					end
					trap('HUP','IGNORE')	# ignore SIGHUP - required for Capistrano
					aWorker.main_proc
				end
			end
		end
  
		def self.stop(aWorkerClass)
			if !File.file?(aWorkerClass.pid_filename)
				puts "Pid file not found. Is the aWorker started?"
				exit
			end
			pid = PidFile.recall(aWorkerClass.pid_filename)
			pid && Process.kill("TERM", pid)
			FileUtils.rm(aWorkerClass.pid_filename)
		end
	end
end


# How to use :
#
#	class Worker < ServiceThread
#		def initialize
#			super(:name => 'worker',:auto_start => true)
#		end
#
# 	def starting
#			# startup code
# 	end
#
# 	def running
#			# repeated code, implicitly looped. set self.stopping = true to quit thread
# 	end
#
# 	def stopping
#			# clean up code
# 	end
#	end
#
# @worker = Worker.new
# logger.info "worker #{@worker.is_started ? 'has':'hasn''t'} started and {@worker.is_stopped ? 'has':'hasn''t'} stopped"
# @worker.stop
#
class ServiceThread

	attr_accessor :name, :logger, :is_stopping
	attr_reader :is_stopped, :is_started, :options

	def random_word(min,max)
		len = min + rand(max-min+1)
		result = ' '*len
		(len-1).downto(0) {|i| result[i] = (?a + rand(?z-?a+1)).chr}
		return result
	end

	# if inheriting from ServiceThread and overriding initialize, remember to call super(aOptions) and that
	# this method may start the thread, so any setup must be done before super, not after
	def initialize(aOptions)
		@options = aOptions
		@thread = nil
		@name = aOptions[:name] || random_word(8,8)
		if not @logger = aOptions[:logger]
			@logger = Logger.new(STDERR)
			@logger.level = Logger::DEBUG
		end
		self.start() if aOptions[:auto_start]
	end

	def start
		raise Exception.new("ServiceThread already started") if @thread
		@thread = Thread.new() { main_proc() }
		#Thread.pass unless @is_started or @is_stopped		# no timeout !
	end

	def name
		@name
	end

	def logger
		@logger
	end


	def main_proc
		begin
			@is_stopped = false
			@is_started = false
			self.starting()
			@is_started = true
			@is_stopping = false
			while !@is_stopping do
				running();
				logger.debug { "ServiceThread running loop: @is_stopping="+@is_stopping.to_s }
			end
		rescue Exception => e
			@is_stopping = true
			logger.warn { "Thread #{@name} #{e.inspect} exception in Starting() or Running()" }
      logger.warn { e.backtrace       }
		end

		begin
			stopping()
		rescue Exception => e
			logger.warn { "Thread #{@name} #{e.inspect} exception in stopping()" }
      logger.warn { e.backtrace       }
		end
		logger.info { "Thread #{@name} dropped out"  }
		@is_stopped = true
	end

	def starting
	end

	def running
	end

	def stopping
	end

	def gentle_stop
		@is_stopping = true
	end

	def stop
		@is_stopping = true
		@thread.exit unless !@thread or (@thread.join(0) and not @thread.alive?)
	end
	
end

