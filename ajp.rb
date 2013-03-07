#!/usr/bin/env ruby

require 'yaml'
require 'sqlite3'
require 'csv'
require 'optparse'

require 'pp'

class Job

	attr_accessor :id, :name, :type, :box_name, :command, :machine, :owner, :permission, :date_condition, :days_of_week, :start_times, :condition, :description, :std_out_file, :std_err_file, :alarm_if_fail

	def initialize (id, name = '', type = '', box_name = '', command = '', machine = '', owner = '', permission = '', date_condition = 0, days_of_week = '', start_times = '', condition = '', description = '', std_out_file = '', std_err_file = '', alarm_if_fail = 0)
		@id				= id
		@name			= name
		@type			= type
		@box_name		= box_name
		@command		= command
		@machine		= machine
		@owner			= owner
		@permission		= permission
		@date_condition	= date_condition
		@days_of_week	= days_of_week
		@start_times	= start_times
		@condition		= condition
		@description	= description
		@std_out_file	= std_out_file
		@std_err_file	= std_err_file
		@alarm_if_fail	= alarm_if_fail
	end

	def to_s
	  job_type = (@type == 'c')?"Job":(@type == 'b')?"Box":(@type == 'f')?"Filewatcher":"Unknown Job Type"
	  "#{job_type} #{@name}\n" <<
		"\tID: #{@id}\n" << 
		"\tName: #{@name}\n" <<
		"\tType: #{@type}\n" <<
		"\tBox Name: #{@box_name}\n" <<
		"\tCommand: #{@command}\n" <<
		"\tMachine: #{@machine}\n" <<
		"\tOwner: #{@owner}\n" <<
		"\tPermission: #{@permission}\n" <<
		"\tDate Condition: #{@date_condition}\n" <<
		"\tDays of Week: #{@days_of_week}\n" <<
		"\tStart Times: #{@start_times}\n" <<
		"\tCondition: #{@condition}\n" <<
		"\tDescription: #{@description}\n" <<
		"\tSTDOUT File: #{@std_out_file}\n" <<
		"\tSTDERR File: #{@std_err_file}\n" <<
		"\tAlarm if Fails: #{@alarm_if_fail}\n"
	end
end

