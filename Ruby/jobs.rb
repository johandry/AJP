require_relative 'job'

require 'yaml'
require 'sqlite3'
require 'csv'


class Jobs

	def get_jobs_from_jil
		job = Job.new(1)
		id=2
		File.open(@jil, "r").each_line do |line|
		
			line.chomp!
			
			if( /insert_job:/.match(line) and job.name != '' ) 
				@jobs.push(job)
				job = Job.new(id)
				id += 1
			end
			
			job.name          	= $1 if /insert_job: (\w+)/.match(line)
			job.type 			= $1 if /job_type: (\w+)/.match(line)
			job.box_name	    = $1 if /box_name: (\w+)/.match(line)
			job.command		    = $1 if /command: (.+)/.match(line)
			job.machine		    = $1 if /machine: (.+)/.match(line)
			job.owner			= $1 if /owner: (.+)/.match(line)
			job.permission    	= $1 if /permission: (.+)/.match(line)
			job.date_condition	= $1 if /date_conditions: (.+)/.match(line)
			job.days_of_week	= $1 if /days_of_week: (.+)/.match(line)
			job.start_times		= $1 if /start_times: "(.+)"/.match(line)
			job.condition		= $1 if /condition: (.+)/.match(line)
			job.description   	= $1 if (/description: "(.*)"/).match(line)
			job.std_out_file	= $1 if /std_out_file: (.*)/.match(line)
			job.std_err_file	= $1 if /std_err_file: (.*)/.match(line)
			job.alarm_if_fail	= $1 if /alarm_if_fail: (.+)/.match(line)
			
		end
	end
	
	def get_jobs_from_db
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT * FROM Jobs"
			rs = stm.execute
			
			rs.each do |job|
				@jobs.push(Job.new(job[0], job[1], job[2], job[3], job[4], job[5], job[6], job[7], job[8], job[9], job[10], job[11], job[12], job[13], job[14], job[15]))
			end
		rescue SQLite3::Exception => e
			puts "Exception occured getting the jobs"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def create_jobs_table
	  begin
	    db = SQLite3::Database.open @database
		db.execute "DROP TABLE IF EXISTS Jobs"
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
	    puts "Exception creating the table Jobs"
	    puts e
	  ensure
	    db.close if db
	  end
  end
	
	def initialize (database, refresh = false, jil_filename = false, verbose = false)
	  @jil  		= jil_filename
	  @database   	= database
	  @jobs 		= Array.new
	  
	  if(refresh and jil_filename)
		puts "Getting jobs from #{jil_filename} file" if verbose
		get_jobs_from_jil
		puts "Creating the jobs table in the #{database} database" if verbose
		create_jobs_table
	  else
		puts "Getting jobs from the #{database} database" if verbose
		get_jobs_from_db
	  end
	end
	
	def find_by_name (name)
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT id FROM Jobs WHERE name = ?"
			stm.bind_param 1, name
			rs = stm.execute
			row = rs.next
			return (row != nil)?row[0]:nil
			
		rescue SQLite3::Exception => e
			puts "Exception occured finding the user with name #{name}"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def get_name_by_id (job_id)
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT name FROM Jobs WHERE id = ?"
			stm.bind_param 1, job_id
			rs = stm.execute
			row = rs.next
			box_name = row[0]
			
			return box_name
			
		rescue SQLite3::Exception => e
			puts "Exception occured finding the user with name #{name}"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end		
	end
	
	def get_jobs_in_box (box_id)
		begin
			db = SQLite3::Database.open @database
			
			box_name = self.get_name_by_id(box_id)
			
			stm = db.prepare "SELECT id FROM Jobs WHERE box_name = ?"
			stm.bind_param 1, box_name
			rs = stm.execute
			
			child_jobs = Array.new
			rs.each { |job_id| child_jobs.push(job_id[0]) }
			
			return child_jobs
			
		rescue SQLite3::Exception => e
			puts "Exception occured finding the user with name #{name}"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end		
	end
	
	def to_ror
	  ror_output = 'Job.delete_all' << "\n\n"
	  @jobs.each do |job|
	    ror_output << job.to_ror << "\n"
    end
    ror_output
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
  
  def to_file (format, filename, verbose = false)
	puts "Creating #{filename} file with jobs in #{format} format"
	file = File.new(filename, 'w')
	file.syswrite(self.send(format))
	file.close unless file == nil
  end
  
end