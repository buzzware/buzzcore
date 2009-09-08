require 'rubygems'
gem 'RequirePaths'; require 'require_paths'
require_paths '..'
require 'ihl_ruby/shell_extras'

module DatabaseUtils
  def self.execute_sql_file(filename,aUser=nil,aPassword=nil)
    conf = ActiveRecord::Base.configurations[RAILS_ENV]
    pw = aPassword || conf['password'].to_s || ''
    user = aUser || conf['username'].to_s || ''
    cmd_line = "mysql -h #{conf['host']} -D #{conf['database']} #{user.empty? ? '' : '-u '+user} #{pw.empty? ? '' : '-p'+pw} <#{filename}"
    if !system(cmd_line)
      raise Exception, "Error executing "+cmd_line
    end
  end
	
	## http://www.cyberciti.biz/faq/how-do-i-empty-mysql-database/
	#
	#
	## drop all tables :
	##			mysqldump -uusername -ppassword -hhost \
	##--add-drop-table --no-data database | grep ^DROP | \
	##mysql -uusername -ppassword -hhost database
	#

	def self.database_exists(aDbDetails,aDatabase=nil)
		aDbDetails[:database] = aDatabase if aDatabase
		return false if !aDbDetails[:database]
		response = POpen4::shell("mysql -u #{aDbDetails[:username]} -p#{aDbDetails[:password]} -e 'use #{aDbDetails[:database]}'") do |r|
			if r[:stderr] && r[:stderr].index("ERROR 1049 ")==0		# Unknown database
				r[:exitcode] = 0 
				return false
			end
		end
		return (response && response[:exitcode]==0)
	end

	def self.clear_database(aDbDetails)
		response = POpen4::shell("mysqldump -u #{aDbDetails[:username]} -p#{aDbDetails[:password]} --add-drop-table --no-data #{aDbDetails[:database]} | grep ^DROP | mysql -u #{aDbDetails[:username]} -p#{aDbDetails[:password]} #{aDbDetails[:database]}")
	end

	def self.create_database(aDbDetails,aDatabase=nil)
		aDbDetails[:database] = aDatabase if aDatabase
		return false if !aDbDetails[:database]
		response = POpen4::shell("mysqladmin -u #{aDbDetails[:username]} -p#{aDbDetails[:password]} create #{aDbDetails[:database]}")
	end

	def self.ensure_empty_database(aDbDetails,aDatabase=nil)
		aDbDetails[:database] = aDatabase if aDatabase
		if database_exists(aDbDetails)
			clear_database(aDbDetails)
		else
			create_database(aDbDetails)
		end
	end
	
	def self.load_database(aDbDetails,aSqlFile)
		ensure_empty_database(aDbDetails)
		response = POpen4::shell("mysql -u #{aDbDetails[:username]} -p#{aDbDetails[:password]} #{aDbDetails[:database]} < #{aSqlFile}")
	end

	def self.save_database(aDbDetails,aSqlFile)
		response = POpen4::shell("mysqldump --user=#{aDbDetails[:username]} --password=#{aDbDetails[:password]} --skip-extended-insert #{aDbDetails[:database]} > #{aSqlFile}")
	end

	#
	## eg. rake metas:spree:data:load from=/tmp/spree_data.tgz to=mysql:fresco_server_d:root:password
	#desc 'load spree data from a file'
	#task :load do
	#	from = ENV['from']
	#	to=ENV['to']
	#	db_server,db,user,password = to.split(':')
	#	tmpdir = make_temp_dir('metas')
	#	cmd = "tar -xvzf #{from} -C #{tmpdir}"
	#	puts CapUtilsClass.shell(cmd)
	#
	#	ensure_empty_database(db_server,db,user,password)
	#
	#	puts CapUtilsClass.shell("mysql -u #{user} -p#{password} #{db} < #{File.join(tmpdir,'db/dumps/db.sql')}")
	#	FileUtils.mkdir_p('public/assets')
	#	puts CapUtilsClass.shell("cp -rf #{File.join(tmpdir,'public/assets/products')} public/assets/products")
	#end




end


