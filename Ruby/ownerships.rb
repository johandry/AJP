require_relative 'ownership'

require 'pp'

class Ownerships

	def add_ownerships (id, line, user_id, box_name, check_on)
	  job_id = @jobs.find_by_name(box_name)
	  
	  if (job_id != nil)
		@ownerships.push(Ownership.new(id, user_id, job_id, check_on)) 
		id += 1
		
		child_jobs = @jobs.get_jobs_in_box(job_id)
		if (child_jobs != nil)
			child_jobs.each do |job|
				@ownerships.push(Ownership.new(id, user_id, job, check_on))
				id += 1
			end
		end
		
	  else
		@jobs_not_found.push([line,box_name])
	  end
	  
	  return id
	end
	
	def get_ownerships_from_csv
		id=1
		line=0
		header=true
		user_id=0
		CSV.foreach(@ownerships_filename) do |row|
		  line += 1
		  if header
		    header = false
		    next
		  end
		  if (row[0] != nil) # This is a user row
			user_id = @users.find_by_name(row[0]) || 0
			next
		  end
		  
		  id = add_ownerships(id, line, user_id, row[1], row[3])
		  id = add_ownerships(id, line, user_id, row[2], row[3]) if row[2] != nil
		end
	end
	
	def create_ownerships_table
		begin
			db = SQLite3::Database.open @database
			db.execute "DROP TABLE IF EXISTS Ownerships"
			db.execute "CREATE TABLE IF NOT EXISTS Ownerships (id            INTEGER PRIMARY KEY,
											user_id            	INTEGER,
											job_id				INTEGER,
											check_on			TEXT)"
			@ownerships.each do |ownership|
				db.execute "INSERT INTO Ownerships VALUES ( #{ownership.id}, #{ownership.user_id}, #{ownership.job_id}, '#{ownership.check_on}')" 
			end
		rescue SQLite3::Exception => e
			puts "Exception creating the table Ownerships"
			puts e
		ensure
			db.close if db
		end		
	end
	
	def get_ownerships_from_db
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT * FROM Ownerships"
			rs = stm.execute
			
			rs.each do |ownership|
				@ownerships.push(Ownerships.new(ownership[0], ownership[1], ownership[2], ownership[3]))
			end
		rescue SQLite3::Exception => e
			puts "Exception occured getting the ownerships"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def initialize (jobs, users, database, refresh = false, ownerships_filename = false, verbose = false)
		@users = users
		@jobs = jobs
		@ownerships_filename = ownerships_filename
		@database = database
		@ownerships = Array.new
		@jobs_not_found = Array.new
		
		if (refresh and ownerships_filename)
			puts "Getting ownerships from #{ownerships_filename} file" if verbose
			get_ownerships_from_csv
			puts "Creating the ownerships table in the #{database} database" if verbose
			create_ownerships_table
		else
			puts "Getting ownerships from the #{database} database" if verbose
			get_ownerships_from_db
		end
		
		puts "Jobs not found:"
		@jobs_not_found.each do |job|
			puts "\tRow: #{job[0]} - Job Name: #{job[1]}"
		end
		puts "Total: #{@jobs_not_found.length} jobs"
	end
end