#!/usr/bin/env ruby

require_relative 'jobs'
require_relative 'users'
require_relative 'ownerships'

require 'optparse'

require 'pp'

def get_options
	options = {}
	def_options = {}
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
			options[:db] = param || options[:db]
		end
		
# Actions
		options[:refresh] = false
		opts.on('-r', '--refresh', "Refresh the database file with the objects specified in the files to parse.") do |param|
			options[:refresh] = true
		end
		
		formats = { 'csv' => 'to_csv',
					'txt' => 'to_s',
					'yaml'=> 'to_yaml',
					'ror' => 'to_ror' }
					
		options[:export] = false
		opts.on('-e FORMAT', '--export FORMAT', formats, "Export the objects in the format specified from the database.") do |param|
			options[:export] = param
		end
		
# Objects
		options[:jobs] = false
		def_options[:jobs] = "jobs.jil"
		opts.on('-j', '--jobs [FILE]', "Export to the file or parse the jobs from a JIL filename with all the jobs to refresh the database. The default is '#{def_options[:jobs]}'") do |param|
			options[:jobs] = param || default_opt[:jobs]
		end

		options[:users] = false
		def_options[:users] = "users.csv"
		opts.on('-u', '--users [FILE]', "Export to the file or parse the users from a CSV filename with all users contact to refresh the database. The default is '#{def_options[:users]}'") do |param|
			options[:users] = param || def_options[:users]
		end
		
		options[:ownerships] = false
		def_options[:ownerships] = "ownerships.csv"
		opts.on('-o', '--owners [FILE]', "Export to the file or parse the owners from a CSV filename with all the owners to refresh the database. The default is '#{def_options[:ownerships]}'") do |param|
			options[:ownerships] = param || def_options[:ownerships]
		end

	end.parse!
	options
end

# Get the option(s) requested 
options = get_options

# Populate the objets and refresh the DB's if requested
jobs 	= Jobs.new(options[:db], options[:refresh], options[:jobs], options[:verbose])
# users 	= Users.new(options[:db], options[:refresh], options[:users], options[:verbose])
# ownerships 	= Ownerships.new(jobs, users, options[:db], options[:refresh], options[:ownerships], options[:verbose])

# Different output options
jobs.to_file(options[:export].to_sym, options[:jobs]) if options[:export] and options[:jobs]
# users.to_file(options[:export].to_sym, options[:users]) if options[:export] and options[:users]
# ownerships.to_file(options[:export].to_sym, options[:ownerships]) if options[:export] and options[:ownerships]