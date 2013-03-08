require_relative 'user'

require 'yaml'
require 'sqlite3'
require 'csv'

class Users

	def get_users_from_csv 
		id=1
		header=true
		CSV.foreach(@users_filename) do |row|
		  if header
		    header = false
		    next
		  end
			@users.push(User.new(id, row[0], row[1]))
			id +=1
		end
	end
	
	def create_users_table
		begin
			db = SQLite3::Database.open @database
			db.execute "DROP TABLE IF EXISTS Users"
			db.execute "CREATE TABLE IF NOT EXISTS Users (id            INTEGER PRIMARY KEY,
											name            CHAR,
											email			CHAR)"
			@users.each do |user|
				db.execute "INSERT INTO Users VALUES ( #{user.id}, '#{user.name}', '#{user.email}')" 
			end
		rescue SQLite3::Exception => e
			puts "Exception creating the table Users."
			puts e
		ensure
			db.close if db
		end
			
	end
	
	def get_users_from_db
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT * FROM Users"
			rs = stm.execute
			
			rs.each do |user|
				@users.push(User.new(user[0], user[1], user[2]))
			end
		rescue SQLite3::Exception => e
			puts "Exception occured getting the users"
			puts e
		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def initialize (database, refresh = false, users_filename = false, verbose = false)
		@users_filename = users_filename
		@database = database
		@users = Array.new
		
		if (refresh and users_filename)
			puts "Getting users from #{users_filename} file" if verbose
			get_users_from_csv
			puts "Creating the users table in the #{database} database" if verbose
			create_users_table
		else
			puts "Getting users from the #{database} database" if verbose
			get_users_from_db
		end
	end
	
	def find_by_name (name)
		begin
			db = SQLite3::Database.open @database
			
			stm = db.prepare "SELECT id FROM Users WHERE name = ?"
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
	
	def to_yaml
	  yaml_output = ''
	  @users.each do |user|
	    yaml_output << user.to_yaml << "\n"
	  end
	  yaml_output
	end
	
	def to_s
	  s_output = ''
	  @users.each do |user|
	    s_output << user.to_s << "\n"
	  end
	  s_output
	end
	
	def to_csv
	  sort = 1
	  csv_output = CSV.generate do |csv|
		csv << ["id", "name", "email"].map(&:capitalize)
		@users.each do |user|
			csv << [user.id, user.name, user.email]
		end
	  end
	end
  
  def to_file (format, filename)
	puts "Creating #{filename} file with users in #{format} format"
	file = File.new(filename, 'w')
	file.syswrite(self.send(format))
	file.close unless file == nil
  end
end