class Jobs

	def get_jobs_from_jil (filename)
		job = Job.new(1)
		id=2
		File.open(filename, "r").each_line do |line|
		
			line.chomp!
			
			if( /insert_job:/.match(line) and job.name != '' ) 
				@jobs.push(job)
				job = Job.new(id)
				id += 1
			end
			
			job.name          = $1 if /insert_job: (\w+)/.match(line)
			job.type 			    = $1 if /job_type: (\w+)/.match(line)
			job.box_name	    = $1 if /box_name: (\w+)/.match(line)
			job.command		    = $1 if /command: (.+)/.match(line)
			job.machine		    = $1 if /machine: (.+)/.match(line)
			job.owner			    = $1 if /owner: (.+)/.match(line)
			job.permission    = $1 if /permission: (.+)/.match(line)
			job.date_condition= $1 if /date_conditions: (.+)/.match(line)
			job.days_of_week	= $1 if /days_of_week: (.+)/.match(line)
			job.start_times		= $1 if /start_times: "(.+)"/.match(line)
			job.condition		  = $1 if /condition: (.+)/.match(line)
			job.description   = $1 if (/description: "(.*)"/).match(line)
			job.std_out_file	= $1 if /std_out_file: (.*)/.match(line)
			job.std_err_file	= $1 if /std_err_file: (.*)/.match(line)
			job.alarm_if_fail	= $1 if /alarm_if_fail: (.+)/.match(line)
			
		end
	end
	
	def get_jobs_from_db (database)
		begin
			db = SQLite3::Database.open database
			
			stm = db.prepare "SELECT * FROM Jobs"
			rs = stm.execute
			
			rs.each do |job|
				@jobs.push(Job.new(job[0], 
							job[1], 
							job[2], 
							job[3], 
							job[4], 
							job[5], 
							job[6], 
							job[7], 
							job[8], 
							job[9], 
							job[10], 
							job[11], 
							job[12], 
							job[13], 
							job[14], 
							job[15]))
			end
		rescue SQLite3::Exception => e
			puts "Exception occured getting the jobs"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def create_database (database)
	  begin
	    db = SQLite3::Database.open database
	    db.execute "CREATE TABLE IF NOT EXISTS Jobs (id             INTEGER PRIMARY KEY,
	                                                name            CHAR,
	                                                type            CHAR,
	                                                box_name        CHAR,
	                                                command         TEXT,
	                                                machine         CHAR,
	                                                owner           CHAR,
	                                                permission      CHAR,
	                                                date_condition  INTEGER,
	                                                days_of_week    CHAR,
	                                                start_times     TEXT,
	                                                condition       TEXT,
	                                                description     TEXT,
	                                                std_out_file    TEXT,
	                                                std_err_file    TEXT,
	                                                alarm_if_fail   INTEGER)"
                                                  
	    @jobs.each do |job|
	      insert_command = "INSERT INTO Jobs VALUES ( #{job.id}, " <<
	                                                  "'#{job.name}', " <<
	                                                  "'#{job.type}', " <<
	                                                  "'#{job.box_name}', " <<
	                                                  "'#{job.command}', " <<
	                                                  "'#{job.machine}', " <<
	                                                  "'#{job.owner}', " <<
	                                                  "'#{job.permission}', " <<
	                                                  "'#{job.date_condition}', " <<
	                                                  "'#{job.days_of_week}', " <<
	                                                  "'#{job.start_times}', " <<
	                                                  "'#{job.condition}', " <<
	                                                  "'#{job.description.gsub(/'/,"''")}', " <<
	                                                  "'#{job.std_out_file}', " <<
	                                                  "'#{job.std_err_file}', " <<
	                                                  "'#{job.alarm_if_fail}')"
	      db.execute insert_command
	    end
	  rescue SQLite3::Exception => e
	    puts "Exception updating the Database #{database}"
	    puts e
	  ensure
	    db.close if db
	  end
  end
	
	def initialize (refresh, jil_filename, database)
	  @jil  = jil_filename
	  @db   = database
	  @jobs = Array.new
	  
	  if(refresh)
		get_jobs_from_jil(jil_filename)
		
		File.delete(database) if File::exists?(database)
		create_database(database)
	  else
		get_jobs_from_db(database)
	  end
	end

	def to_yaml
	  yaml_output = ''
	  @jobs.each do |job|
	    yaml_output << job.to_yaml << "\n"
	  end
	  yaml_output
	end
	
	def to_s
	  s_output = ''
	  @jobs.each do |job|
	    s_output << job.to_s << "\n"
	  end
	  s_output
	end
	
	def to_csv
	  sort = 1
	  csv_output = CSV.generate do |csv|
	    csv << ["sort", "box id", "box name", "jobs inside", "job id", "job name", "type", "box_name", "command", "machine", "owner", "permission", "date_condition", "days_of_week", "start_times", "condition", "description", "std_out_file", "std_err_file", "alarm_if_fail"].map(&:capitalize)
	    @jobs.each do |job_box|
	      if (job_box.type == 'b')
	        rows = Array.new
	        head = [sort,
	                job_box.id,
                  job_box.name,
                  0,
                  job_box.id, 
	                job_box.name, 
	                job_box.type, 
	                job_box.box_name, 
	                job_box.command, 
	                '', 
	                job_box.owner, 
	                job_box.permission, 
	                job_box.date_condition, 
	                job_box.days_of_week, 
	                job_box.start_times, 
	                job_box.condition, 
	                job_box.description, 
	                job_box.std_out_file, 
	                job_box.std_err_file, 
	                job_box.alarm_if_fail]
          sort += 1
          count = 0
          machines = Array.new
	        @jobs.each do |job| 
	          if (job.box_name == job_box.name)
	            rows << [sort,
	                    job_box.id,
	                    job_box.name,
	                    '',
	                    job.id, 
    	                job.name, 
    	                job.type, 
    	                job.box_name, 
    	                job.command, 
    	                job.machine, 
    	                job.owner, 
    	                job.permission, 
    	                job.date_condition, 
    	                job.days_of_week, 
    	                job.start_times, 
    	                job.condition, 
    	                job.description, 
    	                job.std_out_file, 
    	                job.std_err_file, 
    	                job.alarm_if_fail
	             ]
	             sort += 1
	             count += 1
	             machines << job.machine
	          end # of if the job is inside the box
	        end # of jobs loop to find jobs inside the box
	        
	        head[3] = count
	        head[9] = machines.uniq.sort.join(", ")
	        
	        csv << head
	        rows.each do |r|
	          csv << r
	        end
	        
	      end # of the box found
	    end # of jobs loop to find boxes
	  end # of CSV
  end # of def to_csv
  
  def to_file (format, filename)
	file = File.new(filename, 'w')
	file.syswrite(self.send(format))
	file.close unless file == nil
  end
  
