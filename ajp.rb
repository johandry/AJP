#!/usr/bin/env ruby

require 'jobs'
require 'users'

require 'optparse'

require 'pp'

def get_options
	options = {}
	OptionParser.new do |opts|
		script_name = File.basename($PROGRAM_NAME)
		opts.banner = "Autosys JIL Parser: Receives a JIL file as well as csv files with users and owners to create a DB. Also, export the DB to different formats. 
		
Usage: #{script_name} [option] ACTION OBJECT 

Action options:
	-r | --refresh
	-e FORMAT | --export FORMAT
	
Object options:
	-j | --jobs [FILE]
	-u | --users [FILE]
	-o | --owners [FILE]

Examples:
	#{script_name} --refresh -j
		Refresh the database with all the jobs in the #{options[:jobs]} file.
	
	#{script_name} -r -u -o
		Refresh the database with all the users and job owners in the #{options[:users]} and #{options[:owners]} files.
		
	#{script_name} --export csv -u
		Export all the users to the #{options[:users]} file in csv format.
	
	#{script_name} -e txt -j jobs.txt
		Export all the jobs to the jobs.txt file in human readable format.
		
Options:
"

# Options
		options[:verbose] = false
		opts.on('-v', '--verbose', "Output more information") do
			options[:verbose] = true
		end
		
		opts.on('-h', '--help', "Display this screen") do
			puts opts
			exit
		end
		
		options[:db] = "ajp.sqlite"
		opts.on('-d', '--database FILE', "Database file. By default is '#{options[:db]}'") do |param|
			options[:db] = param
		end
		
# Actions
		options[:refresh] = false
		opts.on('-r', '--refresh', "Refresh the database file with the objects specified in the files to parse.") do |param|
			options[:refresh] = true
		end
		
		formats = { 'csv' => ':to_csv',
					'txt' => 'to_s',
					'yaml'=> 'to_yaml' }
					
		options[:export] = false
		opts.on('-e FORMAT', '--export FORMAT', formats, "Export the objects in the format specified from the database.") do |param|
			options[:export] = param
		end
		
# Objects
		options[:jobs] = "jobs.jil"
		opts.on('-j', '--jobs [FILE]', "Parse the jobs from a JIL filename with all the jobs to refresh the database. The default is '#{options[:jobs]}'") do |param|
			options[:jobs] = param
		end

		options[:users] = "users.csv"
		opts.on('-u', '--users [FILE]', "Parse the users from a CSV filename with all users contact to refresh the database. The default is '#{options[:users]}'") do |param|
			options[:users] = param
		end
		
		options[:owners] = "owners.cvs"
		opts.on('-o', '--owners [FILE]', "Parse the owners from a CVS filename with all the owners to refresh the database. The default is '#{options[:owners]}'") do |param|
			options[:owners] = param
		end

	end.parse!
	options
end

# Get the option(s) requested 
options = get_options

# Populate the objets and refresh the DB's if requested
jobs 	= Jobs.new(options[:refresh], options[:jobs], options[:db])
users 	= Users.new(options[:refresh], options[:users], options[:db])
owners 	= Owners.new(options[:refresh], options[:owners], options[:db])

# Different output options
if (options[:csv])
	jobs.to_file(:to_csv, options[:csv])
	#users.to_file(:to_csv)
end
jobs.to_file(:to_s, options[:s]) unless options[:s] == nil
jobs.to_file(:to_yaml, options[:yaml]) unless options[:yaml] == nil