end

class User
	attr_accessors :id, :name, :email
	
	def initialize (id, name, email)
		@id = id
		@name = name
		@email = email
	end
end

class Users

	def get_users_from_csv 
		id=1
		csv.foreach(@users_filename) do |row|
			@users.push(User.new(id, row[0], row[1]))
			id +=1
		end
	end
	
	def cerate_users_table
		begin
			db = SQLite3::Database.open @database
			db.execute "DROP TABLE Users"
			db.execute "CREATE TABLE Users (id            INTEGER PRIMARY KEY,
											name            CHAR,
											email			CHAR)"
			@users.each do |user|
				db.execute "INSERT INTO Users VALUES ( #{user.id}, '#{user.name}', '#{user.email}')" 
			end
		rescue SQLite3::Exception => e
			puts "Exception updating the Database #{@database}"
			puts e
		ensure
			db.close if db
		end
			
	end
	
	def get_users_from_db
		#TODO
	end
	
	def initialize (refresh, users_filename, database)
		@users_filename = users_filename
		@database = database
		@users = Array.new
		
		if (refresh)
			get_users_from_csv
			create_users_table
		else
			get_users_from_db
		end
	end
	
end

def get_options
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: ajp.rb [options]"
		
		options[:verbose] = false
		opts.on('-v', '--verbose', 'Output more information') do
			options[:verbose] = true
		end
		
		opts.on('-h', '--help', 'Display this screen') do
			puts opts
			exit
		end
		
		options[:jil] = "alljobs.jil"
		opts.on('-j', '--jil FILE', "Input JIL filename. By default is '#{options[:jil]}'") do |param|
			options[:jil] = param
		end

		options[:users] = "people.csv"
		opts.on('-u', '--users FILE', "Input CSV filename with people contact. By default is '#{options[:users]}'") do |param|
			options[:users] = param
		end
		
		options[:owners] = "owners.cvs"
		opts.on('-o', '--owners FILE', "Input CVS filename with all the owners. By default is '#{options[:owners]}'") do |param|
			options[:owners] = param
		end
		
		options[:db] = "alljobs.sqlite"
		opts.on('-db', '--database FILE', "Database file. By default is '#{options[:db]}'") do |param|
			options[:db] = param
		end
		
		options[:refresh] = false
		opts.on('-r', '--refresh', "Refresh the database file with the JIL file") do |param|
			options[:refresh] = param
		end
		
		options[:csv] = nil
		opts.on('-a', '--all FILE', "Create a CSV file with all the jobs information") do |param|
			options[:csv] = param
		end
		
		options[:s] = nil
		opts.on('-text', '--text FILE', "Create a human readable file with all the jobs information") do |param|
			options[:s] = param
		end
		
		options[:yaml] = nil
		opts.on('-y', '--yaml FILE', "Create a YAML file with all the jobs information") do |param|
			options[:yaml] = param
		end
			
	end.parse!
	options
end


options = get_options
jobs = Jobs.new(options[:refresh], options[:jil], options[:db])
jobs.to_file(:to_csv, options[:csv]) unless options[:csv] == nil
jobs.to_file(:to_s, options[:s]) unless options[:s] == nil
jobs.to_file(:to_yaml, options[:yaml]) unless options[:yaml] == nil

users = Users.new(options[:refresh], options[:users], options[:db])
